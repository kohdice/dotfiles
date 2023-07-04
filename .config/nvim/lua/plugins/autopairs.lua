return {
  'windwp/nvim-autopairs',
  event = 'VeryLazy',
  config = function()
    require('nvim-autopairs').setup{
      disable_filetype = { 'TelescopePrompt' , 'vim' },
    }
  end,
}
