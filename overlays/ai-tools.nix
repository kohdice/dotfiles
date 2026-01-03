# AI development tools overlay
final: prev: {
  ai-tools = final.symlinkJoin {
    name = "ai-tools";
    paths = with final; [
      claude-code
      codex
    ];
    meta.description = "AI development tools bundle (Claude Code, Codex)";
  };
}
