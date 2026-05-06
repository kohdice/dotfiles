# Git Commit

Check the previous commit and the currently modified files, generate a concise commit message in English, and commit.
Do not commit all files at once.
Instead, split the commits into meaningful units (for example: by feature, by bug fix, or by related changes).
Commit each unit step by step in the correct logical order, so that the commit history remains clear and consistent.
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
- **ci**: Changes to CI configuration files and scripts
- **perf**: A code change that improves performance
