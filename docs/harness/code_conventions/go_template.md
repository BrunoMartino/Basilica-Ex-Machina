# Go — Code conventions

Opinionated conventions for Go, derived from [Effective Go](https://go.dev/doc/effective_go) and the [Google Go Style Guide](https://google.github.io/styleguide/go/). Instantiate as the project's single `docs/harness/code_conventions.md`; keep the seven pillars exactly as they are (same structure as `generic_template.md`).

## Formatting

### Indentation

We use tabs for indentation and `gofmt` emits them by default. Use spaces only if you must.

### Line length

Go has no line length limit. Don't worry about overflowing a punched card. If a line feels too long, wrap it and indent with an extra tab.

### Parentheses

Go needs fewer parentheses than C and Java: control structures (`if`, `for`, `switch`) do not have parentheses in their syntax. Also, the operator precedence hierarchy is shorter and clearer, so

```go
x<<8 + y<<16
```

means what the spacing implies, unlike in the other languages.

### Commentary

Go provides C-style `/* */` block comments and C++-style `//` line comments.

Line comments are the norm.

Block comments appear mostly as package comments; we also use them on large and complex functions that were allowed to exceed the cyclomatic or cognitive complexity thresholds of `babylon-gardens` — the comment states why the exception exists.

## Naming

### Packages

- By convention, packages are given lower case, single-word names; there should be no need for underscores or mixedCaps.
- The package name is the base name of its source directory; the package in `src/encoding/base64` is imported as `"encoding/base64"` but has name `base64`, not `encoding_base64` and not `encodingBase64`.
- Short names read well in use: `once.Do(setup)` would not be improved by writing `once.DoOrWaitUntilDone(setup)`. Long names don't automatically make things more readable. A helpful doc comment can often be more valuable than an extra long name.

Prefer whole words. Short names are good, but avoid ambiguity. When in doubt, use the proto package name up to `_go` with a `pb` suffix:

```go
// Good:
import (
    pushqueueservicepb "path/to/package/push_queue_service_go_proto"
)
```

### Getters and setters

Function and method names should not use a `Get` or `get` prefix, unless the underlying concept uses the word "get" (e.g. an HTTP GET). Prefer starting the name with the noun directly: `Counts` over `GetCounts`. The same applies to `Set` or `set`.

If the function performs a complex computation or executes a remote call, a different word like `Compute` or `Fetch` can be used in place of `Get`, to make it clear to a reader that the call may take time and could block or fail.

Prefer self-explanatory, declarative names that describe objectively the operation performed.

### Interfaces

By convention, one-method interfaces are named by the method name plus an `-er` suffix or similar modification to construct an agent noun: `Reader`, `Writer`, `Formatter`, `CloseNotifier` etc.

There are a number of such names and it's productive to honor them and the function names they capture. `Read`, `Write`, `Close`, `Flush`, `String` and so on have canonical signatures and meanings. To avoid confusion, don't give your method one of those names unless it has the same signature and meaning. Conversely, if your type implements a method with the same meaning as a method on a well-known type, give it the same name and signature; call your string-converter method `String`, not `ToString`.

You can combine the action with the object/data being manipulated: `ReadComments`, `WritePrice`.

### MixedCaps

Go source code uses `MixedCaps` or `mixedCaps` (camel case) rather than underscores (snake case) when writing multi-word names.

This applies even when it breaks conventions in other languages. For example, a constant is `MaxLength` (not `MAX_LENGTH`) if exported and `maxLength` (not `max_length`) if unexported.

Local variables are considered unexported for the purpose of choosing the initial capitalization.

### No abbreviated names

Over-abbreviated names are bad for human reading. Our code is meant to be clear, concise and declarative for humans who can read and update it even without AI.

### Functions

Exported functions use `PascalCase`, unexported ones `camelCase`; both have self-explanatory, declarative names that combine the action with the object/data handled: `ReadComments`, `WritePrice`.

Functions that return something are given noun-like names.

```go
// Good:
func (c *Config) JobName(key string) (value string, ok bool)
```

Functions that do something are given verb-like names.

```go
// Good:
func (c *Config) WriteDetail(w io.Writer) (int64, error)
```

Identical functions that differ only by the types involved include the name of the type at the end of the name.

```go
// Good:
func ParseInt(input string) (int, error)
func ParseInt64(input string) (int64, error)
func AppendInt(buf []byte, value int) []byte
func AppendInt64(buf []byte, value int64) []byte
```

#### Anti-patterns

When choosing the name for a function or method, consider the context in which the name will be read, avoiding excess repetition.

The following can generally be omitted from function and method names:

- The types of the inputs and outputs (when there is no collision)
- The type of a method's receiver
- Whether an input or output is a pointer

For functions, do not repeat the name of the package.

```go
// Bad:
package yamlconfig

func ParseYAMLConfig(input string) (*Config, error)

// Good:
package yamlconfig

func Parse(input string) (*Config, error)
```

For methods, do not repeat the name of the method receiver.

```go
// Bad:
func (c *Config) WriteConfigTo(w io.Writer) (int64, error)

// Good:
func (c *Config) WriteTo(w io.Writer) (int64, error)
```

Do not repeat the names of variables passed as parameters.

```go
// Bad:
func OverrideFirstWithSecond(dest, source *Config) error

// Good:
func Override(dest, source *Config) error
```

Do not repeat the names and types of the return values.

```go
// Bad:
func TransformToJSON(input *Config) *jsonconfig.Config

// Good:
func Transform(input *Config) *jsonconfig.Config
```

When it is necessary to disambiguate functions of a similar name, it is acceptable to include extra information.

```go
// Good:
func (c *Config) WriteTextTo(w io.Writer) (int64, error)
func (c *Config) WriteBinaryTo(w io.Writer) (int64, error)
```

### Variables and constants

Variables, constants and objects use `camelCase` (or `MixedCaps` when exported) with declarative, self-explanatory names, like `var unhealthyFuncs []func()`.

#### Initialization

For consistency, prefer `:=` over `var` when initializing a new variable with a non-zero value.

```go
// Good:
i := 42
```

#### Declaring variables with zero values

The following declarations use the zero value:

```go
// Good:
var (
    coords Point
    magic  [4]byte
    primes []int
)
```

A common application of zero value declaration is when using a variable as the output when unmarshalling:

```go
// Good:
var coords Point
if err := json.Unmarshal(data, &coords); err != nil {
```

If you need a lock or other field that must not be copied in your struct, you can make it a value type to take advantage of zero value initialization. It does mean that the containing type must now be passed via a pointer and not a value. Methods on the type must take pointer receivers.

```go
// Good:
type Counter struct {
    // This field does not have to be "*sync.Mutex". However,
    // users must now pass *Counter objects between themselves, not Counter.
    mu   sync.Mutex
    data map[string]int64
}

// Note this must be a pointer receiver to prevent copying.
func (c *Counter) IncrementBy(name string, n int64)
```

#### Composite literals

The following are composite literal declarations:

```go
// Good:
var (
    coords   = Point{X: x, Y: y}
    magic    = [4]byte{'I', 'W', 'A', 'D'}
    primes   = []int{2, 3, 5, 7, 11}
    captains = map[string]string{"Kirk": "James Tiberius", "Picard": "Jean-Luc"}
)
```

You should declare a value using a composite literal when you know initial elements or members.

In contrast, using composite literals to declare empty or memberless values can be visually noisy compared to zero-value initialization.

When you need a pointer to a zero value, you have two options: empty composite literals and `new`. Both are fine, but the `new` keyword can serve to remind the reader that if a non-zero value were needed, a composite literal wouldn't work:

```go
// Good:
var (
  buf = new(bytes.Buffer) // non-empty Buffers are initialized with constructors.
  msg = new(pb.Message) // non-empty proto messages are initialized with builders or by setting fields one by one.
)
```

## Errors

### Error handling

```go
// Good:
func handlePet(...) {
    switch err := process(an); err {
    case ErrDuplicate:
        return fmt.Errorf("feed %q: %v", an, err)
    case ErrMarsupial:
        // Try to recover with a friend instead.
        alternate = an.BackupAnimal()
        return handlePet(..., alternate, ...)
    }
}
```

The above uses sentinel values, where the error must be equal (in the sense of `==`) to the expected value. That is perfectly adequate in many cases. If `process` returns wrapped errors, use `errors.Is`.

```go
// Good:
func handlePet(...) {
    switch err := process(an); {
    case errors.Is(err, ErrDuplicate):
        return fmt.Errorf("feed %q: %v", an, err)
    case errors.Is(err, ErrMarsupial):
        // ...
    }
}
```

When adding information to errors, avoid redundant information that the underlying error already provides. The `os` package, for instance, already includes path information in its errors.

```go
// Good:
if err := os.Open("settings.txt"); err != nil {
  return fmt.Errorf("launch codes unavailable: %v", err)
}
```

#### Anti-patterns

```go
// Bad:
if err := os.Open("settings.txt"); err != nil {
  return fmt.Errorf("could not open settings.txt: %v", err)
}

// Output:
//
// could not open settings.txt: open settings.txt: no such file or directory
```

Don't add an annotation if its sole purpose is to indicate a failure without adding new information. The presence of an error sufficiently conveys the failure to the caller.

```go
// Bad:
return fmt.Errorf("failed: %v", err) // just return err instead
```

## Structure

### Zero values

The zero-value-is-useful property works transitively. Consider this type declaration.

```go
type SyncedBuffer struct {
    lock    sync.Mutex
    buffer  bytes.Buffer
}
```

### Constructors and composite literals

Sometimes the zero value isn't good enough and an initializing constructor is necessary, as in this example derived from package `os`.

```go
func NewFile(fd int, name string) *File {
    if fd < 0 {
        return nil
    }
    f := new(File)
    f.fd = fd
    f.name = name
    f.dirinfo = nil
    f.nepipe = 0
    return f
}
```

```go
func NewFile(fd int, name string) *File {
    if fd < 0 {
        return nil
    }
    f := File{fd, name, nil, 0}
    return &f
}
```

### Allocation with `make` and `new`

```go
var p *[]int = new([]int)       // allocates slice structure; *p == nil; rarely useful
var v  []int = make([]int, 100) // the slice v now refers to a new array of 100 ints

// Unnecessarily complex:
var p *[]int = new([]int)
*p = make([]int, 100, 100)

// Idiomatic:
v := make([]int, 100)
```

Remember that `make` applies only to maps, slices and channels and does not return a pointer. To obtain an explicit pointer allocate with `new` or take the address of a variable explicitly.

### Arrays and slices

Even though array-like handling is idiomatic in Go, we prefer slices whenever possible.

```go
func Append(slice, data []byte) []byte {
    l := len(slice)
    if l + len(data) > cap(slice) {  // reallocate
        // Allocate double what's needed, for future growth.
        newSlice := make([]byte, (l+len(data))*2)
        // The copy function is predeclared and works for any slice type.
        copy(newSlice, slice)
        slice = newSlice
    }
    slice = slice[0:l+len(data)]
    copy(slice[l:], data)
    return slice
}
```

In functions with high cyclomatic or cognitive complexity, you have permission to use the C-like approach:

```go
func Sum(a *[3]float64) (sum float64) {
    for _, v := range *a {
        sum += v
    }
    return
}

array := [...]float64{7.0, 8.5, 9.1}
x := Sum(&array)  // Note the explicit address-of operator
```

### Maps

Maps can be constructed using the usual composite literal syntax with colon-separated key-value pairs, so it's easy to build them during initialization.

```go
var timeZone = map[string]int{
    "UTC":  0*60*60,
    "EST": -5*60*60,
    "CST": -6*60*60,
    "MST": -7*60*60,
    "PST": -8*60*60,
}
```

Assigning and fetching map values looks syntactically just like doing the same for arrays and slices except that the index doesn't need to be an integer.

```go
offset := timeZone["EST"]
```

### Variables and constants

In Go, enumerated constants are created using the `iota` enumerator. Since `iota` can be part of an expression and expressions can be implicitly repeated, it is easy to build intricate sets of values.

```go
type ByteSize float64

const (
    _           = iota // ignore first value by assigning to blank identifier
    KB ByteSize = 1 << (10 * iota)
    MB
    GB
    TB
    PB
    EB
    ZB
    YB
)
```

Variables can be initialized just like constants but the initializer can be a general expression computed at run time.

```go
var (
    home   = os.Getenv("HOME")
    user   = os.Getenv("USER")
    gopath = os.Getenv("GOPATH")
)
```

### Methods

```go
func (p *ByteSlice) Write(data []byte) (n int, err error) {
    slice := *p
    // Again as above.
    *p = slice
    return len(data), nil
}
```

### Interfaces on concrete types

```go
type Sequence []int

// Methods required by sort.Interface.
func (s Sequence) Len() int {
    return len(s)
}
func (s Sequence) Less(i, j int) bool {
    return s[i] < s[j]
}
func (s Sequence) Swap(i, j int) {
    s[i], s[j] = s[j], s[i]
}

// Copy returns a copy of the Sequence.
func (s Sequence) Copy() Sequence {
    copy := make(Sequence, 0, len(s))
    return append(copy, s...)
}

// Method for printing - sorts the elements before printing.
func (s Sequence) String() string {
    s = s.Copy() // Make a copy; don't overwrite argument.
    sort.Sort(s)
    str := "["
    for i, elem := range s { // Loop is O(N²); will fix that in next example.
        if i > 0 {
            str += " "
        }
        str += fmt.Sprint(elem)
    }
    return str + "]"
}
```

### Concurrency

Go users assume that conceptually read-only operations are safe for concurrent use and do not require extra synchronization.

The extra remark about concurrency can safely be removed in this Godoc:

```go
// Len returns the number of bytes of the unread portion of the buffer;
// b.Len() == len(b.Bytes()).
//
// It is safe to be called concurrently by multiple goroutines.
func (*Buffer) Len() int
```

Mutating operations, however, are not assumed to be safe for concurrent use and require the user to consider synchronization.

Documentation is strongly encouraged if any of the following are true.

It is unclear whether the operation is read-only or mutating:

```go
// Good:
package lrucache

// Lookup returns the data associated with the key from the cache.
//
// This operation is not safe for concurrent use.
func (*Cache) Lookup(key string) (data []byte, ok bool)
```

Why? A cache hit when looking up the key mutates an LRU cache internally. How this is implemented may not be obvious to all readers.

Synchronization is provided by the API:

```go
// Good:
package fortune_go_proto

// NewFortuneTellerClient returns an *rpc.Client for the FortuneTeller service.
// It is safe for simultaneous use by multiple goroutines.
func NewFortuneTellerClient(cc *rpc.ClientConn) *FortuneTellerClient
```

Why? Stubby provides synchronization.

Note: if the API is a type and the API provides synchronization in entirety, conventionally only the type definition documents the semantics.

The API consumes user-implemented types of interfaces, and the interface's consumer has particular concurrency requirements:

```go
// Good:
package health

// A Watcher reports the health of some entity (usually a backend service).
//
// Watcher methods are safe for simultaneous use by multiple goroutines.
type Watcher interface {
    // Watch sends true on the passed-in channel when the Watcher's
    // status has changed.
    Watch(changed chan<- bool) (unwatch func())

    // Health returns nil if the entity being watched is healthy, or a
    // non-nil error explaining why the entity is not healthy.
    Health() error
}
```

Why? Whether an API is safe for use by multiple goroutines is part of its contract.

## Interfaces

We always prefer small interfaces, justified abstractions and composition.

- One to three methods, named after the capability (`Reader`, `Writer`, `Watcher`); see "Naming → Interfaces" for canonical names and signatures.
- An interface exists only when there are at least two real implementations or a documented test seam; never one interface per struct by default.
- Interfaces are declared where they are consumed (the package that needs the behavior), not where they are implemented.
- Compose behavior by embedding interfaces and structs; no inheritance-like hierarchies.

## Tests

Tests always live in a `tests` folder inside the folder of the code they cover, respecting the folder/file naming rules of this document and the architecture instructions from `architecture_rules.md`. Test files end in `_test.go` (the only suffix `go test` compiles):

```
src
|_controllers
    user_controller.go
    app_controller.go
    |_tests
        user_controller_test.go
        app_controller_test.go
```

When it is not possible to keep them in the right parent folder, they live under `src/tests`, branching with folders that mirror the production tree:

```
src
|_controllers
|_repositories
|_services
|_tests
    |_controllers
    |    |_user_controller_test.go
    |    |_app_controller_test.go
    |_repositories
    |_services
```

A `tests` folder is its own package (`package controllers_test`-style), so tests exercise the exported API of the code under test. What is tested, the doubles allowed and the coverage focus come from `testing_expectation.md`; existing tests are immutable for agents (`persisted-tester`).

## Quality and Static Analysis

The gate is `babylon-gardens`; every stage must be green before a push. Go toolchain, all on the machine PATH, never in `go.mod`:

| Stage | Tool |
|-------|------|
| Format | `gofmt` |
| Static analysis | `staticcheck` |
| Security | `gosec`, plus Gitleaks (secrets) and Semgrep (cross-language) |
| Dead code | `deadcode` (`golang.org/x/tools`) + `staticcheck` `U1000` |
| Cyclomatic complexity | `gocyclo` |
| Cognitive complexity | `gocognit` |
| Duplication | `jscpd` |
| Tests | `go test ./...` (or `test_commands.go` in `quality-baseline.json`) |

Thresholds (copied into `quality-baseline.json` by SETUP; the harness wins over the skill defaults):

- Cyclomatic complexity ≤ 10 per function; cognitive complexity ≤ 15 per function.
- Duplication ≤ 3% of the codebase.
- Any `gosec`/Semgrep finding of severity medium or higher fails; any Gitleaks finding fails.

A function allowed to exceed the complexity thresholds carries the block comment described in "Formatting → Commentary", and the exception is recorded in the Quality Run report as Accepted Risk, decided by the user. Agents never add `//nolint`, `// #nosec`, `// nosemgrep`, `gitleaks:allow`, ignore files, baselines or threshold bumps (`babylon-gate`); a false positive is reported as Accepted Risk with its reason. Dead code is removed, never commented out.
