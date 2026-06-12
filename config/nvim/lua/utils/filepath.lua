local M = {}

local function copy_to_clipboard(text)
  vim.fn.setreg("+", text)
  vim.notify('Copied: "' .. text .. '"')
end

local function get_line_info()
  -- "\22" is visual-block mode (CTRL-V)
  if vim.fn.mode():match("[vV\22]") then
    -- '< / '> marks are only updated after leaving visual mode,
    -- so use the cursor and the other end of the active selection
    local start_line = vim.fn.line(".")
    local end_line = vim.fn.line("v")
    if start_line > end_line then
      start_line, end_line = end_line, start_line
    end
    if start_line == end_line then
      return "#L" .. start_line
    end
    return "#L" .. start_line .. "-L" .. end_line
  end
  return "#L" .. vim.fn.line(".")
end

M.copy_absolute_path = function()
  copy_to_clipboard(vim.fn.expand("%:p"))
end

M.copy_absolute_path_with_line = function()
  copy_to_clipboard(vim.fn.expand("%:p") .. get_line_info())
end

M.copy_relative_path = function()
  copy_to_clipboard(vim.fn.expand("%"))
end

M.copy_relative_path_with_line = function()
  copy_to_clipboard(vim.fn.expand("%") .. get_line_info())
end

return M
