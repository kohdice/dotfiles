local oil = require("oil")

oil.setup({
  view_options = { show_hidden = true },
  watch_for_changes = true,
  keymaps = {
    ["h"] = { "actions.parent", mode = "n" },
    ["l"] = "actions.select",
    ["q"] = { "actions.close", mode = "n" },
    ["Y"] = {
      callback = function()
        local entry = oil.get_cursor_entry()
        local dir = oil.get_current_dir()
        if entry and dir then
          vim.fn.setreg("+", dir .. entry.name)
        end
      end,
      desc = "Copy path to clipboard",
      mode = "n",
    },
  },
})

vim.keymap.set("n", "<leader>e", oil.toggle_float, { desc = "Toggle file explorer" })
vim.keymap.set("n", "-", "<cmd>Oil<cr>", { desc = "Open parent directory" })
