# Claude Code Configuration

This directory contains configuration and helpers for working with Claude Code in the OpenDataHub operator repository.

## Slash Commands

Located in `.claude/commands/`, these provide quick access to common workflows:

- `/test-component` - Run e2e tests for a specific component
- `/add-component` - Guided workflow for adding a new component
- `/review-pr` - Comprehensive PR review checklist
- `/debug-reconcile` - Debug reconciliation issues
- `/build-deploy` - Build and deploy operator to a cluster
- `/fix-linting` - Fix linting issues
- `/analyze-component` - Deep analysis of a component's implementation
- `/update-api` - Update API and regenerate manifests
- `/explain-error` - Get help understanding and fixing errors

## Templates

Located in `.claude/templates/`, these provide structured approaches for common tasks:

- `component-feature.md` - Adding a feature to an existing component
- `bugfix.md` - Fixing bugs with proper testing
- `new-component.md` - Complete checklist for adding a new component

## Usage

### Using Slash Commands

In Claude Code, type `/` followed by the command name:

```
/test-component
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

3. **Add a new feature**:
   ```
   Help me add [feature] using the component-feature template
   ```

4. **Debug issues**:
   ```
   /debug-reconcile
   ```

## Contributing

Before submitting PRs:
- Run `/review-pr` to check your changes
- Ensure all quality gates pass
- Link to Jira issue
- Follow conventional commit format

For more details, see `CONTRIBUTING.md` in the repository root.
