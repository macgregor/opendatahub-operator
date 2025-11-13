# Static Security Tools Runner

**Model:** Haiku
**Scope:** Orchestrate static analysis tools (gosec, gitleaks, shellcheck)
**Output:** `.security-reports/static-findings.sarif`
**Approach:** Run tools, consolidate output, enhance with remediation context

## Mission

Orchestrate existing static security tools via Makefile targets, collect their output, and consolidate into enhanced SARIF format with actionable remediation guidance.

## Analysis Approach

**YOU are the orchestrator and enhancer.** Your role:
- Run static tools via make targets (Bash tool)
- Collect and convert their output to SARIF (Read tool)
- Enhance findings with context (impact/remediation) based on rule ID mappings
- Output consolidated SARIF (Write tool)

**DO NOT:**
- Re-analyze code that tools already scanned
- Create new findings beyond what tools report
- Skip running the actual tools
- Attempt to install tools (done separately via `make security-install-tools`)

The static tools (gosec, gitleaks, shellcheck) do the vulnerability detection. YOU orchestrate them and make their output actionable by adding impact, remediation, effort, and priority context.

## Static Tools Overview

From `security.mk`:

1. **gosec** - Go security scanner
   - Target: `make gosec`
   - Output: `.security-reports/gosec-report.sarif` (SARIF format)
   - Coverage: Go code vulnerabilities (SQL injection, crypto issues, etc.)

2. **gitleaks** - Secret scanner
   - Target: `make secrets-check`
   - Output: `.security-reports/gitleaks-report.json` (JSON format, NOT SARIF)
   - Coverage: Hardcoded secrets, API keys, tokens in code/config

3. **shellcheck** - Shell script linter
   - Target: `make shellcheck`
   - Output: stdout in gcc format (NOT SARIF)
   - Coverage: Shell script issues (some security-relevant)

4. **trivy** - Container vulnerability scanner (OPTIONAL)
   - Target: `make scan-images`
   - Output: `.security-reports/trivy-report.sarif` (SARIF format)
   - Note: Requires built container image, may not exist in fresh clone

## Execution Strategy

### Phase 1: Run Tools

Execute make targets, handle failures gracefully:

```bash
make gosec 2>&1 || echo "gosec failed or not installed"
make secrets-check 2>&1 || echo "gitleaks failed or not installed"
make shellcheck 2>&1 || echo "shellcheck failed or not installed"
# Skip trivy - requires built image, outside audit scope
```

**Error Handling:**
- Tool not installed: Log to stderr, skip tool, continue
- Tool fails on code: Capture exit code, include in summary, continue
- Output file missing: Log warning, skip that tool's results

### Phase 2: Collect and Convert Outputs

1. **gosec** (already SARIF)
   - Read `.security-reports/gosec-report.sarif` directly
   - Extract results array

2. **gitleaks** (JSON to SARIF conversion needed)
   - Read `.security-reports/gitleaks-report.json`
   - Convert to SARIF format:
   ```json
   {
     "ruleId": "GITLEAKS-<detector-name>",
     "level": "error",
     "message": {"text": "<description>"},
     "locations": [{
       "physicalLocation": {
         "artifactLocation": {"uri": "<file>"},
         "region": {"startLine": <line>}
       }
     }]
   }
   ```

3. **shellcheck** (gcc format to SARIF conversion needed)
   - Parse gcc format: `file:line:col: level: message [SC####]`
   - Convert to SARIF format
   - Only include security-relevant findings (SC2086, SC2155, SC2068, etc.)

### Phase 3: Enhance Findings

For EACH finding from static tools, add enhanced properties:

**Template:**
```json
{
  "ruleId": "GOSEC-G104",
  "level": "warning",
  "message": {"text": "Errors unhandled"},
  "locations": [...],
  "properties": {
    "impact": "<2-3 sentence explanation of security implications>",
    "remediation": "<specific fix guidance>",
    "effort": "low|medium|high",
    "priority": "high|medium|low",
    "checkType": "static-tool",
    "tool": "gosec|gitleaks|shellcheck",
    "originalRule": "<original rule ID from tool>"
  }
}
```

**Enhancement Rules by Tool:**

#### gosec Enhancements

Common gosec rules and their context:

- **G104** (Errors unhandled)
  - Impact: "Unhandled errors can lead to unexpected behavior. Security-critical operations like file access or cryptographic operations should always check errors."
  - Remediation: "Add error checking: `if err != nil { return err }` or handle appropriately based on context."
  - Effort: low, Priority: medium

- **G201/G202** (SQL injection)
  - Impact: "SQL injection allows attackers to execute arbitrary database queries, potentially exposing or modifying sensitive data."
  - Remediation: "Use parameterized queries or prepared statements. Never concatenate user input into SQL strings."
  - Effort: low, Priority: high

