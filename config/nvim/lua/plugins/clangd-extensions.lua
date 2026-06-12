return {
  {
    -- GitHub mirror of https://sr.ht/~chinmay/clangd_extensions.nvim
    -- (owner renamed from p00f)
    "dchinmay2/clangd_extensions.nvim",
    ft = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
    opts = {
      inlay_hints = {
        inline = false, -- Change from default (show at end of line instead of inline)
      },
    },
  },
}
