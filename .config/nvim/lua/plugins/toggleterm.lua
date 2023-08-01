return {
  'akinsho/toggleterm.nvim',
  version = '*',
  config = function()
    require('toggleterm').setup{
      size = 35,
      hide_numbers = true,
      open_mapping = [[<c-\>]],
    }
    function _G.set_terminal_keymaps()
      local opts = { noremap = true }
      vim.api.nvim_set_keymap('t', '<esc>', [[<C-\><C-n>]], opts)
    end
    local Terminal = require('toggleterm.terminal').Terminal
    local lazygit = Terminal:new({
      cmd = 'lazygit',
      direction = 'float',
      hidden = true
    })

    function _lazygit_toggle()
      lazygit:toggle()
    end

    vim.api.nvim_set_keymap('n', '<Leader>lg', '<cmd>lua _lazygit_toggle()<CR>', { noremap = true, silent = true })
  end
}
