-- No setup(): grug-far's plugin file defines :GrugFar with defaults
vim.keymap.set("n", "<leader>sr", "<cmd>GrugFar<cr>", { desc = "Search and Replace" })
vim.keymap.set("v", "<leader>sr", ":<C-u>'<,'>GrugFar<cr>", { desc = "Search and Replace (selection)" })
