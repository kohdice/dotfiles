-- vim.pack has no lazy loading and no dependency resolution (:h vim.pack), so
-- every plugin is listed here, start-loaded, in load order
local gh = function(x)
  return "https://github.com/" .. x
end

-- Registered before add(): hooks for plugins restored from the lockfile fire
-- during the first vim.pack call
vim.api.nvim_create_autocmd("PackChanged", {
  group = vim.api.nvim_create_augroup("my-pack-hooks", { clear = true }),
  callback = function(ev)
    local name, kind = ev.data.spec.name, ev.data.kind
    -- Parsers are compiled against the plugin's queries, so rebuild them when
    -- the plugin changes. "install" fires before the plugin is loaded, and
    -- plugins/treesitter.lua installs the parsers then anyway, so only an
    -- update of an active plugin is handled here
    if name == "nvim-treesitter" and kind == "update" and ev.data.active then
      require("nvim-treesitter").update()
    end
  end,
})

vim.pack.add({
  gh("craftzdog/solarized-osaka.nvim"),
  gh("nvim-mini/mini.icons"),
  gh("folke/snacks.nvim"),

  { src = gh("nvim-treesitter/nvim-treesitter"), version = "main" },
  { src = gh("nvim-treesitter/nvim-treesitter-textobjects"), version = "main" },
  gh("nvim-treesitter/nvim-treesitter-context"),
  gh("windwp/nvim-ts-autotag"),
  -- A release tag, not main: blink downloads its prebuilt fuzzy-matcher
  -- binary only for tagged versions
  { src = gh("saghen/blink.cmp"), version = vim.version.range("^1") },
  gh("nvim-mini/mini.pairs"),
  gh("nvim-mini/mini.surround"),
  gh("folke/todo-comments.nvim"),
  gh("MagicDuck/grug-far.nvim"),
  gh("catgoose/nvim-colorizer.lua"),

  gh("neovim/nvim-lspconfig"),
  gh("folke/lazydev.nvim"),
  gh("stevearc/conform.nvim"),
  gh("mfussenegger/nvim-lint"),
  gh("folke/trouble.nvim"),

  gh("lewis6991/gitsigns.nvim"),
  gh("sindrets/diffview.nvim"),

  gh("nvim-lualine/lualine.nvim"),
  gh("stevearc/oil.nvim"),

  gh("Saecki/crates.nvim"),
  -- Not p00f/clangd_extensions.nvim: the owner account was renamed. GitHub
  -- mirror of https://sr.ht/~chinmay/clangd_extensions.nvim
  gh("dchinmay2/clangd_extensions.nvim"),
  gh("Julian/lean.nvim"),
  gh("nwiizo/marp.nvim"),
})

-- Colorscheme and icons first: lualine samples highlight groups and requires
-- nvim-web-devicons at setup
require("plugins.solarized-osaka")
require("plugins.mini-icons")
require("plugins.snacks")
require("plugins.treesitter")
require("plugins.blink-cmp")
require("plugins.lazydev")
require("plugins.conform")
require("plugins.nvim-lint")
require("plugins.trouble")
require("plugins.mini-pairs")
require("plugins.mini-surround")
require("plugins.todo-comments")
require("plugins.grug-far")
require("plugins.nvim-colorizer")
require("plugins.gitsigns")
require("plugins.diffview")
require("plugins.lualine")
require("plugins.oil")
require("plugins.crates")
require("plugins.lean")
