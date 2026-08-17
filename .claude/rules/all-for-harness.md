---
description: Harness docs vinculantes; em Plan, to-do de feature é AskQuestion das 4 respostas — não completar até o usuário responder
alwaysApply: true
---

# All for Harness

Esta rule é instalada junto com os documentos `docs/harness/` (criados pela skill `harness-create`, ou pela `legacy-explainer` em projetos brownfield). Quando existem, **o projeto segue os harness docs — são vinculantes, não sugestões.**

| Tipo de mudança | Ler |
|-----------------|-----|
| Arquitetura | `docs/harness/architecture_rules.md` |
| Estilo / convenções de código | `docs/harness/coding_convention.md` |
| Anti-padrões | `docs/harness/forbidden_patterns.md` |
| Testes | `docs/harness/testing_expectation.md` |
| Deployment | `docs/harness/deployment_rules.md` |
| Lógica de domínio | `docs/harness/domain_invariantes.md` |
| Operações | `docs/harness/operational_constraints.md` |
| Nova feature / mudança de feature | `docs/harness/features/feature-{name}.md` (um arquivo por feature) |

## Workflow (docs → código → graphify)

1. Identifique quais categorias de mudança a tarefa toca e leia **antes** de planejar ou editar todos os docs listados para essas categorias.
2. Reflita a mudança primeiro em `docs/harness/` e na documentação relevante.
3. Só depois gere/altere o código, derivado da documentação atualizada, aplicando as constraints dos docs.
4. Nunca ajuste a documentação a partir do código; o código nasce dos docs.

## Enforcement

- Se uma "best practice" genérica conflitar com um harness doc, **o harness doc vence**. Desvie apenas se o usuário sobrescrever explicitamente na conversa atual — e diga que está desviando.
- Não enfraqueça, ignore nem reescreva silenciosamente constraints do harness (invariantes, forbidden patterns, expectativas de teste). Mudanças em `docs/harness/*` exigem pedido explícito do usuário.
- Se um doc estiver faltando, diga isso e prossiga só com o que existe — não invente regras de projeto.
- Se a tarefa violar uma constraint do harness e o usuário não tiver sobrescrito, pare e reporte o conflito em vez de implementar.
- **Gate de features**: nenhuma feature nova é implementada sem o respectivo `docs/harness/features/feature-{name}.md` com as 4 respostas dadas pelo usuário (descrição, problema, solução + trade-offs, exemplo/contexto). Se o usuário pedir a implementação direta, instrua primeiro a criação correta do arquivo pelo chat; só implemente depois. O agente nunca preenche as 4 respostas sozinho.
- Os design docs do projeto derivam obrigatoriamente do harness de features.

## Plan mode — escrita de features

Quando o plano inclui criar ou preencher `docs/harness/features/feature-{name}.md`:

1. O to-do dessa feature é **abrir AskQuestion** com as 4 perguntas obrigatórias (uma feature de cada vez). Não é “gravar o ficheiro”.
2. Esse to-do **não é `completed`** até o usuário responder as 4 perguntas nesta conversa. “Implement the plan” / “completa todos os to-dos” **não** dispensa a espera.
3. Proibido inferir, complementar ou copiar as 4 respostas de `mcpContext`, README, código ou do próprio plano. Sem resposta no AskQuestion, a feature fica **pending** — não se escreve `feature-{name}.md`.
4. Só no turno **seguinte** às 4 respostas se grava o ficheiro (respostas verbatim) e se marca o to-do complete.
