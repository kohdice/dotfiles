local Snacks = require("snacks")

Snacks.setup({
  indent = {
    enabled = true,
    -- Static guides: the scope animation only adds redraws
    animate = { enabled = false },
  },
  picker = {
    enabled = true,
    sources = {
      files = { hidden = true, follow = true },
      grep = { hidden = true },
    },
    layouts = {
      -- The default preset with input and list swapped, so the prompt sits at
      -- the bottom and results grow upward as in fzf and the cmdline wildmenu.
      -- A new name rather than an override of "default": layouts are merged
      -- with vim.tbl_deep_extend, which would blend the swapped entries index
      -- by index
      fzf = {
        reverse = true,
        layout = {
          box = "horizontal",
          width = 0.8,
          min_width = 120,
          height = 0.8,
          {
            box = "vertical",
            border = true,
            title = "{title} {live} {flags}",
            { win = "list", border = "none" },
            { win = "input", height = 1, border = "top" },
          },
          { win = "preview", title = "{preview}", border = true, width = 0.5 },
        },
      },
    },
    layout = {
      -- A function, not preset = "fzf": a plain string drops snacks' own
      -- fallback to the "vertical" layout on narrow windows
      preset = function()
        return vim.o.columns >= 120 and "fzf" or "vertical"
      end,
    },
  },
  -- No ]] / [[ keymaps here: they are buffer-local in config/lsp.lua, only
  -- where a client answers documentHighlight
  words = { enabled = true },
})

local map = function(lhs, rhs, desc)
  vim.keymap.set("n", lhs, rhs, { desc = desc })
end

map(";f", Snacks.picker.files, "Find files")
map(";.", function()
  Snacks.picker.files({ cwd = vim.fn.expand("%:p:h") })
end, "Find files in current directory")
map(";r", Snacks.picker.grep, "Live grep")
map("\\\\", Snacks.picker.buffers, "Buffers")
map(";t", Snacks.picker.help, "Help tags")
map(";;", Snacks.picker.resume, "Resume last picker")
map(";e", Snacks.picker.diagnostics_buffer, "Document diagnostics")
map(";s", Snacks.picker.treesitter, "Treesitter symbols")

map("<leader>gc", Snacks.picker.git_log, "Git commits")
map("<leader>gs", Snacks.picker.git_status, "Git status")
map("<leader>gb", Snacks.picker.git_branches, "Git branches")
map(";h", Snacks.picker.git_diff, "Git diff hunks")
map("<leader>fh", Snacks.picker.command_history, "Command history")
map("<leader>fm", Snacks.picker.marks, "Marks")
map("<leader>fk", Snacks.picker.keymaps, "Keymaps")

-- Terminal mode too, so the same key hides the window from inside the shell
vim.keymap.set({ "n", "t" }, "<C-\\>", function()
  Snacks.terminal.toggle()
end, { desc = "Toggle terminal" })
map("<leader>tf", function()
  Snacks.terminal.toggle()
end, "Toggle floating terminal")
map("<leader>th", function()
  Snacks.terminal.toggle(nil, { win = { position = "bottom" } })
end, "Toggle horizontal terminal")
map("<leader>tv", function()
  Snacks.terminal.toggle(nil, { win = { position = "right" } })
end, "Toggle vertical terminal")
