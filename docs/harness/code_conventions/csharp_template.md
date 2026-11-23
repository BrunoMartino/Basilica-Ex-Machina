# C# / .NET — Code conventions

Opinionated conventions for C# / .NET, derived from the [C# coding conventions](https://learn.microsoft.com/dotnet/csharp/fundamentals/coding-style/coding-conventions) and the [.NET Framework Design Guidelines](https://learn.microsoft.com/dotnet/standard/design-guidelines/). Instantiate as the project's single `docs/harness/code_conventions.md`; keep the seven pillars exactly as they are (same structure as `generic_template.md`).

## Formatting

### Formatter

`dotnet format` owns indentation (4 spaces), braces (Allman), spacing and `using` ordering, driven by a versioned `.editorconfig`. Never hand-format or argue style the formatter already decides.

### Namespaces and usings

Use file-scoped namespaces that mirror the folder path. `using` directives go at the top of the file, outside the namespace; `<ImplicitUsings>enable</ImplicitUsings>` stays on.

```csharp
// Good:
namespace Billing.Invoices;

// Bad:
namespace Billing.Invoices
{
}
```

### Nullability

`<Nullable>enable</Nullable>` stays on in every project. Handle the null; never silence the warning with the null-forgiving operator.

```csharp
// Bad:
var name = customer!.Name;

// Good:
if (customer is null) return Response.NotFound();
var name = customer.Name;
```

### Commentary

Comments explain *why*, never *what* the code already says. Every public symbol carries an XML doc comment (`/// <summary>`).

Block comments (`/* */`) are reserved for file headers and for methods that were allowed to exceed the cyclomatic or cognitive complexity thresholds of `babylon-gardens` — the comment states why the exception exists.

## Naming

Names are declarative and self-explanatory: they state what the thing is or does, combining the action with the object handled (`ReadComments`, `WritePrice`), readable by a human without AI assistance.

### Casing

| Element | Convention | Example |
|---|---|---|
| Namespace / project | PascalCase, mirrors folder | `Billing.Invoices` |
| File | one public type per file, file name = type name; partials `Type.Part.cs` | `InvoiceController.Payments.cs` |
| Class / record / struct / enum | PascalCase noun; enum singular (plural only for `[Flags]`) | `InvoiceStatus` |
| Interface | `I` + PascalCase | `IInvoiceRepository` |
| Method | PascalCase verb; `Async` suffix when it returns `Task`/`ValueTask` | `SendInvoiceAsync` |
| Property | PascalCase noun; booleans read as a question | `IsPaid`, `HasItems` |
| Parameter / local | camelCase | `invoiceId` |
| Private field | `_camelCase` | `_clock` |
| Constant / `static readonly` | PascalCase | `MaxRetries` |
| Type parameter | `T` + PascalCase | `TResult` |

Casing never breaks the C# convention to imitate another language: a constant is `MaxLength`, not `MAX_LENGTH`.

### No abbreviated names

No abbreviations beyond the universal ones (`Id`, `Url`, `Http`, `Api`, `Dto`, `Db`). Acronyms are cased as words: `HttpClient`, `XmlReader`, `userId`.

### Roles

Controllers name the resource (`InvoiceController`); services the business workflow (`InvoiceIssuingService`); repositories the aggregate (`InvoiceRepository`); gateways the external system (`StripeGateway`); factories what they create (`InvoiceFactory`); strategies the interchangeable behavior (`RetryStrategy`); settings classes the section they bind (`SmtpSettings`).

Forbidden as dumping-ground names: `Manager`, `Processor`, `Handler`, `Helper`, `Util`, unless the responsibility is unmistakable (e.g. a mediator `CreateInvoiceCommandHandler`). Prefer an extension class named after the type it extends over a `Helper`.

### Getters and setters

Properties never use `Get`/`Set`. Methods use `Get` only for a cheap, in-memory read; use `Fetch`/`Load` when the call does I/O and `Compute`/`Calculate` when it derives a value, so the reader knows it may block or fail.

