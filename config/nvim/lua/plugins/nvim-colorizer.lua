require("colorizer").setup({
  -- Only filetypes where color literals actually appear; "*" would attach
  -- the scanner (and the tailwind keyword table) to every buffer
  filetypes = {
    "css",
    "scss",
    "html",
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
    "lua",
    "vim",
    "conf",
    "toml",
    "yaml",
  },
  options = {
    parsers = {
      css = true,
      tailwind = { enable = true },
    },
  },
})
