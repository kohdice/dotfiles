return {
  {
    "p00f/clangd_extensions.nvim",
    ft = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
    opts = {
      inlay_hints = {
        inline = false, -- Change from default (show at end of line instead of inline)
      },
    },
    config = function(_, opts)
      require("clangd_extensions").setup(opts)

      -- Integration with nvim-cmp for better completion sorting
      local has_cmp, cmp = pcall(require, "cmp")
      if has_cmp then
        cmp.setup.filetype({ "c", "cpp", "objc", "objcpp", "cuda", "proto" }, {
          sorting = {
            comparators = {
              require("clangd_extensions.cmp_scores"),
              cmp.config.compare.offset,
              cmp.config.compare.exact,
              cmp.config.compare.recently_used,
              cmp.config.compare.kind,
              cmp.config.compare.sort_text,
              cmp.config.compare.length,
              cmp.config.compare.order,
            },
          },
        })
      end
    end,
  },
}
