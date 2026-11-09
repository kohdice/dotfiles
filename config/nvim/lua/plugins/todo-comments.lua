local todo = require("todo-comments")
local Snacks = require("snacks")

todo.setup({})

local map = function(lhs, rhs, desc)
  vim.keymap.set("n", lhs, rhs, { desc = desc })
end

map("]t", todo.jump_next, "Next todo comment")
map("[t", todo.jump_prev, "Previous todo comment")
map("<leader>xt", "<cmd>Trouble todo toggle<cr>", "Todo (Trouble)")
map("<leader>xT", "<cmd>Trouble todo toggle filter = {tag = {TODO,FIX,FIXME}}<cr>", "Todo/Fix/Fixme (Trouble)")
-- Closures, not Snacks.picker.todo_comments itself: todo-comments registers
-- that source on VimEnter, after this file has run
map("<leader>st", function()
  Snacks.picker.todo_comments()
end, "Todo")
map("<leader>sT", function()
  Snacks.picker.todo_comments({ keywords = { "TODO", "FIX", "FIXME" } })
end, "Todo/Fix/Fixme")
