# Personal Harness Engineering

Compilado de **skills**, **rules** e **boilerplates** para iniciar um projeto com o Cursor (ou outro agente de código) já orientado por convenções, guardrails e fluxos de trabalho repetíveis.

Não é uma aplicação executável: é um **kit de arranque** que se copia ou adapta para um repositório novo, para dar contexto consistente ao agente desde o primeiro commit.

## O que inclui

### Skills (`.cursor/skills/`)

Instruções especializadas que o agente pode invocar em tarefas concretas:

| Skill | Função |
|-------|--------|
| `tester` | TDD: testes a falhar primeiro, depois código mínimo (unitários e integração) |
| `code-commenter` | Comentários e documentação em bloco para lógica não trivial |
| `legacy-explainer` | Mapeamento de codebase legado (Graphify) e preenchimento dos docs harness |
| `get-that-task` | Consulta Jira: issues abertas do utilizador e não atribuídas |
| `dependency-guardsman` | Segurança e licenças em dependências npm (Trivy, allow/block list) |
| `data-guardsman` | Criptografia, classificação de dados e boas práticas de segredos |
| `audit-guardsman` | Logs de auditoria JSON em operações privilegiadas |

Cada skill vive numa pasta com `SKILL.md` (e, quando aplicável, `examples.md`).

### Rules (`.cursor/rules/`)

Regras sempre ativas que orientam o comportamento do agente:

- **`harness-docs.mdc`** — antes de alterações de arquitetura, testes, deploy ou domínio, o agente deve ler os documentos correspondentes em `docs/harness/`.

### Harness docs — boilerplate (`docs/harness/`)

Templates para definir as regras do projeto. Copie cada ficheiro `*_template.md`, remova o sufixo `_template` e preencha para o seu contexto:

| Template | Documento final | Conteúdo |
|----------|-------------------|----------|
| `architeture_rules_template.md` | `architecture_rules.md` | Estilo arquitetural (MVC por defeito), módulos, padrões permitidos |
| `coding_conventions_template.md` | `coding_convention.md` | Estilo de código e convenções MVC |
| `forbidden_patterns_template.md` | `forbidden_patterns.md` | Anti-padrões e arquiteturas proibidas por defeito |
| `testing_expectations_template.md` | `testing_expectation.md` | Expectativas de testes e cobertura |
| `deployment_rules_template.md` | `deployment_rules.md` | Regras de deploy e ambientes |
| `domain_invariants_template.md` | `domain_invariantes.md` | Invariantes e regras de negócio |
| `operational_constraints_template.md` | `operational_constraints.md` | Limites operacionais (SLA, quotas, etc.) |

Estes documentos são a **fonte de verdade** que skills como `tester`, `audit-guardsman` e `data-guardsman` referenciam antes de implementar.

### Outros boilerplates

- **`docs/testsReadme.md`** — catálogo de testes (tabela para registar suites, ficheiros e como correr isoladamente).

## Como usar num projeto novo

1. **Copie** para o repositório de destino:
   - `.cursor/skills/`
   - `.cursor/rules/`
   - `docs/harness/*_template.md`
   - `docs/testsReadme.md` (opcional)

2. **Materialize os harness docs**: renomeie e preencha os templates (por exemplo, `architecture_rules.md`, `coding_convention.md`, …).

3. **Ajuste** skills e rules ao stack do projeto (Jira, npm, Graphify, etc.) — muitas skills assumem integrações MCP (Atlassian, Snyk, etc.).

4. **Opcional — projeto legado**: invoque `legacy-explainer` para gerar documentação inicial a partir do código existente.

5. **Mantenha** `docs/harness/` atualizado quando mudar arquitetura, testes ou regras de domínio; a rule `harness-docs` depende disso.

## Estrutura do repositório

```
.
├── .cursor/
│   ├── rules/           # Regras persistentes do agente
│   └── skills/          # Skills invocáveis (tester, guardsman, …)
├── docs/
│   ├── harness/         # Templates de documentação do projeto
│   └── testsReadme.md   # Boilerplate do catálogo de testes
└── README.md
```

A pasta `drafts/` contém rascunhos em elaboração e **não** faz parte do kit estável (está no `.gitignore`).

## Princípios

- **MVC simples por defeito** — sem DDD, Clean/Hexagonal ou CQRS global salvo pedido explícito (ver `forbidden_patterns`).
- **Documentação antes de mudanças estruturais** — o agente lê harness docs, não inventa regras.
- **Skills com escopo fechado** — cada uma cobre um fluxo (TDD, auditoria, dependências, Jira, …).
- **Boilerplate editável** — templates genéricos; o projeto concreto preenche os detalhes.

## Licença

Defina a licença adequada ao copiar este kit para os seus repositórios.
