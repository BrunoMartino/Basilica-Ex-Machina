---
description: NestJS Explicit Dependency Architecture (AI-First). Binding em projetos Nest; harness-create e legacy-explainer devem encodá-la.
alwaysApply: false
---

# Nest Conventions

Binding quando o alvo é Nest (`@nestjs/core`, ou esta rule, ou `CONTEXT.md` AI-First). Spec: `CONTEXT.md` na raiz (skill `nest-project`). Em conflito com MVC genérico / “não usar DDD”, **esta rule vence** no alvo Nest. Pastas `application/domain/infrastructure` **por feature complexa** não são DDD/Clean global.

## Agentes (sempre)

1. Nest permanece Nest: DI, modules, decorators, TestingModule. Não fork, não container próprio, não `new Service()` na app.
2. **Import First** + constructor injection. Classe como provider. Token/`Symbol` só com boundary real e **local** à feature.
3. Feature-first (`src/<feature>/`). `AppModule` = composition root. Sem layout `controllers/services/repositories`. Sem `@Global()` e sem `ModuleRef.get()`/`resolve()` como DI normal.
4. Progressive disclosure: Graphify (`graphify-out/`) → folder da feature → deps diretas. Não despejar a app. Grafo é IR **derivado**; código é a fonte da verdade. Não criar `ARCHITECTURE.md` manual.
5. Novo provider: origem localizável em 1–2 ficheiros; senão simplificar.

## harness-create (greenfield Nest)

Não perguntar MVC vs outro. Preencher `architecture_rules`, `coding_convention`, `forbidden_patterns` e `testing_expectation` a partir desta rule + `CONTEXT.md`. Instalar esta rule com `alwaysApply: true` (`.claude/rules/` e `.cursor/rules/`). Manter fluxo unidirecional do template.

## legacy-explainer (brownfield Nest)

Graphify = `architecture.graph.json`. Explicar por feature. Nos templates, encodar estas convenções e marcar violações (`@Global`, tokens distantes, god modules, service locator). Não inventar narrativa que o grafo já cobre.
