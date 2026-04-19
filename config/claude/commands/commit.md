# Git Commit

Check the previous commit and the currently staged files, generate a concise commit message in English, and commit.
Do not commit any files other than those currently staged.
Do not push under any circumstances—commit only.

## Git Commit Guidelines

### Format

```
type(scope): message
```

- **type**: The type of change (see below)
- **scope**: The affected module, directory, or file (e.g., auth, api)
- **message**: A concise description of the change (typically in English)

### Type

Commit messages must follow one of the following types:

- **feat**: A new feature
- **fix**: A bug fix
- **refactor**: A code change that neither fixes a bug nor adds a feature
- **test**: Adding missing or correcting existing tests
- **style**: Changes that do not affect the meaning of the code (e.g., white-space, formatting, missing semi-colons)
- **chore**: Changes to the build process or auxiliary tools and libraries such as documentation generation
- **docs**: Documentation only changes