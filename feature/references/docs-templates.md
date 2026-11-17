# Archive templates

Both files live in `docs/features/<YYYY-MM-DD>-<slug>/`, where the date is the day the plan was approved. Write them in the language the project's existing docs use; if there are none, use the user's language. Leave out a section only when it truly does not apply.

## plan.md

```markdown
# <Feature name> - Plan

- Date approved: <YYYY-MM-DD>
- Branch: feat/<slug>

## Request
<The user's request, in their own words.>

## Goal
<What will be true when this is done.>

## Acceptance criteria
- [ ] <Observable, checkable statement>

## Approach
<How it will be built, and why this way.>

## Files to change
- `<path>` - <what changes>

## Test plan
- <Case> - `<test file>`

## Risks and edge cases
- <Risk or edge case, and how it is handled>

## Out of scope
- <What this deliberately does not do>
```

## implementation.md

```markdown
# <Feature name> - Implementation

- Pull request: <URL>
- Branch: feat/<slug>
- Completed: <YYYY-MM-DD>

## Summary
<What was built, in two or three sentences.>

## How it works
<Walk through the implementation: the main pieces, how data flows between them, and where to start reading the code.>

## Key decisions
- <Decision> - <why, and what was considered instead>

## Files changed
- `<path>` - <what changed>

## Deviations from the plan
- <What differs from plan.md, and why. "None" if nothing.>

## Review log
### Round 1
| Reviewer | Severity | Finding | Resolution |
|---|---|---|---|
| Security | High | <finding> | Fixed in <commit> / Rejected: <reason> / Deferred: <reason> |

### Round 2
<Same table. Add one section per round.>

## Tests
- Command: `<how the tests were run>`
- Result: <passed / failed counts>
- Added: <test files and what they cover>

## Manual verification
1. <Step the user can follow to see the feature working>

## Known limitations and follow-ups
- <Anything left open, including Low findings that were not fixed>
```
