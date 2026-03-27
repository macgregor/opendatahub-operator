# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

The OpenDataHub Operator is a Kubernetes Operator that manages the deployment and lifecycle of data science applications and components. It uses two primary CRDs:
- **DataScienceCluster (DSC)**: Defines which components to enable/disable and their configurations
- **DSCInitialization (DSCI)**: Handles cluster-wide initialization (monitoring, service mesh, trusted CA bundles, application namespace)

## Common Commands

### Build and Development
```bash
# Build the operator binary
make build

# Run operator locally (with webhooks)
make run

# Run operator locally without webhooks (useful for debugging)
make run-nowebhook

# Build operator image
make image-build IMG=quay.io/<username>/opendatahub-operator:<tag>

# Build with local manifests (instead of fetching from remote)
make image-build USE_LOCAL=true
```

### Testing
```bash
# Run unit tests
make unit-test

# Run e2e tests (requires cluster with operator deployed)
make e2e-test

# Run e2e tests for specific component only
make e2e-test -e E2E_TEST_COMPONENT=dashboard

# Run e2e tests excluding specific components
make e2e-test -e E2E_TEST_COMPONENT=!ray

# Run e2e tests for specific service
make e2e-test -e E2E_TEST_COMPONENTS=false -e E2E_TEST_SERVICE=monitoring

# Run e2e tests with operator running outside cluster (for debugging)
make e2e-test -e E2E_TEST_OPERATOR_CONTROLLER=false -e E2E_TEST_WEBHOOK=false

# Run Prometheus alert unit tests
make test-alerts

# Check for alerts without unit tests
make check-prometheus-alert-unit-tests
```

### Code Quality
```bash
# Run linters
make lint

# Auto-fix linting issues
make lint-fix

# Format code
make fmt

# Run kube-linter on rendered manifests
make kube-lint
```

### API and Documentation
```bash
# Generate CRDs, RBAC, and webhooks
make manifests

# Generate DeepCopy methods
make generate

# Update API documentation (required after API changes)
make api-docs
```

### Component Manifests
```bash
# Fetch all component manifests from remote repositories
make get-manifests

# Fetch manifests with custom source for a component
./get_all_manifests.sh --odh-dashboard="<org>:<repo>:<branch>:<source>:<target>"
```

### Deployment
```bash
# Deploy operator to cluster
make deploy IMG=<image> OPERATOR_NAMESPACE=<namespace>

# Undeploy operator
make undeploy

# Install only CRDs
make install

# Uninstall CRDs
make uninstall
```

### Bundle and OLM
```bash
# Generate bundle manifests
make bundle

# Build and push bundle image
make bundle-build bundle-push BUNDLE_IMG=<image>

# Deploy using OLM
operator-sdk run bundle <bundle-image> --namespace <namespace> --decompression-image quay.io/project-codeflare/busybox:1.36
```

### Running Single Tests
```bash
# Run unit tests for specific package
OPERATOR_NAMESPACE=opendatahub-operator-system KUBEBUILDER_ASSETS="$(./bin/setup-envtest use 1.31 --bin-dir ./bin -p path)" \
  ./bin/ginkgo -v ./internal/controller/components/dashboard

# Run single e2e test by name
go run -C ./cmd/test-retry main.go e2e --verbose --working-dir=$(pwd) -- -timeout 50m -ginkgo.focus="Dashboard"
```

## Architecture

### Core CRDs and Controllers

**DSCInitialization**: Cluster-wide initialization that must be created before DataScienceCluster. Configures:
- Application namespace (default: `opendatahub`)
- Monitoring setup (Prometheus, metrics, traces)
- Service Mesh integration
- Trusted CA bundle management
- Developer flags (log level, manifest sources)

**DataScienceCluster**: Manages component lifecycle. Each component has:
- `managementState`: `Managed`, `Removed`, or `Unmanaged`
- `devFlags.manifests`: Override manifests from custom git repos
- Component-specific configuration fields

### Component System

Components are modular and independently managed:
- **dashboard**: ODH/RHOAI web dashboard
- **workbenches**: Jupyter notebooks and development environments
- **datasciencepipelines**: Kubeflow Pipelines
- **kserve**: Model serving with KNative
- **modelregistry**: Model registry service
- **ray**: Distributed compute framework
- **kueue**: Job queueing
- **trainingoperator**: Distributed training (Kubeflow Training Operator)
- **trustyai**: AI explainability and bias detection
- **feastoperator**: Feature store
- **llamastackoperator**: LLamaStack integration
- **modelcontroller**: Model controller service

Each component:
- Has its own API in `api/components/<component>/`
- Has its own controller in `internal/controller/components/<component>/`
- Can be enabled/disabled independently via DSC spec
- Fetches manifests from component repositories (see `get_all_manifests.sh`)

### Key Directories

