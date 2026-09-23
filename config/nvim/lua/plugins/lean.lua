return {
  "Julian/lean.nvim",
  event = { "BufReadPre *.lean", "BufNewFile *.lean" },
  keys = {
    { "<LocalLeader>i", "<cmd>LeanInfoviewToggle<cr>", ft = "lean", desc = "Toggle infoview" },
    { "<LocalLeader>r", "<cmd>LeanRestartFile<cr>", ft = "lean", desc = "Restart Lean file" },
    { "<LocalLeader>s", "<cmd>LeanInfoviewAcceptSuggestion<cr>", ft = "lean", desc = "Accept infoview suggestion" },
    { "<LocalLeader>u", "<cmd>LeanAbbreviationsReverseLookup<cr>", ft = "lean", desc = "Show Unicode input method" },
  },
  init = function()
    vim.g.lean_config = {
      mappings = false,
      infoview = {
        autoopen = false,
      },
    }
  end,
}
