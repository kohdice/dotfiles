return {
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local lint = require("lint")

      lint.linters_by_ft = {
        c = { "clangtidy" },
        cmake = { "cmakelint" },
        css = { "stylelint" },
        dockerfile = { "hadolint" },
        make = { "checkmake" },
        markdown = { "markdownlint-cli2" },
      }

      vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
        group = vim.api.nvim_create_augroup("lint", { clear = true }),
        callback = function()
          require("lint").try_lint()
        end,
      })
    end,
  },
}
