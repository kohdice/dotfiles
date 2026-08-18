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

--- Resolve the treesitter language to use for a buffer.
--- Returns nil when treesitter must not be used for it, so that highlighting
--- (lua/plugins/treesitter.lua) and indentation (after/indent/<ft>.lua) make
--- the same decision: enabling only one of them leaves the buffer in a mixed
--- state, and nvim-treesitter's indentexpr degrades to "keep current indent"
--- rather than to the runtime indent script when no parser is available.
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
--- Called from after/indent/<ft>.lua for the filetypes whose indent queries
--- are solid enough; every other filetype keeps its runtime indent script.
function M.set_indentexpr()
  local lang = M.usable_lang(0)
  if not lang then
    return
  end

  -- A language without an indents.scm (gomod, for one) does not make
  -- nvim-treesitter's indentexpr fail: it queries with an empty capture map
  -- and returns 0 for every line, collapsing the buffer to column 0. That is
  -- strictly worse than the runtime indent script, so leave 'indentexpr' alone.
  -- get() only returns nil for a missing query; one that exists but no longer
  -- parses (stale .scm after a parser upgrade) throws instead
  local ok, indents = pcall(vim.treesitter.query.get, lang, "indents")
  if not ok or not indents then
    return
  end

  vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"

  -- Restored by the filetypeindent autocmd on the next FileType (:h b:undo_indent).
  -- Append instead of assigning: the runtime indent script usually set it already.
  local undo = vim.b.undo_indent
  vim.b.undo_indent = (undo and undo ~= "" and undo .. " | " or "") .. "setlocal indentexpr<"
end

return M
