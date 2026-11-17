# feature

An agent skill that takes a feature from a one-line request to a reviewed, tested pull request. It works in **Claude Code**, **Codex** and **Antigravity**.

You describe the feature. The agent plans it, waits for your approval, builds it on a new branch, writes tests, opens a pull request, has independent reviewers go over the code (security and quality), fixes what they find, pushes, shows you the result, and archives the plan and implementation notes in your project's `docs/` folder.

```
describe feature
      │
      ▼
   1. Plan ──► you approve (or ask for changes)
      │
      ▼
   2. New branch from main ──► implement
      │
      ▼
   3. Write tests ──► run them locally
      │
      ▼
   4. Open a draft pull request
      │
      ▼
   5. Review loop, up to 3 rounds
        ├─ Reviewer A: security
        └─ Reviewer B: bugs, requirements, quality
        (small, non-security changes: one reviewer does both)
        fix findings ──► re-test affected code ──► review the fixes
      │
      ▼
   6. Write docs/ archive ──► final test run ──► push ──► PR ready
      │
      ▼
   7. Demo the result + report
```

## Contents

- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [What you get](#what-you-get)
- [Customization](#customization)
- [Troubleshooting](#troubleshooting)
- [License](#license)

## Requirements

- One of: [Claude Code](https://claude.com/claude-code), Codex, or Antigravity
- `git`
- The [GitHub CLI](https://cli.github.com/) (`gh`), signed in: run `gh auth status` to check, `gh auth login` to sign in
- A project that is a git repository with a GitHub remote

The installer needs `bash` (macOS, Linux, or WSL / Git Bash on Windows).

## Installation

### Quick install

```bash
git clone https://github.com/emhyy/feature-skill.git
```

```bash
cd feature-skill
```

```bash
./install.sh
```

With no arguments, the installer copies the skill into every supported tool it finds on your machine and skips the ones that are not installed:

| Tool | Installed to |
|---|---|
| Claude Code | `~/.claude/skills/feature/` |
| Codex | `~/.codex/skills/feature/` |
| Antigravity | `~/.gemini/skills/feature/` |

To install for specific tools only, name them:

```bash
./install.sh claude
```

```bash
./install.sh codex antigravity
```

Naming a tool installs the skill even if that tool's folder does not exist yet.

Then **start a new session** in the tool. Skills are loaded when a session starts, so sessions that are already open will not see it.

### Manual install

If you would rather not run a script, copy the `feature/` folder yourself. Run these from the root of this repository.

**Claude Code**

```bash
mkdir -p ~/.claude/skills && cp -R feature ~/.claude/skills/feature
```

**Codex**

```bash
mkdir -p ~/.codex/skills && cp -R feature ~/.codex/skills/feature
```

**Antigravity**

```bash
mkdir -p ~/.gemini/skills && cp -R feature ~/.gemini/skills/feature
```

If your Antigravity version reads skills from a different folder, copy `feature/` into that folder instead. The skill is a plain directory with a `SKILL.md` inside, which is the only thing a tool needs to find.

### Install for a single project

To share the skill with everyone working on one repository, copy it into the project instead of your home folder and commit it. For Claude Code that is:

```bash
mkdir -p .claude/skills && cp -R /path/to/feature-skill/feature .claude/skills/feature
```

Codex and Antigravity have their own project-level skill folders; check your tool's documentation for the exact path.

### Verify the installation

Check that the files are in place:

```bash
ls ~/.claude/skills/feature ~/.codex/skills/feature ~/.gemini/skills/feature
```

Each installed location should list `SKILL.md`, `agents` and `references`. Then open a new session and ask the agent "what skills do you have?", or start typing the command (see [Usage](#usage)): `feature` should appear.

### Update

```bash
git pull && ./install.sh
```

The installer replaces the previous copy, so removed or renamed files do not linger. Edit the skill in this repository and reinstall, rather than editing the installed copies, so the three tools stay identical.

### Uninstall

```bash
./install.sh --uninstall
```

Or for one tool only:

```bash
./install.sh --uninstall codex
```

## Usage

### Start it

Open your project in the tool, then:

| Tool | How to invoke |
|---|---|
| Claude Code | `/feature <what you want>` |
| Codex | `$feature <what you want>` |
| Antigravity | Ask in plain language and mention the skill: `Use the feature skill to <what you want>` |

Plain language works everywhere, for example: *"Build this with the full feature workflow: add CSV export to the reports page."*

Write the request in any language. The agent replies in the language you use.

### A full walkthrough

**1. You ask.**

```
/feature Add a "Download CSV" button to the reports page that exports the currently filtered rows
```

**2. The agent checks the project,** then reads the relevant code and replies with a plan. Nothing has been changed yet. The plan covers:

- the goal and acceptance criteria
- the approach and which files will change
- the test plan
- risks, edge cases, and what is out of scope

If your request is unclear, it asks questions first.

**3. You decide.**

- To go ahead, say so: `approved`, `looks good, go ahead`, `LGTM`.
- To change something, say what: `Use a streaming response instead, the tables can be huge`. The agent revises the plan and waits again.

The agent does not write any code until you approve.

**4. The agent works on its own.** After approval it runs without further input:

- updates `main` and creates the branch `feat/<short-name>`
- saves the approved plan to `docs/features/<date>-<short-name>/plan.md`
- implements the feature
- writes tests and runs the full local test suite, plus lint and type checks if the project has them
- commits, pushes, and opens a **draft** pull request
- runs the review loop (see below)
- writes `docs/features/<date>-<short-name>/implementation.md`
- runs the tests one last time, pushes, and marks the pull request ready for review

**5. You see the result.** The agent starts the app and opens the page, or runs the command and shows the real output, so you can check it yourself. It ends with a report: the pull request link, how the feature was built, test results, what the reviewers found and what was fixed, steps to test it manually, and edge cases to keep in mind.

**6. You merge.** The agent never merges the pull request. That stays your decision.

### The review loop

The reviews are written from the point of view of a senior engineer who did not write the code:

| Reviewer | Looks for |
|---|---|
| **A - Security** | injection, missing authorization, exposed secrets, unsafe input handling, risky dependencies, insecure defaults |
| **B - Correctness and quality** | bugs, unhandled edge cases, whether every acceptance criterion in the plan is met, error handling, test coverage, maintainability |

**Round 1 reviews the whole branch diff.** How many reviewers run depends on the change:

- **One reviewer** that applies both checklists, when the change is under about 200 added and removed lines **and** touches nothing security-sensitive (authentication or authorization, outside input, file system, network, shell or database access, secrets, cryptography or sessions, dependencies, security-related configuration).
- **Two reviewers** in every other case, and whenever the agent is unsure.

Findings are rated Critical, High, Medium or Low. The agent checks each finding, fixes every confirmed Critical, High and Medium one, runs the tests that cover the changed code, and starts another round so the fixes get reviewed too.

**Rounds 2 and 3 review only the fixes**, not the whole branch again:

- The reviewer gets the diff since the last reviewed commit plus the previous findings, and may read every file that diff touches in full, so it can catch a fix that clashes with the code around it.
- Only the reviewer that had confirmed findings runs again. If a fix touches security-sensitive code, the security reviewer always runs.

The loop ends when a round finds nothing at Medium or above. It runs **at most 3 rounds**. If problems remain after the third, the agent stops and lists them for you. The full test suite runs again before the final push.

In tools that support sub-agents, each reviewer runs with a fresh context (two reviewers run in parallel), so they see the code without the author's assumptions. Where sub-agents are not available, the agent performs the reviews itself, one after the other, re-reading that round's diff from scratch each time.

These rules keep token use down: reviewers never re-read code that was already reviewed and has not changed, and small changes need only one reviewer.

### When the agent stops and waits for you

| Situation | What it needs from you |
|---|---|
| The plan is ready | Approve it or ask for changes |
| The request is ambiguous | Answer its questions |
| The working tree has uncommitted changes | Say what to do with them; it will not stash or discard them |
| No git repository, no GitHub remote, or `gh` not signed in | Fix the setup, then run it again |
| `git pull` fails or the branch name is taken | Decide how to proceed |
| Three review rounds did not clear every finding | Decide which remaining findings to fix, defer or accept |

### What the agent will not do

- Write code before you approve the plan
- Merge the pull request or force-push
- Push while tests are failing
- Delete, skip or weaken tests to make them pass
- Commit secrets or `.env` files

## What you get

- A branch `feat/<short-name>` and a pull request ready for your review
- Tests covering the feature
- Two archive files committed with the feature:

```
docs/features/2026-01-15-csv-export/
├── plan.md             the plan you approved
└── implementation.md   how it was built
```

`plan.md` records the request, goal, acceptance criteria, approach, files to change, test plan, risks, and what was out of scope.

`implementation.md` records a summary, how the code works, key decisions, files changed, deviations from the plan, a log of every review round (each finding and how it was resolved), test results, manual verification steps, and known limitations.

## Customization

The skill is plain Markdown. Edit the files in `feature/`, then run `./install.sh` again.

| To change | Edit |
|---|---|
| Number of review rounds | `feature/SKILL.md`, Phase 5 |
| When one reviewer is enough (size limit, security-sensitive surface) | `feature/SKILL.md`, Phase 5, Round 1 |
| Branch naming (`feat/<slug>`) | `feature/SKILL.md`, Phase 2 |
| Where the archive is written (`docs/features/...`) | `feature/SKILL.md`, Phases 2 and 6 |
| What the plan must contain | `feature/SKILL.md`, Phase 1 |
| Waiting for CI after pushing | `feature/SKILL.md`, Phase 6 (by default only local tests are run) |
| What the security reviewer checks | `feature/references/reviewer-security.md` |
| What the quality reviewer checks | `feature/references/reviewer-quality.md` |
| The layout of `plan.md` and `implementation.md` | `feature/references/docs-templates.md` |
| The name and description shown in Codex | `feature/agents/openai.yaml` |

Repository layout:

```
feature-skill/
├── feature/
│   ├── SKILL.md                   the workflow
│   ├── agents/openai.yaml         display metadata for Codex
│   └── references/
│       ├── reviewer-security.md   instructions for Reviewer A
│       ├── reviewer-quality.md    instructions for Reviewer B
│       └── docs-templates.md      templates for the archive files
├── install.sh
├── LICENSE
└── README.md
```

## Troubleshooting

**The skill does not show up.** Start a new session; skills load at session start. Check that `SKILL.md` sits directly inside the `feature/` folder in the tool's skills directory (see [Verify the installation](#verify-the-installation)).

**The agent started coding without showing a plan.** The skill was probably not loaded. Invoke it by name (`/feature`, `$feature`, or "use the feature skill").

**My default branch is not `main`.** Nothing to do. The skill asks GitHub for the repository's default branch and uses that.

**My project has no tests.** The agent proposes a test setup as part of the plan, so you can approve or change it before any code is written.

**`gh` is not signed in.** Run `gh auth login`, then invoke the skill again.

**It stopped because of uncommitted changes.** Commit or stash them yourself, or tell the agent what to do with them.

**My tool has no sub-agents.** The skill still works: the agent runs the reviews itself, one after the other. They are less independent than reviews by separate sub-agents, so read the pull request with a little more care.

**I want CI to pass too.** By default the skill only runs tests locally. See [Customization](#customization) to add a CI wait.

**`./install.sh: Permission denied`.** Run `bash install.sh`, or `chmod +x install.sh` first.

## License

[MIT](LICENSE)