### Anti-patterns

Do not repeat in a name what the context already says: the namespace, the class name, the parameter names or the return type.

```csharp
// Bad:
public class Invoice
{
    public decimal InvoiceTotal { get; }
    public InvoiceDto ConvertInvoiceToInvoiceDto() { ... }
}

// Good:
public class Invoice
{
    public decimal Total { get; }
    public InvoiceDto ToDto() { ... }
}
```

## Errors

### Expected failures are values

Expected business failures are part of the method's contract: return an explicit result type carrying a typed error code, handled by the caller. Exceptions are for the unexpected.

```csharp
// Good:
public async Task<Result<Invoice>> IssueAsync(IssueInvoiceRequest request, CancellationToken cancellationToken)
{
    if (request.Items.Count == 0)
        return Result.Failure<Invoice>(ErrorCode.EmptyInvoice);
    ...
}
```

Compare errors by type or code, never by message string.

### Exceptions

- Catch only what you can handle, and catch the specific type; a bare `catch (Exception)` belongs only to the outermost boundary (middleware, worker loop).
- Rethrow with `throw;` — `throw ex;` destroys the stack trace.
- When wrapping, pass the original as `innerException` and add only information it does not already carry.
- Log the exception object, not only its message.

```csharp
// Bad:
catch (Exception ex)
{
    logger.LogError("Failed: " + ex.Message);
    throw ex;
}

// Good:
catch (HttpRequestException ex)
{
    logger.LogError(ex, "Payment gateway unreachable for invoice {InvoiceId}", invoice.Id);
    throw;
}
```

### Anti-patterns

- Never catch an error and return success; never swallow an error without logging or recovery.
- Never leak secrets, stack traces, `ex.Message` or internal identifiers to users: one global exception handler maps unhandled exceptions to a single public error shape (`ProblemDetails`) with a trace id.
- Never use exceptions for control flow.

### Validation

Validate inputs at the boundary, before any business logic runs, and return every violation at once in the public error shape.

## Structure

Framework-native code first; readable before clever; no premature abstraction; follow the existing conventions of the project before inventing new ones. Layers and dependency direction come from `architecture_rules.md`.

### Responsibilities

- Controllers / endpoints parse inputs, validate, call one use case and map its result to an HTTP response; no business rules, no data access.
- Domain entities hold data, invariants and simple behavior; no I/O.
- Application services hold workflows and depend only on abstractions of I/O; a multi-write operation runs inside one transaction.
- Repositories own data access; SQL is always parameterised, never concatenated with input.
- Gateways own calls to external systems; `HttpClient` comes from `IHttpClientFactory`, never `new HttpClient()`.
- Design patterns only when they clarify intent and are documented for the feature (`docs/harness/features/feature-{name}.md`); a complexity fix is a refactor inside the pattern, never a pattern swap.

### Dependency injection

Dependencies arrive through the constructor; prefer primary constructors, and use an explicit constructor only when initialisation logic is needed. Never `new` a service and never resolve from `IServiceProvider` as a service locator.

```csharp
// Good:
public class InvoiceIssuingService(IInvoiceRepository invoices, IOptions<BillingSettings> settings)
{
    private readonly BillingSettings _settings = settings.Value;
}
```

Each project registers its own implementations in one `IServiceCollection` extension method (`AddBilling`). Configuration is bound to typed settings classes through `IOptions<T>`; never read `IConfiguration` keys inside business code.

### Lifetimes

A singleton never holds a scoped service. A `BackgroundService` creates one scope per iteration or message and resolves its dependencies from it.

```csharp
// Good:
protected override async Task ExecuteAsync(CancellationToken stoppingToken)
{
    while (!stoppingToken.IsCancellationRequested)
    {
        await using var scope = scopeFactory.CreateAsyncScope();
        var service = scope.ServiceProvider.GetRequiredService<InvoiceIssuingService>();
        await service.RunAsync(stoppingToken);
    }
}
```

