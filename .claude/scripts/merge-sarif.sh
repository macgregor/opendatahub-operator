#!/bin/bash
# Merge multiple SARIF files into a single consolidated SARIF file

set -e

SECURITY_REPORTS_DIR="${1:-.security-reports}"
OUTPUT_FILE="${2:-$SECURITY_REPORTS_DIR/security-audit-consolidated.sarif}"

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed"
    exit 1
fi

# Find all *-findings.sarif files
SARIF_FILES=$(find "$SECURITY_REPORTS_DIR" -name "*-findings.sarif" -type f 2>/dev/null || true)

if [ -z "$SARIF_FILES" ]; then
    echo "No SARIF findings files found in $SECURITY_REPORTS_DIR"
    exit 1
fi

echo "Merging SARIF files..."
echo "$SARIF_FILES" | while read -r file; do
    echo "  - $(basename "$file")"
done

# Merge all SARIF files using jq
# This combines all results arrays from all runs in all files
jq -s '
{
  "$schema": "https://raw.githubusercontent.com/oasis-tcs/sarif-spec/master/Schemata/sarif-schema-2.1.0.json",
  "version": "2.1.0",
  "runs": [
    {
      "tool": {
        "driver": {
          "name": "security-audit-consolidated",
          "version": "1.0.0",
          "informationUri": "https://github.com/opendatahub-io/opendatahub-operator"
        }
      },
      "results": ([.[].runs[].results] | flatten)
    }
  ]
}
' $SARIF_FILES > "$OUTPUT_FILE"

RESULT_COUNT=$(jq '.runs[0].results | length' "$OUTPUT_FILE")

echo "✓ Merged SARIF file created: $OUTPUT_FILE"
echo "✓ Total findings: $RESULT_COUNT"
