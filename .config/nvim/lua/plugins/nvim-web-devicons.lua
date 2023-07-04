return {
  'nvim-tree/nvim-web-devicons',
  lazy = false,
  config = function()
    require('nvim-web-devicons').setup({
      default = true,
      strict = true,
    })
  end
}
