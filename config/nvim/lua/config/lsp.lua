-- Global capabilities (enhanced with cmp-nvim-lsp if available)
-- Note: cmp-nvim-lsp is available before InsertEnter via lazy.nvim require loading
local capabilities = vim.lsp.protocol.make_client_capabilities()
local has_cmp, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
if has_cmp then
  capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
end

vim.lsp.config("*", {
  capabilities = capabilities,
})

-- LspAttach autocmd (keymaps, document highlighting)
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("my-lsp-attach", { clear = true }),
  callback = function(args)
    local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
    local bufnr = args.buf

    local nmap = function(keys, func, desc)
      if desc then
        desc = "LSP: " .. desc
      end
      vim.keymap.set("n", keys, func, { buf = bufnr, desc = desc })
    end

    nmap("gd", vim.lsp.buf.definition, "[G]oto [D]efinition")
    nmap("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
    nmap("gi", vim.lsp.buf.implementation, "[G]oto [I]mplementation")
    nmap("gr", "<cmd>FzfLua lsp_references<cr>", "[G]oto [R]eferences")
    nmap("gt", vim.lsp.buf.type_definition, "[G]oto [T]ype Definition")
    nmap("gds", "<cmd>FzfLua lsp_document_symbols<cr>", "[D]ocument [S]ymbols")
    nmap("gws", "<cmd>FzfLua lsp_workspace_symbols<cr>", "[W]orkspace [S]ymbols")

    nmap("gK", vim.lsp.buf.signature_help, "Signature Documentation")

    -- Format via conform (unified formatting through conform.nvim)
    nmap("<leader>f", function()
      require("conform").format({ async = true, lsp_format = "fallback" })
    end, "[F]ormat")

    -- C/C++ specific keymaps
    if client.name == "clangd" then
      nmap("<leader>ch", "<cmd>ClangdSwitchSourceHeader<cr>", "Switch Source/Header (C/C++)")
    end

    -- Document highlighting
    if client and client.server_capabilities.documentHighlightProvider then
      vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
        buffer = bufnr,
        callback = vim.lsp.buf.document_highlight,
      })

      vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
        buffer = bufnr,
        callback = vim.lsp.buf.clear_references,
      })
    end
  end,
})

-- Enable servers
local servers = {
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
}
vim.lsp.enable(servers)
