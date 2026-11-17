---
name: feature
description: Deliver a feature end to end - plan, wait for the user's approval, implement on a new branch cut from the default branch, write tests, open a pull request, run two independent senior-engineer reviews (security and quality), fix and re-review, push, demo the result, and archive the plan and implementation notes under docs/. Use when the user invokes /feature or $feature, or asks to build a feature with the full plan-to-PR workflow. Do not use for quick edits, questions, or one-line fixes.
---

# Feature

Take the feature the user described from idea to a reviewed, tested pull request.

Work through the phases in order. Do not skip a phase or reorder them. Talk to the user in the language they used; write code, commit messages and PR text in the language the project already uses.

This skill relies only on `git` and the GitHub CLI (`gh`). Wherever it says "sub-agent", "show" or "open", use whatever your environment provides for that.

## Phase 0 - Preflight

Check these before anything else. If one fails, stop and tell the user what is missing; do not work around it.

1. The current directory is inside a git repository with a GitHub remote, and `gh auth status` succeeds.
2. The working tree is clean (`git status --porcelain` prints nothing). If it is not, ask the user what to do with the changes. Never stash, discard or commit them on your own.
3. Find the default branch: use `main` if it exists, otherwise `gh repo view --json defaultBranchRef --jq .defaultBranchRef.name`. It is called `<default>` below.
4. If the feature request is ambiguous, ask clarifying questions now, before planning.

## Phase 1 - Plan, then stop

Do not create, edit or delete any file in this phase.

1. Read the relevant code: how the project is structured, its conventions, how it is tested, and what already exists that the feature can reuse.
2. Present a plan containing:
   - **Goal** and **acceptance criteria** (observable, checkable statements)
   - **Approach** and the files to add or change
   - **Test plan** (which cases, in which test files; if the project has no test setup, propose one)
   - **Risks and edge cases**
   - **Out of scope**
3. **Stop and wait.** End your turn after presenting the plan. Continue only after the user explicitly approves it. If they ask for changes, revise the plan and wait again. Silence, or a reply about something else, is not approval.

## Phase 2 - Branch and implement

1. Create the branch from an up-to-date default branch:
   ```bash
   git switch <default>
   git pull --ff-only
   git switch -c feat/<slug>
   ```
   `<slug>` is a short kebab-case name for the feature. If the pull fails or the branch already exists, stop and ask.
2. Save the approved plan as `docs/features/<YYYY-MM-DD>-<slug>/plan.md` using the template in `references/docs-templates.md`.
3. Implement the plan. Follow the project's existing style and patterns. Keep the change limited to the feature. When you have to deviate from the plan, note what changed and why; it goes into the implementation notes later.

## Phase 3 - Tests

1. Write tests with the project's existing test framework. Cover every acceptance criterion and the edge cases from the plan, including failure paths.
2. Run the full local test suite, plus the project's lint and type checks if it has them.
3. Do not continue until everything passes. Fix the code, not the tests, unless a test is wrong. Never delete, skip or weaken a test to get a green run.

## Phase 4 - Open the pull request

1. Commit the work in logical commits with clear messages.
2. Push the branch and open a draft pull request:
   ```bash
   git push -u origin feat/<slug>
   gh pr create --draft --base <default> --title "<title>" --body "<body>"
   ```
   The body states what the feature does, how it is implemented, and how it was tested.

## Phase 5 - Review loop (at most 3 rounds)

Each round runs two independent reviews of `git diff <default>...HEAD`:

- **Reviewer A - security**: use `references/reviewer-security.md`
- **Reviewer B - correctness and quality**: use `references/reviewer-quality.md`

How to run them:

- If your environment supports sub-agents, start both at the same time, each with a fresh context. Give each one its reference file as instructions, the path to `plan.md`, the diff command, and (from round 2 on) the findings of the previous round. Reviewers only read; they never edit files.
- If it does not, perform the two reviews yourself, one after the other. For each, re-read the whole diff from scratch and follow the reference file strictly. Do not rely on what you remember from writing the code.

After both reviews return:

1. Verify every finding against the code. If a finding is wrong, record why; do not silently drop it.
2. Fix every confirmed Critical, High and Medium finding. Fix Low findings when the fix is cheap and safe; otherwise record them.
3. Add or update tests for what you fixed, rerun the full local test suite, and commit.
4. Run the next round so the fixes themselves get reviewed.

Stop the loop when a round ends with no confirmed Critical, High or Medium finding from either reviewer. If round 3 still leaves such findings, stop the whole workflow, list what remains, and let the user decide. Do not start a fourth round on your own.

## Phase 6 - Archive and final push

1. Write `docs/features/<YYYY-MM-DD>-<slug>/implementation.md` using the template in `references/docs-templates.md`: how the feature works, key decisions, files changed, deviations from the plan, the findings of each review round and how each was handled, test results, and manual verification steps.
2. Run the full local test suite one last time. If anything fails, fix it and rerun. Never push with failing tests.
3. Commit, push, and mark the pull request ready:
   ```bash
   git push
   gh pr ready
   ```
4. Do not merge the pull request and do not force-push. Merging is the user's decision.

## Phase 7 - Show the result

1. Make the result visible so the user can check it with their own eyes. For something with a UI, start the app and open the relevant page, or capture screenshots. For a CLI, library or backend, run it and show the real output. If you cannot run it in your environment, give the exact commands and the address to open.
2. Finish with a report:
   - Link to the pull request
   - How the feature was implemented, in plain language
   - Test results (what was run, and the outcome)
   - Review summary: number of rounds, what was found, what was fixed, anything left open
   - Steps for the user to test it manually
   - Edge cases worth keeping in mind
   - Paths to `plan.md` and `implementation.md`

## Rules that always apply

- Report honestly. If a test fails, a step was skipped, or something could not be verified, say so.
- Never commit secrets, credentials or `.env` files.
- Stop and ask whenever a step would destroy work, rewrite history, or go beyond the approved plan.
