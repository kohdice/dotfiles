-- gitsigns: Git integration for buffers
return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    signs = {
      add = { text = "▎" },
      change = { text = "▎" },
      delete = { text = "" },
      topdelete = { text = "" },
      changedelete = { text = "▎" },
      untracked = { text = "▎" },
    },
    on_attach = function(bufnr)
      local gitsigns = require("gitsigns")

      local function map(mode, l, r, desc)
        vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
      end

      -- Navigation
      map("n", "]c", function()
        if vim.wo.diff then
          vim.cmd.normal({ "]c", bang = true })
        else
          gitsigns.nav_hunk("next")
        end
      end, "Next git hunk")

      map("n", "[c", function()
        if vim.wo.diff then
          vim.cmd.normal({ "[c", bang = true })
        else
          gitsigns.nav_hunk("prev")
        end
      end, "Previous git hunk")

      -- Actions
      map("n", "<leader>hs", gitsigns.stage_hunk, "Stage hunk")
      map("n", "<leader>hr", gitsigns.reset_hunk, "Reset hunk")

      map("v", "<leader>hs", function()
        gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
      end, "Stage hunk")

      map("v", "<leader>hr", function()
        gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
      end, "Reset hunk")

      map("n", "<leader>hS", gitsigns.stage_buffer, "Stage buffer")
      map("n", "<leader>hR", gitsigns.reset_buffer, "Reset buffer")
      map("n", "<leader>hp", gitsigns.preview_hunk, "Preview hunk")
      map("n", "<leader>hi", gitsigns.preview_hunk_inline, "Preview hunk inline")

      map("n", "<leader>hb", function()
        gitsigns.blame_line({ full = true })
      end, "Blame line")

      map("n", "<leader>hd", gitsigns.diffthis, "Diff this")

      map("n", "<leader>hD", function()
        gitsigns.diffthis("~")
      end, "Diff this ~")

      map("n", "<leader>hQ", function()
        gitsigns.setqflist("all")
      end, "Quickfix all hunks")
      map("n", "<leader>hq", gitsigns.setqflist, "Quickfix buffer hunks")

      -- Toggles
      map("n", "<leader>tb", gitsigns.toggle_current_line_blame, "Toggle blame line")
      map("n", "<leader>td", gitsigns.toggle_deleted, "Toggle deleted")
      map("n", "<leader>tw", gitsigns.toggle_word_diff, "Toggle word diff")

      -- Text object
      map({ "o", "x" }, "ih", gitsigns.select_hunk, "Select hunk")
    end,
  },
}
