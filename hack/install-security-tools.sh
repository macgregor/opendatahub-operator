#!/usr/bin/env bash

# Security Tools Installation Script
# Installs all security scanning tools needed for local development
#
# Usage:
#   ./hack/install-security-tools.sh [--all|--go|--system]
#
# Options:
#   --all      Install all tools (default)
#   --go       Install only Go-based tools (gosec, gitleaks)
#   --system   Install only system tools (shellcheck, trivy, snyk)

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Tool versions (use latest for simplicity)
GOSEC_VERSION="${GOSEC_VERSION:-latest}"
GITLEAKS_VERSION="${GITLEAKS_VERSION:-latest}"

# Determine install mode
INSTALL_MODE="${1:---all}"

# Detect OS
OS="unknown"
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
fi

# Utility functions
print_header() {
    echo -e "${BLUE}==>${NC} ${1}"
}

print_success() {
    echo -e "${GREEN}✓${NC} ${1}"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} ${1}"
}

print_error() {
    echo -e "${RED}✗${NC} ${1}"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install Go-based tools
install_go_tools() {
    print_header "Installing Go-based security tools..."

    # Check if Go is installed
    if ! command_exists go; then
        print_error "Go is not installed. Please install Go first: https://golang.org/dl/"
        return 1
    fi

    # Install gosec
    print_header "Installing gosec ${GOSEC_VERSION}..."
    if go install "github.com/securego/gosec/v2/cmd/gosec@${GOSEC_VERSION}"; then
        print_success "gosec installed successfully"
    else
        print_error "Failed to install gosec"
        return 1
    fi

    # Install gitleaks
    print_header "Installing gitleaks ${GITLEAKS_VERSION}..."
    if go install "github.com/zricethezav/gitleaks/v8@${GITLEAKS_VERSION}"; then
        print_success "gitleaks installed successfully"
    else
        print_error "Failed to install gitleaks"
        return 1
    fi
}

# Install ShellCheck
install_shellcheck() {
    print_header "Installing ShellCheck..."

    if command_exists shellcheck; then
        print_success "ShellCheck is already installed ($(shellcheck --version | head -n 2 | tail -n 1))"
        return 0
    fi

    case "$OS" in
        macos)
            if command_exists brew; then
                brew install shellcheck
                print_success "ShellCheck installed via Homebrew"
            else
                print_warning "Homebrew not found. Install manually from: https://www.shellcheck.net/"
            fi
            ;;
        linux)
            if command_exists apt-get; then
                print_header "Installing ShellCheck via apt..."
                print_warning "This requires sudo privileges. If it fails, run manually:"
                print_warning "  sudo apt-get update && sudo apt-get install -y shellcheck"
                if sudo -n apt-get update 2>/dev/null && sudo -n apt-get install -y shellcheck 2>/dev/null; then
                    print_success "ShellCheck installed via apt"
                else
                    print_warning "Could not install automatically. Please run: sudo apt-get install -y shellcheck"
                fi
            elif command_exists dnf; then
                print_header "Installing ShellCheck via dnf..."
                print_warning "This requires sudo privileges. If it fails, run manually:"
                print_warning "  sudo dnf install -y ShellCheck"
                if sudo -n dnf install -y ShellCheck 2>/dev/null; then
                    print_success "ShellCheck installed via dnf"
                else
                    print_warning "Could not install automatically. Please run: sudo dnf install -y ShellCheck"
                fi
            elif command_exists yum; then
                print_header "Installing ShellCheck via yum..."
                print_warning "This requires sudo privileges. If it fails, run manually:"
                print_warning "  sudo yum install -y ShellCheck"
                if sudo -n yum install -y ShellCheck 2>/dev/null; then
                    print_success "ShellCheck installed via yum"
                else
                    print_warning "Could not install automatically. Please run: sudo yum install -y ShellCheck"
                fi
            else
                print_warning "Package manager not detected. Install manually from: https://www.shellcheck.net/"
            fi
            ;;
        *)
            print_warning "OS not detected. Install manually from: https://www.shellcheck.net/"
            ;;
    esac
}

# Install Trivy
install_trivy() {
    print_header "Installing Trivy..."

    if command_exists trivy; then
        print_success "Trivy is already installed ($(trivy version | head -n 1))"
        return 0
    fi

    case "$OS" in
        macos)
            if command_exists brew; then
                brew install trivy
                print_success "Trivy installed via Homebrew"
            else
                print_warning "Homebrew not found. Install manually from: https://aquasecurity.github.io/trivy/"
            fi
            ;;
        linux)
            print_header "Installing Trivy from GitHub releases..."
            TRIVY_VERSION=$(curl -s https://api.github.com/repos/aquasecurity/trivy/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
            curl -sfL "https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh" | sh -s -- -b "$HOME/.local/bin" "v${TRIVY_VERSION}"
            print_success "Trivy installed to $HOME/.local/bin/trivy"
            print_warning "Make sure $HOME/.local/bin is in your PATH"
            ;;
        *)
            print_warning "OS not detected. Install manually from: https://aquasecurity.github.io/trivy/"
            ;;
    esac
}

# Install Snyk
install_snyk() {
    print_header "Installing Snyk..."

    if command_exists snyk; then
        print_success "Snyk is already installed ($(snyk version))"
        return 0
    fi

    if ! command_exists npm; then
        print_warning "npm not found. Install Node.js/npm first, then run: npm install -g snyk"
        return 1
    fi

    print_header "Installing Snyk via npm..."
    if npm install -g snyk; then
        print_success "Snyk installed successfully"
        print_warning "Run 'snyk auth' to authenticate with your Snyk account"
    else
        print_error "Failed to install Snyk"
    fi
}

# Install system tools
install_system_tools() {
    install_shellcheck
    install_trivy
    install_snyk
}

# Main installation
main() {
    print_header "Security Tools Installation"
    echo ""

    case "$INSTALL_MODE" in
        --go)
            install_go_tools
            ;;
        --system)
            install_system_tools
            ;;
        --all|*)
            install_go_tools
            echo ""
            install_system_tools
            ;;
    esac

    echo ""
    print_header "Installation Summary"
    echo ""

    # Check which tools are installed
    local all_installed=true

    for tool in gosec gitleaks shellcheck trivy snyk; do
        if command_exists "$tool"; then
            print_success "$tool is installed"
        else
            print_warning "$tool is NOT installed"
            all_installed=false
        fi
    done

    echo ""
    if $all_installed; then
        print_success "All security tools are installed!"
        echo ""
        echo "Next steps:"
        echo "  1. Run 'make security' to scan your code"
        echo "  2. For Snyk, authenticate with: snyk auth"
    else
        print_warning "Some tools are not installed. See warnings above."
    fi

    echo ""
    print_header "Usage"
    echo "  make security              - Run fast local security checks"
    echo "  make security-full         - Run all security checks"
    echo "  make security-help         - Show detailed help"
}

# Run main
main
