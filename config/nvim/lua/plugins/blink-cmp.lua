return {
  "saghen/blink.cmp",
  -- Use a release tag to download prebuilt fuzzy matcher binaries
  version = "1.*",
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
      menu = { border = "rounded" },
      documentation = {
        auto_show = true,
        window = { border = "rounded" },
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

    fuzzy = { implementation = "prefer_rust_with_warning" },
  },
}
