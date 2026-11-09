return {
  cmd = {
    "clangd",
    "--completion-style=detailed",
  },
  root_markers = {
    ".clangd",
    ".clang-tidy",
    ".clang-format",
    "compile_commands.json",
    "compile_flags.txt",
    "Makefile",
    ".git",
  },
}
