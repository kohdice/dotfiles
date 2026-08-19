-- Match stylua.toml's indent_width = 2; the global default is 4 (config/options.lua).
vim.bo.shiftwidth = 2
vim.bo.tabstop = 2
vim.bo.softtabstop = 2

-- Append, not assign: the runtime ftplugin already set b:undo_ftplugin.
local undo = vim.b.undo_ftplugin
vim.b.undo_ftplugin = (undo and undo ~= "" and undo .. " | " or "") .. "setlocal shiftwidth< tabstop< softtabstop<"
