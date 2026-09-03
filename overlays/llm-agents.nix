# AI coding agents from llm-agents.nix
inputs: final: prev: {
  inherit (inputs.llm-agents.packages.${prev.stdenv.hostPlatform.system})
    agent-browser
    claude-code
    coderabbit-cli
    codex
    ;
}
