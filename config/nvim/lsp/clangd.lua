return {
  cmd = {
    "clangd",
    "--completion-style=detailed", -- Show detailed completion information
  },
  filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
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