- `api/`: All CRD definitions
  - `api/datasciencecluster/`: DataScienceCluster CRD
  - `api/dscinitialization/`: DSCInitialization CRD
  - `api/components/`: Individual component CRDs
- `internal/controller/`: Reconciliation logic
  - `internal/controller/datasciencecluster/`: Main DSC controller
  - `internal/controller/dscinitialization/`: DSCI controller
  - `internal/controller/components/`: Component controllers
  - `internal/controller/services/`: Service controllers (monitoring, auth, etc.)
- `pkg/`: Shared packages and utilities
  - `pkg/controller/`: Base controller utilities and actions
  - `pkg/deploy/`: Deployment helpers
  - `pkg/cluster/`: Cluster utilities
- `config/`: Kubernetes manifests
  - `config/crd/`: Generated CRDs
  - `config/rbac/`: RBAC configurations
  - `config/manager/`: Operator deployment manifests
  - `config/monitoring/`: Monitoring configurations (Prometheus, alerts)
- `opt/manifests/`: Component manifests (fetched by `get_all_manifests.sh`)
- `tests/`:
  - `tests/e2e/`: End-to-end tests
  - `tests/integration/`: Integration tests
  - `tests/prometheus_unit_tests/`: Prometheus alert tests

### Reconciliation Process

The DataScienceCluster controller follows a multi-stage reconciliation:
1. **Initialize**: Set up initial state
2. **Check Pre-conditions**: Validate DSCI exists and is ready
3. **Update Status**: Update DSC status conditions
4. **Provision Components**: Enable/disable components based on spec
5. **Deploy Resources**: Apply manifests and create resources
6. **Garbage Collection**: Clean up removed components

Controllers use an action-based pipeline pattern defined in `pkg/controller/actions/`.

### Manifest Management

Component manifests are fetched from upstream repositories via `get_all_manifests.sh`:
- Each component maps to: `<repo-org>:<repo-name>:<branch>:<source-folder>:<target-folder>`
- Stored locally in `opt/manifests/<component>/`
- Can be overridden at runtime using `devFlags.manifests` in component specs
- Image builds fetch fresh manifests by default (`USE_LOCAL=false`)

## Development Workflow

### Prerequisites
- Go 1.24
- Operator SDK v1.37.0+
- Access to a Kubernetes/OpenShift cluster
- `kubectl` or `oc` CLI configured

### Adding a New Component

1. Generate component scaffold:
```bash
make new-component COMPONENT=<component-name>
```

2. This generates:
   - API definition in `api/components/<component>/`
   - Controller in `internal/controller/components/<component>/`
   - Updated manifests and documentation

3. Add component to `get_all_manifests.sh` in `COMPONENT_MANIFESTS` map

4. Implement reconciliation logic in the generated controller

5. Add unit tests in controller directory and e2e tests in `tests/e2e/<component>_test.go`

6. Update documentation:
```bash
make generate manifests api-docs
```

### Testing Changes

For component manifest changes, use `devFlags.manifests` in DSC:
```yaml
spec:
  components:
    dashboard:
      managementState: Managed
      devFlags:
        manifests:
          - contextDir: manifests
            sourcePath: ''
            uri: https://github.com/<org>/<repo>
            ref: <branch>
```

For operator code changes:
1. Build custom image: `make image-build IMG=<your-image>`
2. Deploy: `make deploy IMG=<your-image>`
3. Create/update DSCI and DSC resources
4. Run e2e tests or manual validation

### Debugging

Run operator locally without webhooks:
```bash
export OPERATOR_NAMESPACE=opendatahub-operator-system
export DEFAULT_MANIFESTS_PATH=opt/manifests
make run-nowebhook
```

Then in another terminal, create DSCI and DSC resources.

For profiling, pprof is available at `http://127.0.0.1:6060` when running locally.

### Contributing

Before submitting PRs:
1. Link to Jira issue (required for all non-`chore` commits)
2. Run quality gates: `make lint`, `make unit-test`, `make api-docs`
3. Follow conventional commit format: `<type>(<scope>): <summary>`
4. Ensure test coverage doesn't decrease
5. After merge to `main`, sync to downstream `rhoai` branch (separate PR)

Issues tracked at: https://issues.redhat.com/secure/RapidBoard.jspa?rapidView=18680

Slack: **#forum-openshift-ai-operator**

## Important Notes

- Only ONE DataScienceCluster instance is supported per cluster
- DSCInitialization must exist and be Ready before creating DataScienceCluster
- Default application namespace is `opendatahub` (customizable via DSCI)
- For KServe or single model serving, install these operators first:
  - Authorino operator
  - Service Mesh operator
  - Serverless operator
- When changing log level at runtime, use `.spec.devFlags.logLevel` in DSCI
- PR images are automatically built: `quay.io/opendatahub/opendatahub-operator:pr-<number>`
- Use `local.mk` file to override Makefile variables for your environment
