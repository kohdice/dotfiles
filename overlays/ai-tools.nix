# AI development tools overlay
# Provides grouped AI tools and custom configurations

final: prev: {
  # AI tools bundle - convenient meta package for all AI development tools
  ai-tools = final.symlinkJoin {
    name = "ai-tools";
    paths = with final; [
      claude-code
      codex
    ];
    meta = {
      description = "AI development tools bundle (Claude Code, Codex)";
    };
  };
}
