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
vim.opt.laststatus = 3
vim.opt.scrolloff = 10
vim.opt.wrap = false
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.splitkeep = "screen"
vim.opt.mouse = "a"
vim.opt.cursorline = true

-- Not "unnamedplus" over SSH: Nvim auto-selects the OSC 52 clipboard
-- provider only while 'clipboard' is empty (runtime/autoload/provider/
-- clipboard.vim), and a remote host usually has no other clipboard tool, so
-- the option would leave "+ with no provider at all. Left unset, "+y and "+p
-- reach the local clipboard through OSC 52 on demand.
if not vim.env.SSH_TTY then
  vim.opt.clipboard = "unnamedplus"
end

vim.opt.inccommand = "split"

vim.opt.fillchars = {
  foldopen = "",
  foldclose = "",
  fold = " ",
  foldsep = " ",
  diff = "╱",
  eob = " ",
}
vim.opt.grepformat = "%f:%l:%c:%m"
vim.opt.grepprg = "rg --vimgrep"
vim.opt.jumpoptions = "view"
vim.opt.list = true
vim.opt.listchars = {
  eol = "↲",
  tab = "▸ ",
  trail = "•",
}
vim.opt.signcolumn = "yes"

vim.opt.updatetime = 200
vim.opt.virtualedit = "block"
vim.opt.wildmode = "longest:full,full"
vim.opt.smoothscroll = true

vim.o.winborder = "rounded"
