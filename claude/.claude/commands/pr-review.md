# PR Review Command

## Description
Perform systematic code review on GitHub Pull Requests with structured analysis.

## Usage
```
/pr-review [PR_NUMBER]
```
- Without arguments: Lists open PRs and prompts for selection
- With PR number: Reviews specified PR directly

## Command Flow

### Step 1: PR Selection
```bash
# Check arguments
if [no arguments]; then
  # Get open PR list
  Bash("gh pr list --limit 10")
  # Prompt user for PR number
  prompt: "Enter PR number to review: "
else
  # Use specified PR number
  pr_number = args[0]
fi
```

### Step 2: PR Information Gathering
Execute in parallel:
```bash
# Get PR details
Bash("gh pr view ${pr_number}")

# Get PR diff
Bash("gh pr diff ${pr_number}")

# Get branch information
Bash("gh pr view ${pr_number} --json headRefName,baseRefName")
```

If a Notion link is included in the description or comments, use notion-mcp to review the page before conducting your code review.

### Step 3: Code Analysis
Analyze changes from multiple perspectives:

#### 3.1 Structural Analysis
- File classification (domain/infrastructure/application/presentation)
- Impact scope identification
- Dependency verification

#### 3.2 Quality Checks
- **Code Correctness**: Logic errors, boundary conditions, error handling
- **Project Conventions**: Naming conventions, architecture patterns, coding style
- **Performance**: N+1 queries, unnecessary loops, memory leaks
- **Test Coverage**: Unit tests, integration tests, edge cases
- **Security**: Input validation, authentication/authorization, sensitive data handling

### Step 4: Review Generation
Generate review following this template:
After generating the review, use textlint-mcp to check it.

## Review Template

```markdown
# PR #${pr_number} Review

## Summary
[Brief description of what the PR accomplishes]

## Change Analysis

### Architecture Impact
- [Affected layers and reasons]

### Key Changes
1. [Important change 1]
2. [Important change 2]
...

## Good Points
- [Well-implemented code and improvements]

## Issues & Suggestions

### must (Required)
- [Critical/security issues]
- [Bugs or potential problems]

### nits (Recommended)
- [Code quality improvements]
- [Maintainability suggestions]

### imo (Opinion)
- [Alternative implementations]
- [Future improvement ideas]

## Quality Metrics
- Code Correctness: 4/5
- Convention Compliance: 5/5
- Performance: 3/5
- Test Coverage: 4/5
- Security: 5/5

## Overall Assessment
- [APPROVE/REQUEST CHANGES/COMMENT]

### Reasoning
[Justification for the assessment]

## Additional Suggestions
[Optional: Future improvements or related technical debt]
```

## Error Handling

### Common Errors
- PR not found
  ```
  Error: PR #${pr_number} not found.
  Use 'gh pr list' to see available PRs.
  ```

- GitHub CLI authentication error
  ```
  Error: GitHub CLI authentication required.
  Please run 'gh auth login'.
  ```

- Network error
  ```
  Error: Failed to connect to GitHub.
  Please check your network connection.
  ```

## Configuration Options

### Review Detail Level
- `--brief`: Concise review (major issues only)
- `--detailed`: Detailed review (default)
- `--exhaustive`: Thorough review (includes performance analysis)

### Focus Areas
- `--security`: Focus on security concerns
- `--performance`: Focus on performance implications
- `--testing`: Focus on test coverage

## Implementation Notes

1. **Parallel Processing**: Execute Bash commands in parallel whenever possible
2. **Context Preservation**: Reuse PR information throughout analysis
3. **Progressive Analysis**: Start with lightweight checks, then detailed analysis
4. **Review Tags**: Use must/nits/imo for clear prioritization
5. **Structured Output**: Maintain consistent formatting for readability
6. **Japanese Output**: Prioritize user comprehension