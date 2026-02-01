# Formatted PR Review

Execute a comprehensive pull request review using a git worktree and present findings as sorted, actionable insights to assist with your GitHub PR review.

## Arguments

The first argument should be the branch name to review (required).

## Workflow

1. **Setup Worktree**:
   - Check if the branch exists locally using `git branch --list <branch-name>`
   - If not found, fetch it with `git fetch origin <branch-name>:<branch-name>`
   - Determine worktree path: Use the parent directory of the current repo with `-pr-review` suffix
     Example: If in `/Users/jules/Documents/Code/guardian-backend`, use `/Users/jules/Documents/Code/guardian-backend-pr-review`
   - Create worktree: `git worktree add <worktree-path> <branch-name>`
   - Change to the worktree directory using `cd <worktree-path>`

2. **Execute Review**:
   - Before you start executing, verify what branch this PR is based on. Do not simply assumed it based off of main. Use git commands, etc. to decide what to base yourself against before reviewing everything.
   - Execute the pr-review-toolkit review from within the worktree, passing through any additional provided arguments
   - Once all specialized agents have completed their analysis, extract all findings from code **added in this PR only** (unless an issue is absolutely critical). Organize findings by filename (alphabetical), then by line number within each file (ascending). Present insights concisely with clear formatting to help you efficiently review the PR.

3. **Cleanup Prompt**:
   - After presenting the review, ask the user: "Would you like to delete the worktree at `<worktree-path>`? (yes/no)"
   - If yes: Run `cd` back to original directory, then `git worktree remove <worktree-path>` and confirm deletion
   - If no: Keep the worktree and stay in that directory for further questions
   - **IMPORTANT**: If the user says no, you MUST ask this same question at the end of EVERY subsequent response in this session until they say yes
   - Track this state throughout the conversation - once they decline, keep asking on every response

## Output Format
Start by explaining what this PR does, its key changes, what it adds, removes, etc. in a suscint manner.
This should be one to three paragraphs, and give the reviewer enough context and insight to follow the findings and issues you generated.

Then, sort findings by:
1. **Filename** (alphabetical order, as they appear in GitHub)
2. **Line number** (ascending within each file)

For each finding, use this format:

```
### path/to/file.py

**Line X-Y** | 🔴 **CRITICAL** | Error Handling
Brief issue description. Include code snippet only if it clarifies the problem.


**Line A-B** | 🟡 **IMPORTANT** | Test Coverage
Brief issue description.


**Line C** | 🔵 **SUGGESTION** | Code Quality
Brief issue description.


### path/to/another_file.py

...
```

## Priority Colors

- 🔴 **CRITICAL** - Must fix before merge
- 🟡 **IMPORTANT** - Should fix
- 🔵 **SUGGESTION** - Nice to have

## Issue Types

- Code Quality
- Test Coverage
- Error Handling
- Documentation
- Performance
- Security

## Notes

- Focus exclusively on code added in this PR
- Look at what the PR is based on instead of assuming it is agaisnt main/master. If there's a staging branch, there's a good chance it's against that.
- Only flag existing code if it's an absolutely critical issue
- Include code snippets sparingly, only when they help explain the issue
- Keep descriptions concise and actionable
- Leave blank lines between issues for readability
