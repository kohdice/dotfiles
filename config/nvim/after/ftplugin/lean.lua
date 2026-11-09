local map = function(lhs, rhs, desc)
  vim.keymap.set("n", lhs, rhs, { buffer = true, desc = desc })
end

map("<LocalLeader>i", "<cmd>LeanInfoviewToggle<cr>", "Toggle infoview")
map("<LocalLeader>r", "<cmd>LeanRestartFile<cr>", "Restart Lean file")
map("<LocalLeader>s", "<cmd>LeanInfoviewAcceptSuggestion<cr>", "Accept infoview suggestion")
map("<LocalLeader>u", "<cmd>LeanAbbreviationsReverseLookup<cr>", "Show Unicode input method")

-- Append, not assign: lean.nvim's ftplugin already set b:undo_ftplugin.
local undo = vim.b.undo_ftplugin
vim.b.undo_ftplugin = (undo and undo ~= "" and undo .. " | " or "")
  .. "silent! nunmap <buffer> <LocalLeader>i"
  .. " | silent! nunmap <buffer> <LocalLeader>r"
  .. " | silent! nunmap <buffer> <LocalLeader>s"
  .. " | silent! nunmap <buffer> <LocalLeader>u"
