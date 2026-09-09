vim.diagnostic.config({
  virtual_text = {
    source = "if_many",
    prefix = "●",
  },
  float = {
    source = "if_many",
    border = "rounded",
  },
  severity_sort = true,
})

-- No vim.lsp.config("*") call here: blink.cmp already merged its completion
-- capabilities into it at startup, and a later call would clobber them.

local highlight_group = vim.api.nvim_create_augroup("my-lsp-highlight", { clear = true })

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

    if client.name == "clangd" then
      nmap("<leader>ch", "<cmd>ClangdSwitchSourceHeader<cr>", "Switch Source/Header (C/C++)")
    end

    -- bufnr is required, not optional: omitted, supports_method() falls back to
    -- the current buffer, and LspAttach also fires for background ones
    if client:supports_method("textDocument/inlayHint", bufnr) then
      vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
    end

    if client:supports_method("textDocument/documentHighlight", bufnr) then
      -- The callback runs once per attaching client; clear per buffer so a
      -- second capable client does not stack duplicate autocmds
      vim.api.nvim_clear_autocmds({ group = highlight_group, buffer = bufnr })

      vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
        group = highlight_group,
        buffer = bufnr,
        callback = vim.lsp.buf.document_highlight,
        desc = "LSP: highlight references under cursor",
      })

      vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
        group = highlight_group,
        buffer = bufnr,
        callback = vim.lsp.buf.clear_references,
        desc = "LSP: clear reference highlights",
      })
    end
  end,
})

-- Module level, not inside LspAttach: clear = true on every attach would
-- discard the cleanup registered for already-attached buffers
vim.api.nvim_create_autocmd("LspDetach", {
  group = vim.api.nvim_create_augroup("my-lsp-detach", { clear = true }),
  callback = function(args)
    -- Detach also happens on background buffers (:bd, server crash), and
    -- clear_references() always targets the current buffer
    vim.api.nvim_buf_call(args.buf, vim.lsp.buf.clear_references)

    -- The detaching client is still in get_clients() here, so skip it: another
    -- capable client may still need the highlight autocmds
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = args.buf })) do
      if client.id ~= args.data.client_id and client:supports_method("textDocument/documentHighlight", args.buf) then
        return
      end
    end

    vim.api.nvim_clear_autocmds({ group = highlight_group, buffer = args.buf })
  end,
  desc = "LSP: clean up document-highlight autocmds",
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
vim.lsp.enable(servers)
