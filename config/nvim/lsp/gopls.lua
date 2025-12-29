return {
  settings = {
    gopls = {
      gofumpt = true,
      codelenses = {
        gc_details = false,
        test = true,
        run_govulncheck = true,
      },
      hints = {
        assignVariableTypes = true,
        compositeLiteralFields = true,
        compositeLiteralTypes = true,
        constantValues = true,
        functionTypeParameters = true,
        parameterNames = true,
        rangeVariableTypes = true,
      },
      analyses = {
        unusedparams = true,
        shadow = true,
      },
      usePlaceholders = true,
      staticcheck = true,
      directoryFilters = { "-.git", "-.vscode", "-.idea", "-.vscode-test", "-node_modules" },
    },
  },
}
