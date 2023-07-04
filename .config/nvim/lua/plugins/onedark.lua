return {
  -- Theme inspired by Atom
  'navarasu/onedark.nvim',
  priority = 1000,
  config = function()
    require('onedark').setup{
      style = 'dark',
      transparent = true,
      code_style = {
        comments = 'italic'
      }
    }
    vim.cmd.colorscheme 'onedark'
  end,
}
