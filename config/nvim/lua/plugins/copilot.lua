return {
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    build = ":Copilot auth",
    event = "BufReadPost",
    keys = {
      {
        "<Leader>cp",
        function()
          require("copilot.suggestion").toggle_auto_trigger()
        end,
        desc = "Toggle Copilot suggestion",
      },
    },
    opts = {
      suggestion = {
        enabled = true,
        auto_trigger = false,
        hide_during_completion = true,
        keymap = {
          accept = "<C-l>",
          next = "<M-]>",
          prev = "<M-[>",
        },
      },
      panel = { enabled = false },
      filetypes = {
        markdown = true,
        help = true,
      },
    },
  },
}
