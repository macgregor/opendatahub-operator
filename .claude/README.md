# Claude Code Configuration

This directory contains configuration and helpers for working with Claude Code in the OpenDataHub operator repository.

## Slash Commands

Located in `.claude/commands/`, these provide quick access to common workflows:

- `/review-pr` - Comprehensive PR review checklist

## Agent Skills

Located in `.claude/skills/`, these provide tools for agents to use when working with the code base:

- `generate-unit-tests` - 

If for some reason Claude doesnt automatically use your skill for a tasks, try interrupting the task and prompting it with "What Skills are available?" and it usually connects the dots.

see: https://anthropic.mintlify.app/en/docs/claude-code/skills

## Templates

Located in `.claude/templates/`, these provide structured approaches for common tasks:

- none currently

## Usage

### Using Slash Commands

In Claude Code, type `/` followed by the command name:

```
/review-pr
```

Claude will guide you through the workflow interactively.

### Using Templates

Reference templates when working on specific task types:

```
Use the component-feature template to help me add [feature] to [component]
```

## Project Overview

The OpenDataHub operator is a Kubernetes operator managing data science components. Key concepts:

- **DSCInitialization**: Cluster-wide initialization (must be created first)
- **DataScienceCluster**: Component management (only one per cluster)
- **Components**: Modular data science tools (dashboard, workbenches, kserve, etc.)

For detailed information, see `CLAUDE.md` in the repository root.

## Quick Start

1. **Build and test locally**:
   ```bash
   make build
   make unit-test
   ```

2. **Deploy to cluster**:
   ```
   /build-deploy
   ```

## Contributing

Before submitting PRs:
- Run `/review-pr` to check your changes
- Ensure all quality gates pass
- Link to Jira issue
- Follow conventional commit format

For more details, see `CONTRIBUTING.md` in the repository root.
