return {
  settings = {
    gopls = {
      -- gofumpt is deliberately not enabled: saving goes through conform
      -- (go = { "goimports", "gofmt" }), never gopls' formatting, so enabling
      -- it here would only make gopls-originated edits (organizeImports and
      -- friends) gofumpt-styled and mix two styles inside one file
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
