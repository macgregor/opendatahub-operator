# Testing Patterns for OpenDataHub Operator

Quick reference for AI agents generating tests. Follow these patterns for consistency.

## Framework & Imports

```go
import (
    "testing"
    . "github.com/onsi/gomega"
    gt "github.com/onsi/gomega/types"

    "github.com/opendatahub-io/opendatahub-operator/v2/pkg/utils/test/fakeclient"
    "github.com/opendatahub-io/opendatahub-operator/v2/pkg/utils/test/matchers/jq"
    "github.com/opendatahub-io/opendatahub-operator/v2/pkg/utils/test/mocks"
)
```

**Libraries**: Gomega (assertions), Ginkgo v2 (BDD), fakeclient (K8s mocks), jq matchers (JSON assertions)

## File Organization

- **Unit tests**: `*_test.go` alongside implementation
- **Integration tests**: `*_int_test.go` or `integration_test.go`
- **Suite setup**: `*_suite_test.go`
- **Package naming**: `package <pkg>_test` (preferred) or `package <pkg>` with `//nolint:testpackage`

## Standard Test Structure

### Basic Test

```go
func TestFunctionName(t *testing.T) {
    g := NewWithT(t)
    ctx := t.Context()

    // Setup
    cli, err := fakeclient.New()
    g.Expect(err).ShouldNot(HaveOccurred())

    // Execute
    result, err := functionUnderTest(ctx, params)

    // Assert
    g.Expect(err).ShouldNot(HaveOccurred())
    g.Expect(result).Should(Equal(expected))
}
```

### Table-Driven Test

```go
func TestFunction(t *testing.T) {
    tests := []struct {
        name        string
        input       Type
        expected    Type
        expectError bool
    }{
        {
            name:     "descriptive test case name",
            input:    value,
            expected: expected,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            g := NewWithT(t)

            result, err := functionUnderTest(tt.input)

            if tt.expectError {
                g.Expect(err).Should(HaveOccurred())
                return
            }

            g.Expect(err).ShouldNot(HaveOccurred())
            g.Expect(result).Should(Equal(tt.expected))
        })
    }
}
```

### Parallel Execution

```go
func TestFunction(t *testing.T) {
    t.Parallel()

    tests := []struct { /* ... */ }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            t.Parallel()
            // test body
        })
    }
}
```

### Integration Tests (EnvTest)

#### Suite Setup

```go
var cfg *rest.Config
var k8sClient client.Client
var testEnv *envtest.Environment

func TestAPIs(t *testing.T) {
    RegisterFailHandler(Fail)
    RunSpecs(t, "Suite Name")
}

var _ = BeforeSuite(func() {
    logf.SetLogger(zap.New(zap.WriteTo(GinkgoWriter), zap.UseDevMode(true)))

    testEnv = &envtest.Environment{
        CRDDirectoryPaths:     []string{filepath.Join("..", "..", "config", "crd", "bases")},
        ErrorIfCRDPathMissing: true,
    }

    var err error
    cfg, err = testEnv.Start()
    Expect(err).NotTo(HaveOccurred())

    DeferCleanup(func() {
        if testEnv != nil {
            Expect(testEnv.Stop()).To(Succeed())
        }
    })

    // Add schemes
    err = componentApi.AddToScheme(scheme.Scheme)
    Expect(err).NotTo(HaveOccurred())

    k8sClient, err = client.New(cfg, client.Options{Scheme: scheme.Scheme})
    Expect(err).NotTo(HaveOccurred())
})
```

#### Ginkgo BDD Tests

```go
var _ = Describe("Feature description", func() {
    Context("specific scenario", func() {
        var cleaner *envtestutil.Cleaner

        BeforeEach(func() {
            cleaner = envtestutil.CreateCleaner(k8sClient, cfg, timeout, interval)
        })

        It("should perform expected behavior", func(ctx context.Context) {
            // given
            obj := createTestObject()
            defer cleaner.DeleteAll(ctx, obj)

            // when
            result, err := performOperation(ctx, k8sClient, obj)

            // then
            Expect(err).ToNot(HaveOccurred())
            Expect(result).To(Equal(expected))
        })
    })
})
```

## Mocking & Fixtures

### Fake Client

```go
import "github.com/opendatahub-io/opendatahub-operator/v2/pkg/utils/test/fakeclient"

// With pre-existing objects
cli, err := fakeclient.New(fakeclient.WithObjects(obj1, obj2))
g.Expect(err).ShouldNot(HaveOccurred())

// Empty client
cli, err := fakeclient.New()
g.Expect(err).ShouldNot(HaveOccurred())
```

### Mock Controllers

```go
import "github.com/opendatahub-io/opendatahub-operator/v2/pkg/utils/test/mocks"

rr := types.ReconciliationRequest{
    Controller: mocks.NewMockController(func(m *mocks.MockController) {
        m.On("Owns", mock.Anything).Return(true)
    }),
}
```
