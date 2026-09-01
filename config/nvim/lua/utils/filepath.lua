local M = {}

local function copy_to_clipboard(text)
  vim.fn.setreg("+", text)
  vim.notify('Copied: "' .. text .. '"')
end

--- Expand a buffer-name modifier, or nil for an unnamed buffer.
--- expand() yields "" there (scratch buffers from <Leader>S, :enew), which would
--- otherwise wipe the clipboard and still report a successful copy.
---@param modifier string
---@return string|nil
local function buffer_path(modifier)
  local path = vim.fn.expand(modifier)
  if path == "" then
    vim.notify("Buffer has no file name", vim.log.levels.WARN)
    return nil
  end
  return path
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
  local path = buffer_path("%:p")
  if path then
    copy_to_clipboard(path)
  end
end

M.copy_absolute_path_with_line = function()
  local path = buffer_path("%:p")
  if path then
    copy_to_clipboard(path .. get_line_info())
  end
end

M.copy_relative_path = function()
  local path = buffer_path("%")
  if path then
    copy_to_clipboard(path)
  end
end

M.copy_relative_path_with_line = function()
  local path = buffer_path("%")
  if path then
    copy_to_clipboard(path .. get_line_info())
  end
end

return M
