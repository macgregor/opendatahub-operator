#!/usr/bin/env bash
# generate-markdown-report.sh
# Generates human-readable markdown report from consolidated SARIF
# Input: .security-reports/security-audit-consolidated.sarif
# Output: .security-reports/SECURITY-AUDIT-SUMMARY.md

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
SECURITY_DIR="${REPO_ROOT}/.security-reports"
INPUT_FILE="${SECURITY_DIR}/security-audit-consolidated.sarif"
OUTPUT_FILE="${SECURITY_DIR}/SECURITY-AUDIT-SUMMARY.md"

# Verify input file exists
if [[ ! -f "${INPUT_FILE}" ]]; then
    echo "ERROR: Input file not found: ${INPUT_FILE}" >&2
    echo "Run the security audit to generate consolidated SARIF first." >&2
    exit 1
fi

# Verify jq is available
if ! command -v jq &> /dev/null; then
    echo "ERROR: jq is required but not installed" >&2
    exit 1
fi

echo "Generating markdown report from SARIF..." >&2

# Extract metadata
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
TOTAL_FINDINGS=$(jq '[.runs[].results // []] | flatten | length' "${INPUT_FILE}")

# Count by severity
ERROR_COUNT=$(jq '[.runs[].results // [] | .[] | select(.level == "error")] | length' "${INPUT_FILE}")
WARNING_COUNT=$(jq '[.runs[].results // [] | .[] | select(.level == "warning")] | length' "${INPUT_FILE}")
NOTE_COUNT=$(jq '[.runs[].results // [] | .[] | select(.level == "note" or .level == "none")] | length' "${INPUT_FILE}")

# Generate markdown header
cat > "${OUTPUT_FILE}" <<EOF
# Security Audit Summary

**Generated:** ${TIMESTAMP}
**Total Findings:** ${TOTAL_FINDINGS}

## Severity Breakdown

- 🔴 High/Critical (error): ${ERROR_COUNT}
- 🟡 Medium (warning): ${WARNING_COUNT}
- 🔵 Low/Info (note): ${NOTE_COUNT}

## Findings

EOF

# Extract and format each finding
jq -r '
[.runs[].results // []] | flatten | .[] |
"### [\(if .level == "error" then "ERROR" elif .level == "warning" then "WARNING" else "INFO" end)] \(.ruleId // "UNKNOWN")

**Issue:** \(.message.text)

**Location:** `\(.locations[0].physicalLocation.artifactLocation.uri // "unknown"):\(.locations[0].physicalLocation.region.startLine // "?")`

\(if .properties.impact then "**Impact:** \(.properties.impact)

" else "" end)\(if .properties.remediation then "**Remediation:** \(.properties.remediation)

" else "" end)\(if .properties.effort and .properties.priority then "**Effort:** \(.properties.effort) | **Priority:** \(.properties.priority)
" else "" end)
\(if .properties.cwe or .properties.reference then "**Reference:** \(if .properties.cwe then .properties.cwe else "" end)\(if .properties.cwe and .properties.reference then " | " else "" end)\(if .properties.reference then "[Documentation](\(.properties.reference))" else "" end)
" else "" end)
\(if .properties.checkType then "_Check type: \(.properties.checkType)_
" else "" end)
---
"
' "${INPUT_FILE}" >> "${OUTPUT_FILE}"

# Count findings generated
FINDINGS_IN_REPORT=$(grep -c "^### \[" "${OUTPUT_FILE}" || echo 0)

echo "" >&2
echo "Report generated successfully!" >&2
echo "  Total findings: ${TOTAL_FINDINGS}" >&2
echo "  Errors: ${ERROR_COUNT}" >&2
echo "  Warnings: ${WARNING_COUNT}" >&2
echo "  Notes: ${NOTE_COUNT}" >&2
echo "" >&2
echo "Report saved to: ${OUTPUT_FILE}" >&2
