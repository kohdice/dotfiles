return {
  settings = {
    redhat = {
      telemetry = {
        enabled = false,
      },
    },
    yaml = {
      format = {
        enable = false,
      },
    },
  },

  -- nvim-lspconfig's lsp/yamlls.lua forces documentFormattingProvider = true in
  -- its own on_init so that capability checks see a formatter. With formatting
  -- disabled above, that lie makes conform's lsp_format = "fallback" hand yaml
  -- to yamlls (when yamlfmt is missing) and get back silence instead of an error
  on_init = function() end,
}
