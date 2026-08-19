vim.g.mapleader = " "
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.title = true
vim.opt.shell = "zsh"

vim.opt.smartindent = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4

vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.cmdheight = 0
vim.opt.laststatus = 3 -- 3 = one global statusline instead of one per window
vim.opt.scrolloff = 10
vim.opt.wrap = false
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.splitkeep = "screen"
vim.opt.mouse = "a"
vim.opt.cursorline = true

-- Over SSH, leave clipboard unset: "unnamedplus" would route every yank/put
-- through the OSC 52 terminal roundtrip instead of using it on demand via "+
vim.opt.clipboard = vim.env.SSH_TTY and "" or "unnamedplus"

vim.opt.inccommand = "split"

-- The blank entries hide the default '·' fold filler and '~' end-of-buffer marker
vim.opt.fillchars = {
  foldopen = "",
  foldclose = "",
  fold = " ",
  foldsep = " ",
  diff = "╱",
  eob = " ",
}
vim.opt.grepformat = "%f:%l:%c:%m" -- Matches rg --vimgrep output
vim.opt.grepprg = "rg --vimgrep"
vim.opt.jumpoptions = "view"
vim.opt.list = true
vim.opt.listchars = {
  eol = "↲",
  tab = "▸ ",
  trail = "•",
}
vim.opt.signcolumn = "yes" -- Always reserved so text does not shift when signs appear

vim.opt.timeoutlen = 300
vim.opt.updatetime = 200 -- Drives how soon CursorHold fires (LSP document highlight, config/lsp.lua)
vim.opt.virtualedit = "block"
vim.opt.wildmode = "longest:full,full" -- First Tab completes the longest common prefix, later Tabs cycle matches
vim.opt.smoothscroll = true

vim.o.winborder = "rounded"
