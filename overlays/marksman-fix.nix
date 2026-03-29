# Temporary fix: marksman server crashes with SIGABRT on macOS due to missing ICU
# The Nix wrapper sets LD_LIBRARY_PATH (Linux) instead of DYLD_LIBRARY_PATH (macOS).
# Workaround: disable ICU via DOTNET_SYSTEM_GLOBALIZATION_INVARIANT.
# TODO: Remove this overlay once nixpkgs fixes the macOS wrapper for .NET apps.
#       Also remove ./marksman-fix.nix from overlayFiles in overlays/default.nix.
final: prev: {
  marksman = prev.marksman.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ final.makeWrapper ];
    postFixup = (old.postFixup or "") + ''
      wrapProgram $out/bin/marksman \
        --set DOTNET_SYSTEM_GLOBALIZATION_INVARIANT 1
    '';
  });
}
