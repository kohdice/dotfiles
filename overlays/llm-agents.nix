# AI coding agents from llm-agents.nix
final: prev: {
  inherit (prev._llm-agents.packages.${prev.system})
    claude-code
    codex
    ;
}
