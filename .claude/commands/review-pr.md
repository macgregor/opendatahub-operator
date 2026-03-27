---
description: Review a pull request for quality and completeness
---

Perform a comprehensive PR review for the OpenDataHub operator.

Review checklist:

1. **Jira Issue**: Check if PR description links to a Jira issue (required for non-chore changes)

2. **Commit Messages**: Verify conventional commit format: `<type>(<scope>): <summary>`
   - Valid types: fix, feat, docs, chore, refactor, test, ci

3. **Code Quality**:
   - Run `make lint` to check for linting issues
   - Check for proper error handling (no ignored errors with `_`)
   - Verify comments for exported functions
   - Check `go.mod` and `go.sum` are up to date

4. **API Changes**:
   - If API changes detected, verify `make api-docs` was run
   - Check that `docs/api-overview.md` is updated
   - Verify CRD changes in `config/crd/bases/`

5. **Tests**:
   - Check that new code has unit tests
   - For new features, verify e2e tests exist
   - Run `make unit-test` to ensure tests pass
   - Check test coverage hasn't decreased

6. **Manifests**:
   - If controller changes, check `make manifests` was run
   - Verify RBAC permissions are correct

7. **Documentation**:
   - Check if README or other docs need updates
   - Verify testing steps are provided in PR description

8. **Downstream Sync**:
   - Remind that changes need to be synced to `rhoai` branch after merge

Provide a summary of findings with specific file/line references for issues.
