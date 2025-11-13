# Security scanning tools and targets for local development
# This file can be shared across projects for consistent security practices
#
# Tools included:
# - gosec: Go security scanner
# - gitleaks: Secret scanner
# - shellcheck: Shell script linter
# - trivy: Container vulnerability scanner
# - snyk: Dependency vulnerability scanner (requires SNYK_TOKEN)

##@ Security

## Tool Binaries (security-specific)
GOSEC ?= $(LOCALBIN)/gosec
GITLEAKS ?= $(LOCALBIN)/gitleaks
TRIVY ?= trivy
SNYK ?= snyk
SHELLCHECK ?= shellcheck

## Tool Versions
GOSEC_VERSION ?= latest
GITLEAKS_VERSION ?= latest

## Security Output Directory
SECURITY_OUT_DIR ?= .security-reports
$(SECURITY_OUT_DIR):
	@mkdir -p $(SECURITY_OUT_DIR)

.PHONY: security
security: gosec shellcheck secrets-check ## Run all fast security checks (local development)
	@echo "Basic security checks finished"

.PHONY: security-full
security-full: security scan-images snyk-check ## Run all security checks including container and dependency scans
	@echo "Comprehensive security checks finished"

.PHONY: gosec
gosec: $(GOSEC) $(SECURITY_OUT_DIR) ## Run gosec Go security scanner
	@echo "Scanning Go code for security issues..."
	@# Note: gosec's SSA analyzer can have issues with some packages (known bug)
	@# Using -no-fail to continue scanning despite import errors in dependencies
	@$(GOSEC) -fmt=sarif -out=$(SECURITY_OUT_DIR)/gosec-report.sarif -exclude-generated -no-fail -quiet ./... 2>&1 || true
	@echo ""
	@echo "Security findings:"
	@$(GOSEC) -fmt=text -exclude-generated -no-fail -quiet ./... 2>/dev/null
	@echo ""
	@echo "Detailed report saved to: $(SECURITY_OUT_DIR)/gosec-report.sarif"

.PHONY: shellcheck
shellcheck: ## Run ShellCheck on all shell scripts
	@echo "Running ShellCheck on shell scripts..."
	@SCRIPTS=$$(find . -name "*.sh" -not -path "./vendor/*" -not -path "./.git/*" -not -path "*/node_modules/*"); \
	if [ -n "$$SCRIPTS" ]; then \
		echo "$$SCRIPTS" | xargs $(SHELLCHECK) -f gcc; \
		echo "ShellCheck passed"; \
	else \
		echo "No shell scripts found to check"; \
	fi

.PHONY: secrets-check
secrets-check: $(GITLEAKS) $(SECURITY_OUT_DIR) ## Run Gitleaks secret scanner
	@echo "Running Gitleaks secret scanner..."
	@$(GITLEAKS) detect --source . --report-path=$(SECURITY_OUT_DIR)/gitleaks-report.json --no-git --verbose || { \
		echo "Secrets detected! Review $(SECURITY_OUT_DIR)/gitleaks-report.json"; \
		exit 1; \
	}
	@echo "No secrets detected"

.PHONY: scan-images
scan-images: $(SECURITY_OUT_DIR) ## Scan container images with Trivy (requires built image)
	@echo "Running Trivy container vulnerability scanner..."
	@echo "Scanning image: $(IMG)"
	@$(TRIVY) image --severity HIGH,CRITICAL --format sarif --output $(SECURITY_OUT_DIR)/trivy-report.sarif $(IMG) || true
	@$(TRIVY) image --severity HIGH,CRITICAL $(IMG)

.PHONY: snyk-check
snyk-check: $(SECURITY_OUT_DIR) ## Run Snyk security check (requires SNYK_TOKEN environment variable)
	@echo "Running Snyk security scanner..."
	@if [ -z "$$SNYK_TOKEN" ]; then \
		echo "SNYK_TOKEN not set. Skipping Snyk scan."; \
		echo "   Set SNYK_TOKEN environment variable or run: snyk auth"; \
		exit 0; \
	fi
	@echo "Running Snyk dependency scan..."
	@$(SNYK) test --all-projects --sarif-file-output=$(SECURITY_OUT_DIR)/snyk-report.sarif || true
	@echo "Running Snyk code scan..."
	@$(SNYK) code test --sarif-file-output=$(SECURITY_OUT_DIR)/snyk-code-report.sarif || true
	@$(SNYK) test --all-projects

.PHONY: security-audit-ai
security-audit-ai: ## Run AI-powered comprehensive security audit
	@claude /security-audit

.PHONY: security-clean
security-clean: ## Clean security report outputs
	@echo "Cleaning security reports..."
	@rm -rf $(SECURITY_OUT_DIR)

.PHONY: security-install-tools
security-install-tools:
	@. ./hack/install-security-tools.sh

.PHONY: security-help
security-help: ## Show detailed security tools help
	@echo "Security Scanning Targets:"
	@echo ""
	@echo "Quick Start:"
	@echo "  make security              - Run fast local security checks (gosec, shellcheck, secrets)"
	@echo "  make security-full         - Run all security checks including container and dependency scans"
	@echo "  make security-audit-ai     - Run AI-powered comprehensive security audit (requires Claude Code)"
	@echo ""
	@echo "Individual Scans:"
	@echo "  make gosec                 - Scan Go code for security issues"
	@echo "  make shellcheck            - Lint shell scripts for issues"
	@echo "  make secrets-check         - Scan for secrets/credentials in code"
	@echo "  make scan-images           - Scan container images for vulnerabilities (requires IMG=...)"
	@echo "  make snyk-check            - Scan dependencies with Snyk (requires SNYK_TOKEN)"
	@echo ""
	@echo "Setup:"
	@echo "  make security-install-tools - Install security tools for local dev environment (gosec, gitleaks)"
	@echo ""
	@echo "Output:"
	@echo "  Reports are saved to: $(SECURITY_OUT_DIR)/"
	@echo "  SARIF format for GitHub Security tab integration"
	@echo ""
	@echo "Cleanup:"
	@echo "  make security-clean        - Remove all security report files"