A service that keeps per-call state in fields is Scoped or Transient, never Singleton.

### Async

Async all the way: never block on a task, never `async void` (except event handlers). Every I/O method accepts a `CancellationToken` and passes it on.

```csharp
// Bad:
var invoice = repository.FetchAsync(id).Result;

// Good:
var invoice = await repository.FetchAsync(id, cancellationToken);
```

### Types and data

- DTOs, requests and responses are `record`s or classes with `init`/`required` properties; immutable by default.
- Classes are `sealed` unless designed for inheritance.
- Expose `IReadOnlyList<T>` / `IEnumerable<T>`; return an empty collection, never `null`.
- Dispose with `using` / `await using`.
- Time comes from an injected `TimeProvider`, stored in UTC; never `DateTime.Now` in business code.
- No magic numbers or strings: name them as constants or enums.

## Interfaces

We always prefer small interfaces, justified abstractions and composition.

- Small and named after the capability they expose (`IInvoiceReader`, `IClock`); do not grow unrelated responsibilities into an existing one.
- An interface exists only when there are at least two real implementations or a documented seam; every I/O boundary (repository, gateway, publisher, clock) is a seam. Entities and pure functions get no interface.
- Interfaces are declared where they are consumed (the application layer), not where they are implemented (infrastructure).
- Composition over inheritance; a base class is accepted only for a real Template Method or a generic base, never to share utility code.

## Tests

.NET does not allow test code inside a production assembly without shipping it, so tests live in dedicated projects under `src/tests`: one test project per production project (`<Project>.Tests`), folders mirroring the production tree, file name = class under test + `Tests`.

```
src
|_Core
|   |_Services
|       |_InvoiceIssuingService.cs
|_tests
    |_Core.Tests
    |   |_Services
    |       |_InvoiceIssuingServiceTests.cs
    |_Api.Tests
```

Every test project is added to the solution so `dotnet test` runs it. Test names state the behavior and the condition (`ReturnsEmptyInvoiceError_WhenRequestHasNoItems`); the body follows Arrange / Act / Assert. What is tested, the doubles allowed and the coverage focus come from `testing_expectation.md`; existing tests are immutable for agents (`persisted-tester`).

## Quality and Static Analysis

The gate is `babylon-gardens`; every stage must be green before a push. .NET toolchain:

| Stage | Tool |
|-------|------|
| Format | `dotnet format --verify-no-changes` |
| Static analysis | `dotnet build -warnaserror` with .NET analyzers (`AnalysisLevel=latest-recommended`) |
| Security | `dotnet list package --vulnerable --include-transitive`, plus Gitleaks (secrets) and Semgrep (cross-language) |
| Dead code | analyzers `IDE0005`, `IDE0051`, `IDE0052`, `IDE0060` enforced on build |
| Cyclomatic complexity | analyzer `CA1502` |
| Cognitive complexity | analyzer `S3776` (`SonarAnalyzer.CSharp`, build-time only, no server) |
| Duplication | `jscpd` |
| Tests | `dotnet test` (or `test_commands` in `quality-baseline.json`) |

Thresholds (copied into `quality-baseline.json` by SETUP; the harness wins over the skill defaults):

- Cyclomatic complexity ≤ 10 per method; cognitive complexity ≤ 15 per method.
- Duplication ≤ 3% of the codebase.
- Any vulnerable package or Semgrep finding of severity medium or higher fails; any Gitleaks finding fails.

A method allowed to exceed the complexity thresholds carries the block comment described in "Formatting → Commentary", and the exception is recorded in the Quality Run report as Accepted Risk, decided by the user. Agents never add `#pragma warning disable`, `[SuppressMessage]`, `<NoWarn>`, `gitleaks:allow`, ignore files, baselines or threshold bumps (`babylon-gate`); a false positive is reported as Accepted Risk with its reason. Dead code is removed, never commented out.
