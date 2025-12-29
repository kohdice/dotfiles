local keymap = vim.keymap
local filepath = require("utils.filepath")

local register_safe_mappings = {
  { "n", "x", '"_x', { desc = "Delete without copying", silent = true } },
  { "n", "<Leader>p", '"0p', { desc = "Paste from yank register", silent = true } },
  { "n", "<Leader>P", '"0P', { desc = "Paste before from yank register", silent = true } },
  { "v", "<Leader>p", '"0p', { desc = "Paste from yank register (visual)", silent = true } },
  { "n", "<Leader>c", '"_c', { desc = "Change without copying", silent = true } },
  { "n", "<Leader>C", '"_C', { desc = "Change to end without copying", silent = true } },
  { "v", "<Leader>c", '"_c', { desc = "Change without copying (visual)", silent = true } },
  { "v", "<Leader>C", '"_C', { desc = "Change to end without copying (visual)", silent = true } },
  { "n", "<Leader>d", '"_d', { desc = "Delete without copying", silent = true } },
  { "n", "<Leader>D", '"_D', { desc = "Delete to end without copying", silent = true } },
  { "v", "<Leader>d", '"_d', { desc = "Delete without copying (visual)", silent = true } },
  { "v", "<Leader>D", '"_D', { desc = "Delete to end without copying (visual)", silent = true } },
}

for _, mapping in ipairs(register_safe_mappings) do
  keymap.set(mapping[1], mapping[2], mapping[3], mapping[4])
end

keymap.set("n", "<Leader>o", "o<Esc>^Da", { desc = "Insert line below without continuation", silent = true })
keymap.set("n", "<Leader>O", "O<Esc>^Da", { desc = "Insert line above without continuation", silent = true })

local window_management_mappings = {
  { "n", "te", ":tabedit<CR>", { desc = "Open new tab", silent = true } },
  -- { "n", "<Tab>", ":tabnext<CR>", { desc = "Next tab", silent = true } },
  -- { "n", "<S-Tab>", ":tabprev<CR>", { desc = "Previous tab", silent = true } },
  { "n", "tn", ":tabnext<CR>", { desc = "Next tab", silent = true } },
  { "n", "tp", ":tabprev<CR>", { desc = "Previous tab", silent = true } },
  { "n", "tc", ":tabclose<CR>", { desc = "Close tab", silent = true } },
  { "n", "ss", ":split<CR>", { desc = "Split window horizontally", silent = true } },
  { "n", "sv", ":vsplit<CR>", { desc = "Split window vertically", silent = true } },
  { "n", "sh", "<C-w>h", { desc = "Move to left window", silent = true } },
  { "n", "sk", "<C-w>k", { desc = "Move to upper window", silent = true } },
  { "n", "sj", "<C-w>j", { desc = "Move to lower window", silent = true } },
  { "n", "sl", "<C-w>l", { desc = "Move to right window", silent = true } },
  { "n", "<C-w><left>", "<C-w><", { desc = "Decrease window width", silent = true } },
  { "n", "<C-w><right>", "<C-w>>", { desc = "Increase window width", silent = true } },
  { "n", "<C-w><up>", "<C-w>+", { desc = "Increase window height", silent = true } },
  { "n", "<C-w><down>", "<C-w>-", { desc = "Decrease window height", silent = true } },
}

for _, mapping in ipairs(window_management_mappings) do
  keymap.set(mapping[1], mapping[2], mapping[3], mapping[4])
end

keymap.set("n", "<C-j>", function()
  vim.diagnostic.goto_next()
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

keymap.set("n", "<A-j>", ":move .+1<CR>==", { desc = "Move line down", silent = true })
keymap.set("n", "<A-k>", ":move .-2<CR>==", { desc = "Move line up", silent = true })

keymap.set("i", "<A-j>", "<Esc>:move .+1<CR>==gi", { desc = "Move line down", silent = true })
keymap.set("i", "<A-k>", "<Esc>:move .-2<CR>==gi", { desc = "Move line up", silent = true })

keymap.set("v", "<A-j>", ":move '>+1<CR>gv=gv", { desc = "Move selection down", silent = true })
keymap.set("v", "<A-k>", ":move '<-2<CR>gv=gv", { desc = "Move selection up", silent = true })

keymap.set({ "i", "n", "s" }, "<Esc>", function()
  vim.cmd("nohlsearch")
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
