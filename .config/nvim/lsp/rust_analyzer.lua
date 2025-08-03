-- Rust言語サーバーの設定
return {
  settings = {
    ["rust-analyzer"] = {
      ["checkOnSave.command"] = "clippy",
    },
  },
}
