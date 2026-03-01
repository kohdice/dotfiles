# AI coding agents from llm-agents.nix
final: prev: {
  inherit (prev._llm-agents.packages.${prev.stdenv.hostPlatform.system})
    agent-browser
    amp
    claude-code
    coderabbit-cli
    codex
    opencode
    ;
}
