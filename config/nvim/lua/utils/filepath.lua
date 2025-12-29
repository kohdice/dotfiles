local M = {}

M.copy_absolute_path = function()
  local path = vim.fn.expand("%:p")
  vim.fn.setreg("+", path)
  vim.notify('Copied: "' .. path .. '"')
end

M.copy_absolute_path_with_line = function()
  local path = vim.fn.expand("%:p")
  local line_info = ""

  if vim.fn.mode():match("[vV]") then
    local start_line = vim.fn.line("'<")
    local end_line = vim.fn.line("'>")
    if start_line == end_line then
      line_info = "#L" .. start_line
    else
      line_info = "#L" .. start_line .. "-L" .. end_line
    end
  else
    line_info = "#L" .. vim.fn.line(".")
  end

  local result = path .. line_info
  vim.fn.setreg("+", result)
  vim.notify('Copied: "' .. result .. '"')
end

M.copy_relative_path = function()
  local path = vim.fn.expand("%")
  vim.fn.setreg("+", path)
  vim.notify('Copied: "' .. path .. '"')
end

M.copy_relative_path_with_line = function()
  local path = vim.fn.expand("%")
  local line_info = ""

  if vim.fn.mode():match("[vV]") then
    local start_line = vim.fn.line("'<")
    local end_line = vim.fn.line("'>")
    if start_line == end_line then
      line_info = "#L" .. start_line
    else
      line_info = "#L" .. start_line .. "-L" .. end_line
    end
  else
    line_info = "#L" .. vim.fn.line(".")
  end

  local result = path .. line_info
  vim.fn.setreg("+", result)
  vim.notify('Copied: "' .. result .. '"')
end

return M
