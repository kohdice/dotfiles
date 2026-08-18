return {
  "folke/todo-comments.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  event = { "BufReadPre", "BufNewFile" },
  opts = {},
  keys = {
    {
      "]t",
      function()
        require("todo-comments").jump_next()
      end,
      desc = "Next todo comment",
    },
    {
      "[t",
      function()
        require("todo-comments").jump_prev()
      end,
      desc = "Previous todo comment",
    },
    { "<leader>xt", "<cmd>Trouble todo toggle<cr>", desc = "Todo (Trouble)" },
    {
      "<leader>xT",
      "<cmd>Trouble todo toggle filter = {tag = {TODO,FIX,FIXME}}<cr>",
      desc = "Todo/Fix/Fixme (Trouble)",
    },
    { "<leader>st", "<cmd>TodoFzfLua<cr>", desc = "Todo" },
    {
      -- Not :TodoFzfLua keywords=... — plugin/todo.vim defines the command as
      -- `lua require("todo-comments.fzf").todo() <args>`, appending <args>
      -- outside the call parentheses. The filter then parses as a separate
      -- global assignment, no error is raised, and todo() still receives nil
      "<leader>sT",
      function()
        require("todo-comments.fzf").todo({ keywords = { "TODO", "FIX", "FIXME" } })
      end,
      desc = "Todo/Fix/Fixme",
    },
  },
}