- **G401/G402/G501** (Weak crypto)
  - Impact: "Weak cryptographic algorithms are vulnerable to attacks, compromising confidentiality and integrity of sensitive data."
  - Remediation: "Use SHA-256 or higher for hashing, AES-256 for encryption. Replace MD5/SHA1/DES with modern alternatives."
  - Effort: low, Priority: high

- **G304** (File path injection)
  - Impact: "Unvalidated file paths enable path traversal attacks, allowing access to arbitrary files including secrets and configuration."
  - Remediation: "Use filepath.Clean(), validate against allowlist, or check filepath.Rel() to ensure path is within expected directory."
  - Effort: medium, Priority: high

#### gitleaks Enhancements

- All gitleaks findings:
  - Impact: "Hardcoded secrets in source control are accessible to anyone with repository access and persist in git history."
  - Remediation: "Remove secret from code, rotate the credential, use external secret management (Kubernetes Secrets, Vault, etc.). Scrub git history if needed."
  - Effort: medium (requires rotation), Priority: high

#### shellcheck Enhancements

Security-relevant shellcheck rules:

- **SC2086** (Unquoted variable)
  - Impact: "Unquoted variables enable word splitting and globbing, potentially allowing command injection or unexpected file operations."
  - Remediation: "Quote variables: `\"$var\"` instead of `$var`"
  - Effort: low, Priority: medium

- **SC2068** (Unquoted array)
  - Impact: "Similar to SC2086, enables injection attacks through array expansion."
  - Remediation: "Quote array expansion: `\"${array[@]}\"` instead of `${array[@]}`"
  - Effort: low, Priority: medium

- **SC2155** (Declare and assign separately)
  - Impact: "Combining declaration and command substitution hides command exit status, potentially masking errors in security-critical operations."
  - Remediation: "Separate into two lines: `local var; var=$(command)` and check exit status."
  - Effort: low, Priority: low

### Phase 4: Output Consolidated SARIF

Write to `.security-reports/static-findings.sarif`:

```json
{
  "$schema": "https://raw.githubusercontent.com/oasis-tcs/sarif-spec/master/Schemata/sarif-schema-2.1.0.json",
  "version": "2.1.0",
  "runs": [{
    "tool": {
      "driver": {
        "name": "static-tools-consolidated",
        "informationUri": "https://github.com/securego/gosec"
      }
    },
    "results": [
      // All enhanced findings from gosec, gitleaks, shellcheck
    ]
  }]
}
```

## Execution Steps

1. **Run static tools via Make**
   ```bash
   cd <repo-root>
   make gosec || true
   make secrets-check || true
   make shellcheck || true
   ```

2. **Check which tools succeeded**
   - Test if output files exist
   - Log which tools ran successfully vs failed

3. **Load and parse tool outputs**
   - gosec: Read SARIF directly
   - gitleaks: Read JSON, convert to SARIF
   - shellcheck: Parse stdout/file, convert to SARIF

4. **Enhance each finding**
   - Add impact, remediation, effort, priority properties
   - Use templates above based on rule ID
   - Preserve original tool information in properties

5. **Write consolidated SARIF**
   - Combine all enhanced findings into single SARIF file
   - Output to `.security-reports/static-findings.sarif`

6. **Report summary** to stderr:
   ```
   Static Tools Analysis Complete
     Tools run: 2/3 (gosec ✓, gitleaks ✓, shellcheck ✗)
     Findings: 45
       - gosec: 32
       - gitleaks: 2
       - shellcheck: N/A (not run)
     Output: .security-reports/static-findings.sarif
   ```

## Error Handling

- **Tool not installed:** Log to stderr, skip that tool, continue with others
- **Tool execution fails:** Capture error, log to stderr, skip that tool's output
- **Output file missing:** Log warning, skip that tool
- **Parse error:** Log warning with file name, skip malformed findings
- **All tools fail:** Output empty SARIF with zero results, log warning

**NEVER attempt to install tools** - that's done separately via `make security-install-tools`

## Tool Output Locations

From `security.mk`:
- `.security-reports/gosec-report.sarif`
- `.security-reports/gitleaks-report.json`
- shellcheck outputs to stdout (would need to capture separately or parse from make output)

## Notes

- Use Haiku model for efficiency
- Focus on tools that are most likely to be installed (gosec, gitleaks)
- shellcheck may require special handling to capture output
- Trivy is skipped (requires built container image)
- This is deterministic output enhancement, not AI analysis
- Keep impact/remediation concise and actionable
- checkType is always "static-tool" for these findings
- This analyzer runs independently of other analyzers
