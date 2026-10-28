# {Stack} — Code conventions

Fallback template for a stack without a dedicated `{stack}_template.md` in this folder. The target project has **one** `docs/harness/code_conventions.md` for the whole codebase, legacy or new; it is instantiated from the template of the stack detected in the code (greenfield with no code yet: the user picks one file from this folder via AskQuestion) and keeps the seven pillars exactly as they are — `## Formatting`, `## Naming`, `## Errors`, `## Structure`, `## Interfaces`, `## Tests`, `## Quality and Static Analysis` — in this order, with these headings, nothing removed, renamed, merged or added. Fill every section for the stack, keeping cohesion with the conventions already in use, and replace every `TBD:` with the project's decision. Stack templates are written manually by the user; agents never create one.

## Formatting

- Use the stack's canonical formatter (`TBD: formatter`) with its default configuration; the formatter owns indentation, line length and spacing. Never hand-format or argue style the formatter already decides.
- Formatting runs on every commit (`babylon-gardens` pre-commit) and is checked by the Quality Run; a file that is not formatter-clean fails the gate.
- Comments explain *why*, never *what* the code already says. Doc comments on every exported/public symbol, in the stack's doc-comment syntax (`TBD: syntax`).
- Block comments are reserved for package/module headers and for functions that were allowed to exceed the complexity thresholds (see "Quality and Static Analysis"); the comment states why.

## Naming

- Names are declarative and self-explanatory: they state what the thing is or does, combining the action with the object it handles (`ReadComments`, `WritePrice`), readable by a human without AI assistance.
- No abbreviations beyond the stack's universal ones (`TBD: allowed abbreviations, e.g. id, url, http`). Short is good; ambiguous is not.
- Follow the stack's casing rules for packages/modules, files, types, functions, variables and constants (`TBD: casing table`). Casing never breaks the stack's convention to imitate another language.
- Controllers describe resources or actions; services describe business workflows; policies describe permissions; adapters name the external system; factories name what they create; strategies name the interchangeable behavior (`PaymentStrategy`, `NotificationAdapter`, `InvoiceFactory`, `AccessPolicy`, `CreateOrderCommand`).
- Forbidden as dumping-ground names: `Manager`, `Processor`, `Handler`, `Helper`, `Util`, unless the responsibility is unmistakable.
- No `Get`/`Set` prefix unless the underlying concept is literally a get/set (e.g. HTTP GET); prefer the noun (`Counts`, not `GetCounts`). Use `Compute`/`Fetch` when the call may block, fail or be slow.
- Do not repeat in a name what the context already says: the package/module name, the receiver/class name, the parameter names or the return types.

## Errors

- Expected business failures are explicit values or typed errors; they are part of the function's contract and are handled by the caller.
- Unexpected errors preserve context when wrapped: add only information the underlying error does not already carry; never annotate with "failed" alone — return the error as is.
- Never catch an error and return success; never swallow an error without logging or recovery.
- Never leak secrets, stack traces or internal identifiers to users; map internal errors to the stack's public error shape (`TBD: error response shape`).
- Compare errors by identity/type (sentinels, `errors.Is`-style helpers), never by message string.

## Structure

- Framework-native code first; readable before clever; no premature abstraction; follow the existing conventions of the project before inventing new ones.
- Controllers parse inputs, call services or models and return responses; no complex business logic.
- Models represent persisted data and relationships and hold simple domain behavior; no external API calls, no workflow orchestration.
- Services hold business workflows and coordinate models, repositories, adapters and jobs; they are named after use cases or business actions.
- Views / presenters / serializers format output; no persistence, no business decisions, no hidden data fetching.
- Repositories / DAOs only when queries become complex or repeated; never one per model by default.
- Design patterns only when they clarify intent and are documented for the feature (`docs/harness/features/feature-{name}.md`); a complexity fix is a refactor inside the pattern, never a pattern swap.
- Prefer the stack's zero-value / default-initialization idioms; constructors only when the zero value is not usable (`TBD: constructor convention`).
- Concurrency: read-only operations are assumed safe for concurrent use; mutating operations document their synchronization contract (`TBD: concurrency primitives`).
- Agents keep edits aligned with `architecture_rules.md`; no DDD/Clean terminology unless enabled there; no refactor into layers without explicit need.

## Interfaces

- Small interfaces: one to three methods, named after the capability they expose.
- An abstraction exists only when there are at least two real implementations or a documented test seam; never an interface per class by default.
- Composition over inheritance; embed/compose capabilities instead of building hierarchies.
- Interfaces are declared where they are consumed, not where they are implemented (`TBD: stack idiom`).

## Tests

- Tests live in a `tests` folder inside the folder of the code they cover, mirroring file names with the stack's test suffix (`TBD: suffix`), always respecting the folder/file naming rules of this document and `architecture_rules.md`:

```
src
|_controllers
    user_controller.{ext}
    app_controller.{ext}
    |_tests
        user_controller{test-suffix}.{ext}
        app_controller{test-suffix}.{ext}
```

- When the stack or the architecture does not allow tests next to the code, they live under `src/tests`, branching with folders that mirror the production tree:

```
src
|_controllers
|_repositories
|_services
|_tests
    |_controllers
    |    |_user_controller{test-suffix}.{ext}
    |    |_app_controller{test-suffix}.{ext}
    |_repositories
    |_services
```

- What is tested, the doubles allowed and the coverage focus come from `testing_expectation.md`; existing tests are immutable for agents (`persisted-tester`).

## Quality and Static Analysis

- The gate is `babylon-gardens`; every stage (format, static, security, deadcode, complexity, duplication, tests) must be green before a push. Tools for this stack: `TBD: list from the babylon-gardens stack table`.
- Thresholds (copied into `quality-baseline.json` by SETUP): cyclomatic complexity ≤ 10 per function, cognitive complexity ≤ 15 per function, duplication ≤ 3%, security findings of severity medium or higher fail, any leaked secret fails.
- A function allowed to exceed the complexity thresholds must carry a block comment stating why; the exception is recorded in the Quality Run report as Accepted Risk and decided by the user, never silenced.
- No inline suppressions, ignore files, baselines or threshold bumps by agents (`babylon-gate`); a false positive is reported as Accepted Risk with its reason.
- Dead code is removed, not commented out; unused exports, parameters and imports fail the gate.
