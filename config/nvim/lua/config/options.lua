-- General Settings
vim.g.mapleader = " " -- Set leader key to space
vim.g.ai_cmp = true -- Enable AI completion via nvim-cmp (for Copilot integration)
vim.opt.number = true -- Enable line numbers
vim.opt.relativenumber = true -- Enable relative line numbers
vim.opt.title = true -- Show window title
vim.opt.backup = false -- Disable backup files
vim.opt.backupskip = { "/tmp/*", "/private/tmp/*" } -- Skip backup for temporary files
vim.opt.shell = "zsh" -- Set default shell to Zsh

-- Indentation Settings
vim.opt.smartindent = true -- Automatically indent based on syntax
vim.opt.expandtab = true -- Use spaces instead of tabs
vim.opt.shiftwidth = 4 -- Number of spaces per indentation level
vim.opt.tabstop = 4 -- Number of spaces a tab counts for

-- Search Settings
vim.opt.ignorecase = true -- Case-insensitive searching unless capital letter is used
vim.opt.smartcase = true -- Override ignorecase when search contains uppercase letters

-- Interface Settings
vim.opt.cmdheight = 0 -- Hide command line when not in use (Neovim 0.8+ required)
vim.opt.laststatus = 3 -- Use a global statusline
vim.opt.scrolloff = 10 -- Keep 10 lines above/below cursor when scrolling
vim.opt.wrap = false -- Disable line wrapping
vim.opt.splitbelow = true -- Open horizontal splits below current window
vim.opt.splitright = true -- Open vertical splits to the right
vim.opt.splitkeep = "screen" -- Keep scroll position when splitting
vim.opt.mouse = "a" -- Enable mouse support in all modes
vim.opt.cursorline = true -- Highlight the current line

-- Clipboard & Completion Settings
vim.opt.clipboard = vim.env.SSH_TTY and "" or "unnamedplus" -- Sync with system clipboard
vim.opt.completeopt = "menu,menuone,noselect" -- Configure completion behavior

-- Command Execution Settings
vim.opt.inccommand = "split" -- Preview incremental substitution results in a split

-- Terminal Undercurl Support (for GUI)
vim.cmd([[let &t_Cs = "\e[4:3m"]]) -- Enable undercurl for terminal
vim.cmd([[let &t_Ce = "\e[4:0m"]]) -- Disable undercurl for terminal

-- UI Enhancements
vim.opt.fillchars = {
  foldopen = "", -- Icon for opened folds
  foldclose = "", -- Icon for closed folds
  fold = " ", -- Hide fold background
  foldsep = " ", -- Hide fold separators
  diff = "╱", -- Symbol for diff view
  eob = " ", -- Hide End-of-Buffer markers
}
vim.opt.grepformat = "%f:%l:%c:%m" -- Configure grep output format
vim.opt.grepprg = "rg --vimgrep" -- Use ripgrep for searching
vim.opt.jumpoptions = "view" -- Preserve cursor position when jumping
vim.opt.list = true -- Display hidden characters
vim.opt.listchars = {
  eol = "↲", -- End-of-line character
  tab = "▸ ", -- Tab character
  trail = "•", -- Trailing spaces
}
vim.opt.signcolumn = "yes" -- Always show sign column to avoid text shifting

-- Performance Optimizations
vim.opt.timeoutlen = vim.g.vscode and 1000 or 300 -- Adjust timeout for key sequences
vim.opt.updatetime = 200 -- Reduce time before triggering CursorHold event
vim.opt.virtualedit = "block" -- Allow cursor to move past end of line in visual block mode
vim.opt.wildmode = "longest:full,full" -- Configure command-line completion behavior
vim.opt.smoothscroll = true -- Enable smooth scrolling

-- Floating Window Borders (Neovim 0.11+)
vim.o.winborder = "rounded" -- Add rounded borders to all floating windows

-- Diagnostic Display
vim.diagnostic.config({
  virtual_text = {
    source = "if_many",
    prefix = "●",
  },
  float = {
    source = "if_many",
    border = "rounded",
  },
  severity_sort = true,
})
