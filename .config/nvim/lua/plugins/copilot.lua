return {
  'github/copilot.vim',
  lazy=false,
  config = function ()
    vim.g.copilot_no_tab_map = true
    vim.keymap.set(
      'i',
      '<C-o>',
      'copilot#Accept("<CR>")',
      { silent = true, expr = true, script = true, replace_keycodes = false, desc = 'Copilot accept' }
    )
    vim.keymap.set('i', '<C-j>', '<Plug>(copilot-next)', { desc = 'Copilot next' })
    vim.keymap.set('i', '<C-k>', '<Plug>(copilot-previous)', { desc = 'Copilot previous' })
    vim.keymap.set('i', '<C-d>', '<Plug>(copilot-dismiss)', { desc = 'Copilot dismiss' })
    vim.keymap.set('i', '<C-s>', '<Plug>(copilot-suggest)', { desc = 'Copilot suggest' })
    vim.keymap.set('n', '<Leader>ce', '<cmd>Copilot enable<CR>', { desc = 'Copilot enable' })
    vim.keymap.set('n', '<Leader>cd', '<cmd>Copilot disable<CR>', { desc = 'Copilot disable' })
    vim.keymap.set('n', '<Leader>cs', '<cmd>Copilot status<CR>', { desc = 'Copilot status' })
  end
}
