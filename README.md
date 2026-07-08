# Personal Harness Engineering

Compilado de **skills**, **rules** e **boilerplates** para iniciar um projeto com o Cursor (ou outro agente de código) já orientado por convenções, guardrails e fluxos de trabalho repetíveis.

Não é uma aplicação executável: é um **kit de arranque** que se copia ou adapta para um repositório novo, para dar contexto consistente ao agente desde o primeiro commit.

## O que inclui

### Skills (`.cursor/skills/`)

Instruções especializadas que o agente pode invocar em tarefas concretas:

| Skill | Função |
|-------|--------|
| `harness-create` | Cria os docs harness interactivamente (perguntas só para o que falta) e instala a rule `harness-docs` |
| `tester` | TDD: testes a falhar primeiro, depois código mínimo; triangulação em 4 eixos (happy, boundary, negative, adversarial) |
| `code-commenter` | Comentários e documentação em bloco para lógica não trivial |
| `design-docs-creator` | TDD técnico: specs, RFCs e propostas de arquitetura via descoberta interactiva; fases de implementação em Red/Green |
| `coupling-analizer` | Análise de acoplamento entre módulos (força, distância, volatilidade) |
| `legacy-explainer` | Graphify: explica codebase legado E regenera/actualiza o grafo (`graphify-out/`); preenche os docs harness |
| `get-that-task` | Consulta Jira: issues abertas do utilizador e não atribuídas |
| `get-my-tools` | Inventaria e instala skills, rules e docs de `personal_harness_eng` no projeto actual (útil em dev containers) |
| `dependency-guardsman` | Segurança em dependências npm: scan de vulnerabilidades, supply-chain (typosquatting, install scripts) e licenças |
| `data-guardsman` | Criptografia, classificação de dados, gestão de segredos e acesso a dados injection-safe |
| `audit-guardsman` | Logs de auditoria JSON em operações privilegiadas, com protecção contra log injection e sem PII |
| `wordpress-developer` | Scan e mitigação das vulnerabilidades comuns de WordPress via tema local (xmlrpc, feeds, comentários, CORS, …) |
| `shopify-developer` | Referência completa de desenvolvimento Shopify (Liquid, temas OS 2.0, GraphQL, Hydrogen, Functions) |
| `learn-live-canvas` | Docs e hooks de LiveCanvas + Picostrap 5 a partir de cache local sincronizada |
| `node-express-project` | Scaffold Node+Express+TS (npm/bun, Zod, Prisma/Drizzle, paralelismo, Jest) |
| `node-fastify-project` | Scaffold Node+Fastify+TS (npm/bun, Zod, Prisma/Drizzle, paralelismo, Jest) |
| `nest-project` | Scaffold NestJS optimizado (SWC/Vite, validadores, Prisma/Drizzle, segurança, Jest) |
| `laravel-project` | Instalação Laravel optimizada com API (Sanctum), Eloquent, FormRequests, PHPUnit e strict types (Larastan) |
| `django-project` | Django API (DRF) ou monolito com Vue; pytest, Pydantic, SQLAlchemy, pandas/numpy opcionais |
| `django-fastapi-project` | Django + FastAPI montados no mesmo ASGI; pytest, Pydantic, SQLAlchemy |
| `make-etl-project` | Projeto ETL Python (SQLAlchemy, pandas, numpy) com bancos source/target e pytest por estágio E/T/L |
| `database-postgres-mcp` | Instala o MCP-explorer-for-Postgress e regista-o em `.cursor/mcp.json` |

Cada skill vive numa pasta com `SKILL.md` (e, quando aplicável, `examples.md`).

### Rules (`.cursor/rules/`)

Regras sempre ativas que orientam o comportamento do agente:

- **`harness-docs.mdc`** — os docs em `docs/harness/` são vinculativos: o agente lê-os antes de alterações de arquitetura, testes, deploy ou domínio e segue-os em caso de conflito com "best practices" genéricas. É instalada junto com os docs pela skill `harness-create`.
- **`less-talk.mdc`** — proíbe explicações não pedidas, extras de escopo e desperdício de tokens em modo Agent/Ask; modo Plan mantém profundidade.
- **`dont-write-env.mdc`** — nunca editar `.env`; apenas `.env.example`.

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

   **Alternativa (dev container / sem acesso ao repo local):** invoque `get-my-tools` para listar e instalar itens directamente a partir do GitHub.

2. **Materialize os harness docs**: invoque `harness-create` (greenfield — faz perguntas e gera cada doc a partir dos templates, instalando a rule `harness-docs`), ou renomeie e preencha os templates manualmente.

3. **Ajuste** skills e rules ao stack do projeto (Jira, npm, Graphify, etc.) — muitas skills assumem integrações MCP (Atlassian, Snyk, etc.).

4. **Opcional — projeto legado**: invoque `legacy-explainer` para gerar documentação inicial a partir do código existente.

5. **Opcional — decisões de arquitectura**: invoque `design-docs-creator` antes de features significativas; use `coupling-analizer` para avaliar acoplamento entre módulos.

6. **Mantenha** `docs/harness/` e o grafo actualizados quando mudar código, arquitetura ou regras de domínio — invoque `legacy-explainer` após alterações relevantes (actualiza o grafo e refresca os docs); a rule `harness-docs` depende disso.

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
