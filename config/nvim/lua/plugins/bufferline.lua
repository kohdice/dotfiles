return {
  "akinsho/bufferline.nvim",
  version = "*",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
    "craftzdog/solarized-osaka.nvim",
  },
  event = "VeryLazy",
  opts = function()
    -- Derive highlight colors from the colorscheme palette instead of
    -- duplicating hex literals that drift when the colorscheme changes
    local colors = require("solarized-osaka.colors").setup()
    return {
      options = {
        mode = "tabs",
        always_show_bufferline = false,
        show_buffer_close_icons = false,
        show_close_icon = false,
      },
      highlights = {
        separator = {
          fg = colors.base02,
          bg = colors.base03,
        },
        separator_selected = {
          fg = colors.base02,
        },
        background = {
          fg = colors.base00,
          bg = colors.base03,
        },
        buffer_selected = {
          fg = colors.base3,
          bold = true,
        },
        fill = {
          bg = colors.base02,
        },
      },
    }
  end,
}
