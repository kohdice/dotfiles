return {
  'iamcco/markdown-preview.nvim',
  event = 'BufRead',
  run = function()
    vim.fn['mkdp#util#install']()
  end,
  keys = {
    {
      '<leader>mp',
      '<Plug>MarkdownPreview',
      desc = 'Markdown Preview'
    }
  }
}
