{ pkgs }:

pkgs.writeShellApplication {
  name = "setup-ssh-keys";

  runtimeInputs = with pkgs; [
    coreutils
    gawk
    gh
    jq
    openssh
  ];

  text = ''
    authentication_key_name="id_ed25519_github_auth"
    signing_key_name="id_ed25519_git_signing"
    apple_ssh_add="/usr/bin/ssh-add"

    info() {
      printf '==> %s\n' "$*"
    }

    warn() {
      printf 'warning: %s\n' "$*" >&2
    }

    die() {
      printf 'error: %s\n' "$*" >&2
      exit 1
    }

    usage() {
      printf 'Usage: setup-ssh-keys\n'
    }

    confirm() {
      local prompt="$1"
      local reply

      read -r -p "$prompt [y/N] " reply
      case "$reply" in
        y | Y | yes | YES | Yes)
          return 0
          ;;
        *)
          return 1
          ;;
      esac
    }

    github_key_ids() {
      local endpoint="$1"
      local public_key_file="$2"
      local public_key
      local response

      public_key="$(awk 'NF >= 2 { print $1 " " $2; exit }' "$public_key_file")"
      [ -n "$public_key" ] || die "invalid public key: $public_key_file"

      response="$(gh api --paginate "$endpoint")" ||
        die "GitHub key API access failed for $endpoint"
      printf '%s\n' "$response" |
        jq -r --arg key "$public_key" '
          .[]
          | select((.key | split(" ") | .[0:2] | join(" ")) == $key)
          | .id
        '
    }

    ensure_github_key() {
      local key_type="$1"
      local endpoint="$2"
      local public_key_file="$3"
      local title="$4"
      local existing_ids

      existing_ids="$(github_key_ids "$endpoint" "$public_key_file")"
      if [ -n "$existing_ids" ]; then
        info "GitHub already has the $key_type key"
        return
      fi

      info "Registering the $key_type key with GitHub"
      gh ssh-key add "$public_key_file" --title "$title" --type "$key_type"
    }

    generate_key() {
      local destination="$1"
      local temporary="$2"
      local comment="$3"

      rm -f -- "$temporary" "$temporary.pub"
      ssh-keygen -t ed25519 -a 100 -C "$comment" -f "$temporary"
      [ -f "$temporary" ] || die "ssh-keygen did not create $temporary"
      [ -f "$temporary.pub" ] || die "ssh-keygen did not create $temporary.pub"

      mv -- "$temporary" "$destination"
      mv -- "$temporary.pub" "$destination.pub"
    }

    add_key_to_agent() {
      local private_key="$1"

      if [ "$platform" = "macos" ]; then
        "$apple_ssh_add" --apple-use-keychain "$private_key"
      else
        ssh-add "$private_key"
      fi
    }

    remove_key_from_agent() {
      local public_key="$1"

      if [ "$platform" = "macos" ]; then
        "$apple_ssh_add" -d "$public_key"
      else
        ssh-add -d "$public_key"
      fi
    }

    test_key_in_agent() {
      local public_key="$1"

      if [ "$platform" = "macos" ]; then
        "$apple_ssh_add" -T "$public_key"
      else
        ssh-add -T "$public_key"
      fi
    }

    if [ "$#" -ne 0 ]; then
      usage >&2
      exit 2
    fi

    [ -t 0 ] && [ -t 1 ] || die "run this command from an interactive terminal"

    case "''${HOME:-}" in
      "" | /)
        die "HOME must identify a user home directory"
        ;;
    esac

    case "$(uname -s)" in
      Darwin)
        platform="macos"
        [ -x "$apple_ssh_add" ] || die "$apple_ssh_add is not available"
        ssh_client="/usr/bin/ssh"
        [ -x "$ssh_client" ] || die "$ssh_client is not available"
        default_description="$(/usr/sbin/scutil --get ComputerName 2>/dev/null || uname -n)"
        ;;
      Linux)
        platform="linux"
        ssh_client="ssh"
        runtime_directory="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
        if [ ! -S "''${SSH_AUTH_SOCK:-}" ] && [ -S "$runtime_directory/ssh-agent" ]; then
          export SSH_AUTH_SOCK="$runtime_directory/ssh-agent"
        fi
        [ -S "''${SSH_AUTH_SOCK:-}" ] ||
          die "ssh-agent is not available; apply the Home Manager profile before running setup"
        default_description="$(uname -n)"
        ;;
      *)
        die "this setup supports macOS and Linux only"
        ;;
    esac

    ssh_directory="$HOME/.ssh"
    authentication_key="$ssh_directory/$authentication_key_name"
    authentication_public_key="$authentication_key.pub"
    authentication_key_new="$authentication_key.new"
    signing_key="$ssh_directory/$signing_key_name"
    signing_public_key="$signing_key.pub"
    signing_key_new="$signing_key.new"

    cleanup() {
      rm -f -- \
        "$authentication_key_new" \
        "$authentication_key_new.pub" \
        "$signing_key_new" \
        "$signing_key_new.pub"
    }

    trap cleanup EXIT
    trap 'exit 130' INT
    trap 'exit 143' HUP TERM

    mkdir -p "$ssh_directory"
    chmod 700 "$ssh_directory"

    read -r -p "Key description [$default_description]: " description
    description="''${description:-$default_description}"
    [ -n "$description" ] || die "key description must not be empty"

    authentication_title="$description GitHub authentication"
    signing_title="$description Git signing"

    if [ -f "$authentication_key" ] && [ -f "$authentication_public_key" ]; then
      info "Keeping the existing GitHub authentication key"
    elif [ -e "$authentication_key" ] || [ -e "$authentication_public_key" ]; then
      die "the GitHub authentication key pair is incomplete: $authentication_key"
    else
      info "Generating the GitHub authentication key"
      generate_key "$authentication_key" "$authentication_key_new" "$authentication_title"
    fi

    replaced_signing_key=false
    old_signing_key_ids=""
    if [ -f "$signing_key" ] && [ -f "$signing_public_key" ]; then
      if confirm "Replace the existing Git signing key?"; then
        old_signing_key_ids="$(github_key_ids user/ssh_signing_keys "$signing_public_key")"
        info "Generating the replacement Git signing key"
        rm -f -- "$signing_key_new" "$signing_key_new.pub"
        ssh-keygen -t ed25519 -a 100 -C "$signing_title" -f "$signing_key_new"
        [ -f "$signing_key_new" ] || die "ssh-keygen did not create $signing_key_new"
        [ -f "$signing_key_new.pub" ] || die "ssh-keygen did not create $signing_key_new.pub"

        remove_key_from_agent "$signing_public_key" >/dev/null 2>&1 || true
        rm -f -- "$signing_key" "$signing_public_key"
        mv -- "$signing_key_new" "$signing_key"
        mv -- "$signing_key_new.pub" "$signing_public_key"
        replaced_signing_key=true
      else
        info "Keeping the existing Git signing key"
      fi
    elif [ -e "$signing_key" ] || [ -e "$signing_public_key" ]; then
      die "the Git signing key pair is incomplete: $signing_key"
    else
      info "Generating the Git signing key"
      generate_key "$signing_key" "$signing_key_new" "$signing_title"
    fi

    chmod 600 "$authentication_key" "$signing_key"
    chmod 644 "$authentication_public_key" "$signing_public_key"

    if [ "$platform" = "macos" ]; then
      info "Adding keys to ssh-agent and macOS Keychain"
    else
      info "Adding keys to ssh-agent"
    fi
    add_key_to_agent "$authentication_key"
    add_key_to_agent "$signing_key"

    ensure_github_key \
      authentication \
      user/keys \
      "$authentication_public_key" \
      "$authentication_title"
    ensure_github_key \
      signing \
      user/ssh_signing_keys \
      "$signing_public_key" \
      "$signing_title"

    if [ "$replaced_signing_key" = true ] && [ -n "$old_signing_key_ids" ]; then
      while IFS= read -r key_id; do
        [ -n "$key_id" ] || continue
        if ! gh api --method DELETE "user/ssh_signing_keys/$key_id"; then
          warn "could not delete the old GitHub signing key with ID $key_id"
        fi
      done <<< "$old_signing_key_ids"
    fi

    info "Verifying GitHub SSH authentication"
    set +e
    authentication_output="$(
      "$ssh_client" \
        -o IdentitiesOnly=yes \
        -o "IdentityFile=$authentication_key" \
        -T git@github.com 2>&1
    )"
    authentication_status=$?
    set -e

    case "$authentication_output" in
      *"successfully authenticated"*)
        if [ "$authentication_status" -ne 1 ]; then
          die "GitHub returned an unexpected SSH status: $authentication_status"
        fi
        ;;
      *)
        printf '%s\n' "$authentication_output" >&2
        die "GitHub SSH authentication failed"
        ;;
    esac

    info "Verifying Git signing"
    test_key_in_agent "$signing_public_key"
    printf 'SSH signing test\n' | ssh-keygen -Y sign -n git -f "$signing_public_key" >/dev/null

    info "SSH key setup completed"
  '';
}
