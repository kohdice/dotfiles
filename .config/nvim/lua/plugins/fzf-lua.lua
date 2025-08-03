return {
  "ibhagwan/fzf-lua",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  cmd = "FzfLua",
  keys = {
    { ";f", "<cmd>FzfLua files<cr>", desc = "Find files" },
    { ";r", "<cmd>FzfLua live_grep<cr>", desc = "Live grep" },
    { "\\\\", "<cmd>FzfLua buffers<cr>", desc = "Buffers" },
    { ";t", "<cmd>FzfLua help_tags<cr>", desc = "Help tags" },
    { ";;", "<cmd>FzfLua resume<cr>", desc = "Resume last search" },
    { ";e", "<cmd>FzfLua diagnostics_document<cr>", desc = "Document diagnostics" },
    { ";s", "<cmd>FzfLua treesitter<cr>", desc = "Treesitter symbols" },

    { "<leader>gc", "<cmd>FzfLua git_commits<cr>", desc = "Git commits" },
    { "<leader>gs", "<cmd>FzfLua git_status<cr>", desc = "Git status" },
    { "<leader>gb", "<cmd>FzfLua git_branches<cr>", desc = "Git branches" },
    { "<leader>fh", "<cmd>FzfLua command_history<cr>", desc = "Command history" },
    { "<leader>fm", "<cmd>FzfLua marks<cr>", desc = "Marks" },
    { "<leader>fk", "<cmd>FzfLua keymaps<cr>", desc = "Keymaps" },
  },
  opts = {
    files = {
      git_icons = true,
      find_opts = [[-type f -not -path '*/\.git/*' -printf '%P\n']],
      rg_opts = "--color=never --files --hidden --follow -g '!.git'",
      fd_opts = "--color=never --type f --hidden --follow --exclude .git",
    },
    grep = {
      git_icons = true,
      rg_opts = "--column --line-number --no-heading --color=always --smart-case --max-columns=4096 -e",
    },
    lsp = {
      prompt_postfix = "❯ ",
    },
    fzf_colors = true,
    fzf_opts = {
      ["--layout"] = "default",
    },
  },
}
