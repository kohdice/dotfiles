local keymap = vim.keymap
local filepath = require("utils.filepath")

-- Kept one level down under <Leader>m* instead of directly under <Leader>:
-- <Leader>c was both a complete mapping and the prefix of <leader>cf/cs/cS/ch,
-- so it shadowed those motions and cost a 'timeoutlen' wait. <Leader>m* is
-- otherwise used only by marp (mw/ms/me/mt), which does not collide here.
local register_safe_mappings = {
  { "n", "x", '"_x', { desc = "Delete without copying", silent = true } },
  { "n", "<Leader>mp", '"0p', { desc = "Paste from yank register", silent = true } },
  { "n", "<Leader>mP", '"0P', { desc = "Paste before from yank register", silent = true } },
  { "v", "<Leader>mp", '"0p', { desc = "Paste from yank register (visual)", silent = true } },
  { "n", "<Leader>mc", '"_c', { desc = "Change without copying", silent = true } },
  { "n", "<Leader>mC", '"_C', { desc = "Change to end without copying", silent = true } },
  { "v", "<Leader>mc", '"_c', { desc = "Change without copying (visual)", silent = true } },
  { "v", "<Leader>mC", '"_C', { desc = "Change to end without copying (visual)", silent = true } },
  { "n", "<Leader>md", '"_d', { desc = "Delete without copying", silent = true } },
  { "n", "<Leader>mD", '"_D', { desc = "Delete to end without copying", silent = true } },
  { "v", "<Leader>md", '"_d', { desc = "Delete without copying (visual)", silent = true } },
  { "v", "<Leader>mD", '"_D', { desc = "Delete to end without copying (visual)", silent = true } },
}

for _, mapping in ipairs(register_safe_mappings) do
  keymap.set(mapping[1], mapping[2], mapping[3], mapping[4])
end

keymap.set("n", "<Leader>o", "o<Esc>^Da", { desc = "Insert line below without continuation", silent = true })
keymap.set("n", "<Leader>O", "O<Esc>^Da", { desc = "Insert line above without continuation", silent = true })

keymap.set("n", "<C-w><left>", "<C-w><", { desc = "Decrease window width", silent = true })
keymap.set("n", "<C-w><right>", "<C-w>>", { desc = "Increase window width", silent = true })
keymap.set("n", "<C-w><up>", "<C-w>+", { desc = "Increase window height", silent = true })
keymap.set("n", "<C-w><down>", "<C-w>-", { desc = "Decrease window height", silent = true })

keymap.set("n", "<C-j>", function()
  vim.diagnostic.jump({ count = 1 })
end, { desc = "Go to next diagnostic", silent = true })

keymap.set(
  { "n", "x" },
  "j",
  "v:count == 0 ? 'gj' : 'j'",
  { desc = "Move down (wrap-aware)", expr = true, silent = true }
)
keymap.set(
  { "n", "x" },
  "<Down>",
  "v:count == 0 ? 'gj' : 'j'",
  { desc = "Move down (wrap-aware)", expr = true, silent = true }
)
keymap.set(
  { "n", "x" },
  "k",
  "v:count == 0 ? 'gk' : 'k'",
  { desc = "Move up (wrap-aware)", expr = true, silent = true }
)
keymap.set(
  { "n", "x" },
  "<Up>",
  "v:count == 0 ? 'gk' : 'k'",
  { desc = "Move up (wrap-aware)", expr = true, silent = true }
)

-- ':move' past either end of the buffer fails with E16, and 'silent' does not
-- suppress an error: the mapping aborts there, so its trailing keys never run
-- (insert mode is left behind without gi, the selection is dropped without
-- gv=gv). Swallow the key instead. line("v") is the cursor line outside Visual
-- mode, so the same bounds check covers all three modes; <Ignore> rather than
-- an empty string because an expr mapping that returns nothing ends Visual mode.
local function move_lines(keys, offset)
  return function()
    local cursor, other = vim.fn.line("."), vim.fn.line("v")
    local edge = offset > 0 and math.max(cursor, other) or math.min(cursor, other)
    if edge + offset < 1 or edge + offset > vim.fn.line("$") then
      return "<Ignore>"
    end
    return keys
  end
end

local move_line_down = { desc = "Move line down", expr = true, silent = true }
local move_line_up = { desc = "Move line up", expr = true, silent = true }
local move_selection_down = { desc = "Move selection down", expr = true, silent = true }
local move_selection_up = { desc = "Move selection up", expr = true, silent = true }

keymap.set("n", "<A-j>", move_lines(":move .+1<CR>==", 1), move_line_down)
keymap.set("n", "<A-k>", move_lines(":move .-2<CR>==", -1), move_line_up)

keymap.set("i", "<A-j>", move_lines("<Esc>:move .+1<CR>==gi", 1), move_line_down)
keymap.set("i", "<A-k>", move_lines("<Esc>:move .-2<CR>==gi", -1), move_line_up)

keymap.set("v", "<A-j>", move_lines(":move '>+1<CR>gv=gv", 1), move_selection_down)
keymap.set("v", "<A-k>", move_lines(":move '<-2<CR>gv=gv", -1), move_selection_up)

keymap.set({ "i", "n", "s" }, "<Esc>", function()
  vim.cmd.nohlsearch()
  return vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
end, { desc = "Escape and Clear hlsearch", expr = true, silent = true })

keymap.set({ "n", "v" }, "<Leader>ya", filepath.copy_absolute_path, { desc = "Copy absolute path", silent = true })
keymap.set(
  { "n", "v" },
  "<Leader>yA",
  filepath.copy_absolute_path_with_line,
  { desc = "Copy absolute path with line", silent = true }
)
keymap.set({ "n", "v" }, "<Leader>yr", filepath.copy_relative_path, { desc = "Copy relative path", silent = true })
keymap.set(
  { "n", "v" },
  "<Leader>yR",
  filepath.copy_relative_path_with_line,
  { desc = "Copy relative path with line", silent = true }
)

keymap.set("n", "<Leader>S", function()
  vim.cmd("enew")
  vim.bo.buftype = "nofile"
  vim.bo.bufhidden = "hide"
  vim.bo.swapfile = false
end, { desc = "Open scratch buffer", silent = true })
