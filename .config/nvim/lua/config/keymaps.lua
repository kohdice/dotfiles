-- [[ Basic Keymaps ]]

-- Keymaps for better default experience
-- See `:help vim.keymap.set()`
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Remap for dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Do not yank with x
vim.keymap.set('n', 'x', '"_x')

-- Increment/decrement
vim.keymap.set('n', '+', '<C-a>')
vim.keymap.set('n', '-', '<C-x>')

-- Delete a word backwards
vim.keymap.set('n', 'dw', 'vb"_d')

-- Select all
vim.keymap.set('n', '<C-a>', 'gg<S-v>G')

-- New tab
vim.keymap.set('n', 'te', ':tabedit')

-- Split window
vim.keymap.set('n', 'ss', ':split<Return><C-w>w')
vim.keymap.set('n', 'sv', ':vsplit<Return><C-w>w')

-- Move window
vim.keymap.set('n', '<Leader>w', '<C-w>w')
vim.keymap.set('', '<Leader>h', '<C-w>h')
vim.keymap.set('', '<Leader>k', '<C-w>k')
vim.keymap.set('', '<Leader>j', '<C-w>j')
vim.keymap.set('', '<Leader>l', '<C-w>l')

-- Resize window
vim.keymap.set('n', '<C-w><left>', '<C-w><')
vim.keymap.set('n', '<C-w><right>', '<C-w>>')
vim.keymap.set('n', '<C-w><up>', '<C-w>+')
vim.keymap.set('n', '<C-w><down>', '<C-w>-')

-- Save with root permission
--vim.api.nvim_create_user_command('W', 'w !sudo tee > /dev/null %', {})
