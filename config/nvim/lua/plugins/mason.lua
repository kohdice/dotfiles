return {
  {
    "williamboman/mason.nvim",
    lazy = false,
    build = ":MasonUpdate",
    opts = {
      ensure_installed = {
        "checkmake",
        "clang-format",
        "cmakelang",
        "cmakelint",
        "hadolint",
        "markdownlint-cli2",
        "prettier",
        "prettierd",
        "stylelint",
        "taplo",
        "yamlfmt",
      },
      ui = {
        icons = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗",
        },
      },
    },
    config = function(_, opts)
      require("mason").setup(opts)
      local mr = require("mason-registry")
      mr:on("package:install:success", function()
        vim.defer_fn(function()
          vim.cmd("doautocmd FileType")
        end, 100)
      end)

      mr.refresh(function()
        for _, tool in ipairs(opts.ensure_installed) do
          local p = mr.get_package(tool)
          if not p:is_installed() then
            p:install()
          end
        end
      end)
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    lazy = false,
    dependencies = {
      "williamboman/mason.nvim",
    },
    opts = {
      ensure_installed = {
        "clangd",
        "cssls",
        "dockerls",
        "emmet_ls",
        "gopls",
        "html",
        "jsonls",
        "lua_ls",
        "marksman",
        "neocmake",
        "rust_analyzer",
        "taplo",
        "terraformls",
        "ts_ls",
        "yamlls",
        "zls",
      },
      automatic_installation = true,
    },
  },
}
