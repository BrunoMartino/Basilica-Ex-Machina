# CONTEXT.md — NestJS AI-First Architecture

Spec canónica. Nest continua a ser Nest. Import First é legibilidade do Dependency Graph, **não** substituição do DI.

> **O Nest continua responsável pela composição e pelo lifecycle. O código-fonte continua responsável por declarar explicitamente a arquitetura.**

> **NestJS com Explicit Dependency Architecture.**

## 1. Objetivo

Tornar o Dependency Graph navegável no código: sem descobrir providers por módulos distantes, tokens espalhados, factories mentais, ou carregar a app inteira para perceber uma feature.

## 2. Explicit Architecture, Automatic Runtime

DI permanece (`constructor(private readonly repo: UserRepository)`). Dependency **discovery** deve tender a zero.

```text
imports → constructor dependencies → module providers → Nest container → runtime
```

## 3. Não modificar o NestJS

Não fork, não container próprio, não alterar DI, module resolution, reflection, lifecycle, decorators, request scopes. Adaptação só via convenções, pastas, imports explícitos, módulos locais, lint, análise estática, grafo **derivado**.

## 4–5. Import First + constructor injection

Dependências visíveis por `import` + constructor. Evitar string tokens, módulos globais, factories opacas, service locator, `ModuleRef.get()` / `ModuleRef.resolve()` como DI normal.

## 6–7. Concrete Provider First; tokens são exceção

Registar a classe. **Não introduza um token quando a classe resolve.** Token (`Symbol`) só para múltiplas implementações, ports/adapters, config, plugins, externos — **local** à feature (`billing/payment.tokens.ts`), nunca `src/infrastructure/tokens/everything.tokens.ts`.

## 8–11. Modules, locality, globais, barrels

Module = composition boundary. Feature folder compreensível sozinha. `@Global()` só com justificação. Barrels não podem esconder dezenas de exports; preferir `from '@/users/user.service'`.

## 12–13. Dynamic modules e factories

`ConfigModule.forRoot()` ok. Não usar `forFeature` para esconder providers estáticos. Factories curtas (uma decisão de composição), nunca mini-containers.

## 14–15. Composition root e direção

```text
AppModule → Feature Module → Application Service → Domain/Port → Infrastructure Adapter
```

Proibido: Repository → Controller, Infrastructure → Feature Controller.

## 16–18. Feature-first

`src/<feature>/` + `app.module.ts` como root. **Proibido** `src/controllers|services|repositories|entities|modules` como layout primário.

Feature simples: ficheiros planos no folder. Feature complexa **pode** ter `application/`, `domain/`, `infrastructure/`, `presentation/` — não dividir à força. Isso **não** é DDD/Clean global.

`exports` = API pública. Não aceder a internals de outra feature.

## 19–20. Sem service locator / resolução escondida

`moduleRef.get`, `container.resolve`, `registry.get` são excepção justificada, não o caminho normal.

## 21–25. Grafo derivado + progressive disclosure

Fonte da verdade: código. IR: `graphify-out/graph.json` + `GRAPH_REPORT.md` (equivalente a `architecture.graph.json`). Não manter `ARCHITECTURE.md` manual que duplica o código.

Contexto por níveis: grafo → folder da feature → deps diretas → implementação. Formato denso (árvore de deps, exports, deps externas). Sem narrativa.

## 26–28. Imports são metadata; decorators ficam

Decorators Nest (`@Module`, `@Injectable`, `@Controller`, guards, interceptors) permanecem. Proibido `@AutoInjectEverything()` / `@Feature({ database, cache, messaging })` que esconde providers.

## 29–31. Shared, infra, ports

Módulos especializados (`DatabaseModule`, `CacheModule`), não `CommonModule` god-object. Infra encapsulada. Interfaces só em boundaries reais — sem `IUserService` / `IWhatever` por cerimónia.

## 32–34. Testes e DI

Unit: `new UserService(mockRepo)`. Integração: `Test.createTestingModule({ imports: [UsersModule] })`. E2E: app Nest. **Não** substituir DI por `new Service()` na aplicação. TestingModule não se abandona.

## 35. Checklist de provider

Injetável? Dep visível no constructor? No module da feature? Export necessário? Token necessário? Import direto possível? Um agente acha a origem em 1–2 ficheiros? Se não → simplificar.

## 36. Métricas (objectivo)

| Métrica | Alvo |
|---------|------|
| Dependency Discovery Depth | ≈ 1–2 ficheiros |
| Hidden / Global / Dynamic Resolution Rate | ≈ 0% (excepto infra justificada) |
| Feature Context Size | pequeno e previsível |

## 37–38. AI-Friendly + regra de ouro

Agente localiza feature, entrypoint, deps, deps externas, boundaries e altera comportamento **sem** carregar a app. Entre duas soluções equivalentes, preferir a que o grafo se lê em imports + constructors + `@Module`. Otimizar para menos inferência/navegação/contexto, mais localidade — não para menos linhas.

## 39. Não fazer

Remover DI; container paralelo; decorators mágicos para IA; `new` em todo o lado; eliminar Modules/decorators; duplicar o grafo à mão; docs arquiteturais que divergem do código.

## 40–41. Target

Nest runtime (DI, lifecycle, modules, HTTP) + arquitetura explícita (imports, constructors, módulos locais) + grafo estático (Graphify) + contexto progressivo = **AI-First NestJS**.
