local Snacks = require("snacks")

vim.diagnostic.config({
  virtual_text = {
    source = "if_many",
    prefix = "●",
  },
  float = {
    source = "if_many",
  },
  severity_sort = true,
})

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
    -- list-style results with snacks pickers
    nmap("gd", vim.lsp.buf.definition, "[G]oto [D]efinition")
    nmap("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
    nmap("grr", Snacks.picker.lsp_references, "[R]eferences")
    nmap("gri", Snacks.picker.lsp_implementations, "[I]mplementations")
    nmap("grt", Snacks.picker.lsp_type_definitions, "[T]ype Definitions")
    nmap("gO", Snacks.picker.lsp_symbols, "Document Symbols")

    nmap("gK", vim.lsp.buf.signature_help, "Signature Documentation")

    if client.name == "clangd" then
      nmap("<leader>ch", "<cmd>ClangdSwitchSourceHeader<cr>", "Switch Source/Header (C/C++)")
    end

    -- bufnr is required, not optional: omitted, supports_method() falls back to
    -- the current buffer, and LspAttach also fires for background ones
    if client:supports_method("textDocument/inlayHint", bufnr) then
      vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
    end

    -- Buffer-local, so the built-in ]] / [[ section motions stay intact where
    -- no client answers documentHighlight
    if client:supports_method("textDocument/documentHighlight", bufnr) then
      nmap("]]", function()
        Snacks.words.jump(vim.v.count1)
      end, "Next reference")
      nmap("[[", function()
        Snacks.words.jump(-vim.v.count1)
      end, "Prev reference")
    end
  end,
})

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
  "tsc",
  "yamlls",
  "zls",
}

-- Explicit rather than relying on blink's plugin/ file: that file runs after
-- init.lua, and this keeps the server capabilities independent of load order
vim.lsp.config("*", {
  capabilities = require("blink.cmp").get_lsp_capabilities(),
})
vim.lsp.enable(servers)
