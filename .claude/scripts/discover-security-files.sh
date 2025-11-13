#!/usr/bin/env bash
# discover-security-files.sh
# Categorizes files by security domain for AI analysis
# Output: .security-reports/file-manifest.json

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
OUTPUT_DIR="${REPO_ROOT}/.security-reports"
OUTPUT_FILE="${OUTPUT_DIR}/file-manifest.json"

# Create output directory
mkdir -p "${OUTPUT_DIR}"

# Change to repo root for relative paths
cd "${REPO_ROOT}"

# Initialize JSON structure
cat > "${OUTPUT_FILE}" <<'EOF'
{
  "k8s_manifests": {
    "rbac": [],
    "network": [],
    "secrets": [],
    "crds": []
  },
  "go_code": {
    "controllers": [],
    "api": [],
    "webhooks": [],
    "pkg": []
  },
  "scripts": []
}
EOF

# Helper function to add file to JSON array
add_to_category() {
    local category=$1
    local filepath=$2

    # Use jq to append to the appropriate array
    local jq_path
    case "${category}" in
        rbac)       jq_path='.k8s_manifests.rbac' ;;
        network)    jq_path='.k8s_manifests.network' ;;
        secrets)    jq_path='.k8s_manifests.secrets' ;;
        crds)       jq_path='.k8s_manifests.crds' ;;
        controllers) jq_path='.go_code.controllers' ;;
        api)        jq_path='.go_code.api' ;;
        webhooks)   jq_path='.go_code.webhooks' ;;
        pkg)        jq_path='.go_code.pkg' ;;
        scripts)    jq_path='.scripts' ;;
        *)
            echo "WARN: Unknown category '${category}' for file: ${filepath}" >&2
            return 0
            ;;
    esac

    # Add file to the appropriate array
    jq "${jq_path} += [\"${filepath}\"]" "${OUTPUT_FILE}" > "${OUTPUT_FILE}.tmp"
    mv "${OUTPUT_FILE}.tmp" "${OUTPUT_FILE}"
}

echo "Discovering security-relevant files..." >&2

# K8s Manifests - RBAC
echo "  Finding RBAC manifests..." >&2
while IFS= read -r file; do
    add_to_category "rbac" "${file}"
done < <(find config/rbac -type f \( -name "*.yaml" -o -name "*.yml" \) 2>/dev/null || true)

# K8s Manifests - Network Policies
echo "  Finding network policies..." >&2
while IFS= read -r file; do
    add_to_category "network" "${file}"
done < <(find config -type f \( -name "*.yaml" -o -name "*.yml" \) | grep -i networkpolicy || true)

# K8s Manifests - Secrets
echo "  Finding secret manifests..." >&2
while IFS= read -r file; do
    add_to_category "secrets" "${file}"
done < <(find config -type f \( -name "*.yaml" -o -name "*.yml" \) | grep -i secret || true)

# K8s Manifests - CRDs
echo "  Finding CRDs..." >&2
while IFS= read -r file; do
    add_to_category "crds" "${file}"
done < <(find config/crd/bases -type f \( -name "*.yaml" -o -name "*.yml" \) 2>/dev/null || true)

# Go Code - Controllers
echo "  Finding controller code..." >&2
while IFS= read -r file; do
    add_to_category "controllers" "${file}"
done < <(find internal/controller -type f -name "*.go" 2>/dev/null || true)

# Go Code - API
echo "  Finding API code..." >&2
while IFS= read -r file; do
    add_to_category "api" "${file}"
done < <(find api -type f -name "*.go" 2>/dev/null || true)

# Go Code - Webhooks
echo "  Finding webhook code..." >&2
while IFS= read -r file; do
    add_to_category "webhooks" "${file}"
done < <(find internal/webhook -type f -name "*.go" 2>/dev/null || true)

# Go Code - Pkg
echo "  Finding pkg code..." >&2
while IFS= read -r file; do
    add_to_category "pkg" "${file}"
done < <(find pkg -type f -name "*.go" 2>/dev/null || true)

# Scripts
echo "  Finding shell scripts..." >&2
while IFS= read -r file; do
    add_to_category "scripts" "${file}"
done < <(find . -type f -name "*.sh" -not -path "./vendor/*" -not -path "./.git/*" -not -path "*/node_modules/*" 2>/dev/null || true)

# Count totals
echo "" >&2
echo "Discovery complete. Summary:" >&2
jq -r '
  "  RBAC: \(.k8s_manifests.rbac | length) files",
  "  Network: \(.k8s_manifests.network | length) files",
  "  Secrets: \(.k8s_manifests.secrets | length) files",
  "  CRDs: \(.k8s_manifests.crds | length) files",
  "  Controllers: \(.go_code.controllers | length) files",
  "  API: \(.go_code.api | length) files",
  "  Webhooks: \(.go_code.webhooks | length) files",
  "  Pkg: \(.go_code.pkg | length) files",
  "  Scripts: \(.scripts | length) files"
' "${OUTPUT_FILE}" >&2

echo "" >&2
echo "Manifest saved to: ${OUTPUT_FILE}" >&2
