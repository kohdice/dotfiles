# AI development tools overlay
# Uses latestPkgs (nixpkgs-latest) for frequently updated packages
# Update with: nix flake lock --update-input nixpkgs-latest

{ latestPkgs }:
final: prev: {
  claude-code = latestPkgs.claude-code;
  codex = latestPkgs.codex;

  ai-tools = final.symlinkJoin {
    name = "ai-tools";
    paths = with final; [
      claude-code
      codex
    ];
    meta.description = "AI development tools bundle (Claude Code, Codex)";
  };
}
