local M = {}

-- Above this size the parse cost outweighs the benefit, so the buffer keeps
-- the runtime syntax highlighting and indent script
local MAX_FILESIZE = 100 * 1024

-- Scratch-like buffers never hold source worth parsing. Deny-list rather
-- than allow-list: diffview gives its revision buffers buftype=nowrite,
-- and those must highlight like the file they are diffed against
local SKIP_BUFTYPES = {
  nofile = true,
  prompt = true,
  quickfix = true,
  terminal = true,
}

--- Resolve the treesitter language to use for a buffer, or nil when treesitter
--- must not be used. Single gate so highlighting (lua/plugins/treesitter.lua)
--- and indentation (after/indent/<ft>.lua) never disagree.
---@param bufnr integer
---@return string|nil
function M.usable_lang(bufnr)
  if SKIP_BUFTYPES[vim.bo[bufnr].buftype] then
    return nil
  end

  local lang = vim.treesitter.language.get_lang(vim.bo[bufnr].filetype)
  if not lang then
    return nil
  end

  -- add() returns false for a missing parser, but throws on a parser that
  -- exists yet fails to load (ABI mismatch after an nvim upgrade)
  local ok, added = pcall(vim.treesitter.language.add, lang)
  if not ok or not added then
    return nil
  end

  local stat_ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(bufnr))
  if stat_ok and stats and stats.size > MAX_FILESIZE then
    return nil
  end

  return lang
end

--- Opt the current buffer into treesitter indentation.
--- Called from after/indent/<ft>.lua, not after/ftplugin/: the runtime indent
--- script runs later and would overwrite 'indentexpr'. Only for filetypes
--- whose indent queries are solid enough; the rest keep their indent script.
function M.set_indentexpr()
  local lang = M.usable_lang(0)
  if not lang then
    return
  end

  -- Without an indents.scm (gomod, for one) nvim-treesitter's indentexpr
  -- collapses every line to column 0. pcall: get() throws on a stale .scm.
  local ok, indents = pcall(vim.treesitter.query.get, lang, "indents")
  if not ok or not indents then
    return
  end

  vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"

  -- Append, not assign: the runtime indent script already set b:undo_indent.
  local undo = vim.b.undo_indent
  vim.b.undo_indent = (undo and undo ~= "" and undo .. " | " or "") .. "setlocal indentexpr<"
end

return M
