return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  opts = {
    sections = {
      lualine_b = {
        { "branch", icon = " " },
      },
      lualine_c = {
        "filename",
        {
          "diff",
          symbols = {
            added = " ",
            modified = " ",
            removed = " ",
          },
        },
      },
      lualine_x = {
        {
          "diagnostics",
          sources = { "nvim_diagnostic" },
          symbols = {
            error = " ",
            warn = " ",
            info = " ",
            hint = " ",
          },
        },
        "encoding",
        "filetype",
      },
    },
    inactive_sections = {
      lualine_c = { {
        "filename",
        path = 1,
      } },
    },
  },
}
