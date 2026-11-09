return {
  settings = {
    gopls = {
      -- No gofumpt: saving goes through conform (goimports, gofmt), so it would
      -- only restyle gopls-originated edits and mix two styles in one file
      codelenses = {
        test = true,
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
        shadow = true,
      },
      usePlaceholders = true,
      staticcheck = true,
      directoryFilters = { "-.git", "-.vscode", "-.idea", "-.vscode-test", "-node_modules" },
    },
  },
}
