return {
  "saghen/blink.cmp",
  -- Use a release tag to download prebuilt fuzzy matcher binaries
  version = "1.*",
  -- Must be start-loaded: blink's bundled plugin/blink-cmp.lua registers its
  -- completion capabilities into vim.lsp.config("*"), which has to happen
  -- before config/lsp.lua enables the servers
  lazy = false,
  dependencies = {
    "rafamadriz/friendly-snippets",
    "folke/lazydev.nvim",
  },
  opts = {
    keymap = {
      preset = "enter",
      ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
      ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
    },

    completion = {
      documentation = {
        auto_show = true,
      },
    },

    cmdline = {
      -- Show the menu while typing (blink only shows it on <Tab> by default)
      completion = { menu = { auto_show = true } },
    },

    sources = {
      default = { "lazydev", "lsp", "path", "snippets", "buffer" },
      providers = {
        lazydev = {
          name = "LazyDev",
          module = "lazydev.integrations.blink",
          score_offset = 100,
        },
      },
    },
  },
}
