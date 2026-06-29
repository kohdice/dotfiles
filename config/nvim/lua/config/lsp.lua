-- Global capabilities (enhanced with blink.cmp if available)
local capabilities = vim.lsp.protocol.make_client_capabilities()
local has_blink, blink = pcall(require, "blink.cmp")
if has_blink then
  capabilities = blink.get_lsp_capabilities(capabilities)
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

    -- Built-in defaults (:h lsp-defaults) cover grn/gra/K; override the
    -- list-style results with fzf-lua pickers
    nmap("gd", vim.lsp.buf.definition, "[G]oto [D]efinition")
    nmap("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
    nmap("grr", "<cmd>FzfLua lsp_references<cr>", "[R]eferences")
    nmap("gri", "<cmd>FzfLua lsp_implementations<cr>", "[I]mplementations")
    nmap("grt", "<cmd>FzfLua lsp_typedefs<cr>", "[T]ype Definitions")
    nmap("gO", "<cmd>FzfLua lsp_document_symbols<cr>", "Document Symbols")

    nmap("gK", vim.lsp.buf.signature_help, "Signature Documentation")

    -- C/C++ specific keymaps
    if client.name == "clangd" then
      nmap("<leader>ch", "<cmd>ClangdSwitchSourceHeader<cr>", "Switch Source/Header (C/C++)")
    end

    -- Document highlighting (cleaned up on LspDetach)
    if client:supports_method("textDocument/documentHighlight") then
      local highlight_group = vim.api.nvim_create_augroup("my-lsp-highlight", { clear = false })

      vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
        group = highlight_group,
        buffer = bufnr,
        callback = vim.lsp.buf.document_highlight,
      })

      vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
        group = highlight_group,
        buffer = bufnr,
        callback = vim.lsp.buf.clear_references,
      })

      vim.api.nvim_create_autocmd("LspDetach", {
        group = vim.api.nvim_create_augroup("my-lsp-detach", { clear = true }),
        callback = function(args2)
          vim.lsp.buf.clear_references()
          vim.api.nvim_clear_autocmds({ group = "my-lsp-highlight", buffer = args2.buf })
        end,
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
  "tsgo",
  "yamlls",
  "zls",
}
vim.lsp.enable(servers)
