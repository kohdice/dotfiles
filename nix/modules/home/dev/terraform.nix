{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # CLI
    terraform

    # LSP
    terraform-ls

    # Linter
    tflint
  ];
}
