-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are required (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- [[ Setting options ]]
-- See `:help vim.o`

-- Set highlight on search
vim.o.hlsearch = false

-- Make line numbers default
vim.wo.number = true

-- Enable mouse mode
vim.o.mouse = 'a'

-- Sync clipboard between OS and Neovim.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.o.clipboard = 'unnamedplus'

-- Enable break indent
vim.o.breakindent = true

-- Save undo history
vim.o.undofile = true

-- Case-insensitive searching UNLESS \C or capital in search
vim.o.ignorecase = true
vim.o.smartcase = true

-- Keep signcolumn on by default
vim.wo.signcolumn = 'yes'

-- Decrease update time
vim.o.updatetime = 250
vim.o.timeout = true
vim.o.timeoutlen = 300

-- Set completeopt to have a better completion experience
vim.o.completeopt = 'menuone,noselect'

-- NOTE: You should make sure your terminal supports this
vim.o.termguicolors = true

-- Display invisible characters
vim.opt.list = true
vim.opt.listchars = {
  tab = '|»',
  -- space = '⋅' ,
  nbsp = '%',
  eol = '↲',
}

-- Set file encoding and script encoding to UTF-8
vim.scriptencoding = 'utf-8'
vim.opt.encoding = 'utf-8'
vim.opt.fileencoding = 'utf-8'

-- File name will appear in the terminal window title
vim.opt.title = true

-- Configure backup creation settings, specify paths for files not to be backed up
vim.opt.backup = false
vim.opt.backupskip = { '/tmp/*', '/private/tmp/*' }

-- Height of command line
vim.opt.cmdheight = 1

-- Status line at the bottom of the window
vim.opt.laststatus = 2

-- Set the number of lines to scroll when the cursor approaches the edge of the screen
vim.opt.scrolloff = 10

-- No Wrap lines
vim.opt.wrap = false

-- Set shell used to execute commands
vim.opt.shell = 'fish'

-- indentation
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.smarttab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 4
vim.opt.expandtab = true

-- Backspace key behavior in insert mode
vim.opt.backspace = { 'start', 'eol', 'indent' }

-- Finding files - Search down into subfolders
vim.opt.path:append { '**' }

-- Preview on command line when searching
-- Horizontal split to show preview
vim.opt.inccommand = 'split'

-- Turn off paste mode when leaving insert
vim.api.nvim_create_autocmd("InsertLeave", {
    pattern = '*',
    command = "set nopaste"
})

-- Add asterisks in block comments
vim.opt.formatoptions:append { 'r' }
