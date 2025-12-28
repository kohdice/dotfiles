return {
  -- Marp: Markdown Presentation Ecosystem
  {
    "nwiizo/marp.nvim",
    ft = "markdown",
    keys = {
      { "<leader>mw", "<cmd>MarpWatch<cr>", desc = "Start Marp watch" },
      { "<leader>ms", "<cmd>MarpStop<cr>", desc = "Stop Marp preview" },
      { "<leader>me", "<cmd>MarpExport<cr>", desc = "Export Marp presentation" },
      { "<leader>mt", "<cmd>MarpTheme<cr>", desc = "Switch Marp theme" },
    },
  },
}
