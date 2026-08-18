-- stylua.toml sets indent_width = 2 and conform runs stylua on save, so a
-- buffer-local 2 keeps typing and saving in agreement; the global default in
-- lua/config/options.lua is 4 for every other filetype.
vim.bo.shiftwidth = 2
vim.bo.tabstop = 2
vim.bo.softtabstop = 2

-- Restored by the filetypeplugin autocmd on the next FileType (:h b:undo_ftplugin).
-- Append instead of assigning: the runtime ftplugin already set it.
local undo = vim.b.undo_ftplugin
vim.b.undo_ftplugin = (undo and undo ~= "" and undo .. " | " or "") .. "setlocal shiftwidth< tabstop< softtabstop<"
