local trouble = require("trouble")

trouble.setup({
  modes = {
    lsp = {
      win = { position = "right" },
    },
  },
})

local map = function(lhs, rhs, desc)
  vim.keymap.set("n", lhs, rhs, { desc = desc })
end

map("<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", "Diagnostics (Trouble)")
map("<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", "Buffer Diagnostics (Trouble)")
map("<leader>cs", "<cmd>Trouble symbols toggle<cr>", "Symbols (Trouble)")
map("<leader>cS", "<cmd>Trouble lsp toggle<cr>", "LSP references/definitions/... (Trouble)")
map("<leader>xL", "<cmd>Trouble loclist toggle<cr>", "Location List (Trouble)")
map("<leader>xQ", "<cmd>Trouble qflist toggle<cr>", "Quickfix List (Trouble)")

map("[q", function()
  if trouble.is_open() then
    trouble.prev({ skip_groups = true, jump = true })
  else
    local ok, err = pcall(vim.cmd.cprev)
    if not ok then
      vim.notify(err, vim.log.levels.ERROR)
    end
  end
end, "Previous Trouble/Quickfix Item")

map("]q", function()
  if trouble.is_open() then
    trouble.next({ skip_groups = true, jump = true })
  else
    local ok, err = pcall(vim.cmd.cnext)
    if not ok then
      vim.notify(err, vim.log.levels.ERROR)
    end
  end
end, "Next Trouble/Quickfix Item")
