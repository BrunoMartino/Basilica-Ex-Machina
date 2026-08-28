<p align="center">
  <img src="assets/michelangelo-dev-toolkit.png" alt="Michelangelo-Dev-Toolkit" width="480" />
</p>

# Michelangelo-Dev-Toolkit

> *«O código é o produto residual da teoria da construção do projeto.»*  
> — frase adaptada de Peter Naur

Compilado de **skills**, **rules**, **agents** e **boilerplates** para iniciar um projeto com o **Claude Code** ou o **Cursor** já orientado por convenções, guardrails e fluxos de trabalho repetíveis.

Não é uma aplicação executável: é um **kit de arranque** que se copia ou adapta para um repositório novo, para dar contexto consistente ao agente desde o primeiro commit.

| IDE / CLI | Pasta do kit | Extensão das rules |
|-----------|--------------|--------------------|
| **Claude Code** | `.claude/` | `.md` |
| **Cursor** | `.cursor/` | `.mdc` |

O conteúdo (skills, agents, regras) é o mesmo nos dois lados; só muda o caminho e a extensão das rules.

**Repositório:** [BrunoMartino/Michelangelo-Dev-Toolkit](https://github.com/BrunoMartino/Michelangelo-Dev-Toolkit)

[English](README.en.md)

## O que inclui

### Skills (`.claude/skills/` ou `.cursor/skills/`)

Instruções especializadas que o agente pode invocar em tarefas concretas:

| Skill | Função |
|-------|--------|
| `harness-create` | Cria os docs harness interactivamente (perguntas só para o que falta) e instala a rule `all-for-harness` |
| `tester` | TDD: testes a falhar primeiro, depois código mínimo; triangulação em 4 eixos (happy, boundary, negative, adversarial); handoff Green em `docs/tdd/fase{N}.md` + `fase{N}Task.md` |
| `design-patterns-coder` | Padrões GoF só a partir da documentação do desenvolvedor (docs-mcp `gof-design-patterns`; fallback no GitHub); composição sobre herança |
| `code-commenter` | Comentários e documentação em bloco para lógica não trivial |
| `design-docs-creator` | TDD técnico: specs, RFCs e propostas de arquitetura via descoberta interactiva; fases de implementação em Red/Green |
| `coupling-analizer` | Análise de acoplamento entre módulos (força, distância, volatilidade) |
| `legacy-explainer` | Graphify: explica codebase legado E regenera/actualiza o grafo (`graphify-out/`); preenche os docs harness |
| `cistina-arch` | Companion do Graphify: HTML interactivo ao nível de ficheiro com trechos complexos visíveis; AskQuestion para mais profundidade; órfãos e dead code no canvas |
| `get-that-task` | Consulta Jira: issues abertas do utilizador e não atribuídas |
| `get-my-tools` | Inventaria e instala skills, rules e docs deste toolkit no projeto actual (útil em dev containers) |
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
| `create-minio-docker` | Gera MinIO (Dockerfile + docker-compose) e `install.md` para deploy no Coolify (API/Console, buckets, credenciais) |
| `database-postgres-mcp` | Instala o MCP-explorer-for-Postgress e regista-o na config MCP do agente |

Cada skill vive numa pasta com `SKILL.md` (e, quando aplicável, `examples.md`).

### Controspia — bloco de segurança (`.claude/skills/controspia/` ou `.cursor/skills/controspia/`)

Skills de cibersegurança agrupadas num bloco próprio, com **README dedicado** ([PT](.claude/skills/controspia/README.md) · [EN](.claude/skills/controspia/README-ENG.md)) que explica cada skill, quando usar e quando não usar:

| Skill | Função |
|-------|--------|
| `owasp-audit` | Auditoria de código pelo OWASP Top 10 (2021), A01–A10, com verificação de correcções em runtime |
| `api-audit` | OWASP API Security Top 10 (2023) endpoint a endpoint (REST, GraphQL, RPC): BOLA, BFLA, mass assignment, SSRF |
| `container-audit` | Dockerfile, Helm/Kustomize, manifests Kubernetes e runtime: privilégios, segredos, PSS, network policies, RBAC |
| `incident-triage` | Resposta a incidentes (NIST SP 800-61): classificação, contenção, preservação de prova, IOCs |
| `finding-triage` | Um finding → disposição defensável (Fixed / Deferred / Accepted Risk) com plano de mitigação ou risco aceite |
| `offensive/recon` | Enumeração de superfície de ataque (passiva e activa) em alvos autorizados |
| `offensive/osint-recon` | Inteligência de fontes abertas: infraestrutura, organização, e-mails, documentos, threat intel |
| `offensive/web-pentest` | Pentest web black-box / grey-box em 9 fases (Burp Suite / OWASP ZAP) |
| `offensive/red-legio` | Engajamento de red team autorizado: RoE, assumed breach, emulação ATT&CK, deconflicção, debrief |
| `report/security-comms` | Traduz trabalho de segurança para board, executivos, engenharia, clientes, legal |

As skills em `offensive/` **exigem autorização explícita do alvo** — abrem com verificação de autorização e recusam alvos ambíguos. Origem: [briiirussell/cybersecurity-skills](https://github.com/briiirussell/cybersecurity-skills) (MIT), com selecção parcial e `red-team-engagement` renomeada para `red-legio`.

### Agents (`.claude/agents/` ou `.cursor/agents/`)

Subagentes especializados (spawnados pelo agente principal conforme a `description`):

| Agent | Função |
|-------|--------|
| `test-writer` | TDD Red/Green: só sob pedido explícito de fase Red, Green ou (raramente) ambas; usa sempre as skills `tester` e `design-patterns-coder`; cobertura >50% global e 80–90% no código crítico |
| `security-auditor` | Análise de vulnerabilidades exploráveis em backends (APIs, auth, DB, integrações); foco em impacto real, não em falsos positivos teóricos |

### Rules

Regras sempre ativas que orientam o comportamento do agente:

| Claude Code | Cursor |
|-------------|--------|
| `.claude/rules/*.md` | `.cursor/rules/*.mdc` |

- **`all-for-harness`** — os docs em `docs/harness/` são vinculativos: o agente lê-os antes de alterações de arquitetura, testes, deploy, domínio ou features, segue-os em caso de conflito com "best practices" genéricas e aplica o fluxo obrigatório docs → código → graphify. Gate de features: nenhuma feature nova sem `docs/harness/features/feature-{name}.md` com as 4 respostas do utilizador. É instalada junto com os docs pela skill `harness-create`.
- **`graphify-first`** — antes de inferir arquitectura/fluxos/dependências, consultar o Graphify (`graphify-out/`) primeiro; se indisponível, perguntar ao utilizador.
- **`persisted-tester`** — testes já existentes no repositório não podem ser removidos nem alterados pelo agente; cobrir mudanças com testes novos e avisar o utilizador dos obsoletos.
- **`less-talk`** — proíbe explicações não pedidas, extras de escopo e desperdício de tokens em modo Agent/Ask; modo Plan mantém profundidade.
- **`dont-write-env`** — nunca editar `.env`; apenas `.env.example`.
- **`python-uv-package-manager`** — em projetos Python, usar sempre `uv` (`uv add` / `uv run` / `uv sync`); proíbe pip/poetry/conda.
- **`api-pydantic-schemas`** — endpoints de API com schemas Pydantic explícitos de request/response; sem `dict`/`Any` crus.

### Harness docs — boilerplate (`docs/harness/`)

Templates para definir as regras do projeto. Copie cada ficheiro `*_template.md`, remova o sufixo `_template` e preencha para o seu contexto:

| Template | Documento final | Conteúdo |
|----------|-----------------|----------|
| `architeture_rules_template.md` | `architecture_rules.md` | Estilo arquitetural (MVC por defeito), módulos, padrões permitidos |
| `coding_conventions_template.md` | `coding_convention.md` | Estilo de código e convenções MVC |
| `forbidden_patterns_template.md` | `forbidden_patterns.md` | Anti-padrões e arquiteturas proibidas por defeito |
| `testing_expectations_template.md` | `testing_expectation.md` | Expectativas de testes e cobertura |
| `deployment_rules_template.md` | `deployment_rules.md` | Regras de deploy e ambientes |
| `domain_invariants_template.md` | `domain_invariantes.md` | Invariantes e regras de negócio |
| `operational_constraints_template.md` | `operational_constraints.md` | Limites operacionais (SLA, quotas, etc.) |
| `features_template.md` | `features/feature-{name}.md` | Um ficheiro por feature: descrição, problema, solução + trade-offs, exemplo/contexto (4 respostas do utilizador); relações entre features |

Estes documentos são a **fonte de verdade** que skills como `tester`, `design-patterns-coder`, `audit-guardsman` e `data-guardsman` referenciam antes de implementar. Os design docs do projeto derivam do harness de features.

### Outros boilerplates

- **`docs/testsReadme.md`** — catálogo de testes (tabela para registar suites, ficheiros e como correr isoladamente).
- **`docs/tdd/`** — criado pela skill `tester` / agente `test-writer` durante Red: `fase{N}.md` (plano Green) e `fase{N}Task.md` (checklist).

## Como usar (Claude Code)

1. **Copie** para o repositório de destino:
   - `.claude/skills/`
   - `.claude/rules/`
   - `.claude/agents/` (opcional)
   - `docs/harness/*_template.md`
   - `docs/testsReadme.md` (opcional)

   **Alternativa (dev container / sem clone local):** invoque a skill `get-my-tools` no Claude Code para listar e instalar itens a partir do GitHub.

2. **Materialize os harness docs**: invoque `harness-create` (greenfield — faz perguntas e gera cada doc a partir dos templates, incluindo `features/`, instalando a rule `all-for-harness`), ou renomeie e preencha os templates manualmente.

3. **Ajuste** skills e rules ao stack do projeto (Jira, npm, Graphify, uv/Python, etc.) — muitas skills assumem integrações MCP (Atlassian, Snyk, docs-mcp, etc.).

4. **Opcional — projeto legado**: invoque `legacy-explainer` para gerar documentação inicial a partir do código existente.

5. **Opcional — decisões de arquitectura**: invoque `design-docs-creator` antes de features significativas; use `coupling-analizer` para avaliar acoplamento; use `design-patterns-coder` na implementação Green quando houver padrões GoF.

6. **TDD**: peça explicitamente fase **Red** ou **Green** (ou ambas) ao agente `test-writer`, que segue `tester` + `design-patterns-coder`.

7. **Mantenha** `docs/harness/` e o grafo actualizados quando mudar código, arquitetura ou regras de domínio — invoque `legacy-explainer` após alterações relevantes; as rules `all-for-harness` e `graphify-first` dependem disso.

## Como usar (Cursor)

Mesmos passos, trocando `.claude/` por `.cursor/` e rules `.md` por `.mdc`. A skill `get-my-tools` do lado Cursor instala sob `.cursor/`.

## Estrutura do repositório

```
.
├── .claude/                 # Kit Claude Code
│   ├── agents/
│   ├── rules/               # *.md
│   └── skills/
│       └── controspia/      # Bloco de segurança (+ offensive/, report/)
├── .cursor/                 # Kit Cursor (espelho)
│   ├── agents/
│   ├── rules/               # *.mdc
│   └── skills/              # espelho, inclui controspia/
├── docs/
│   ├── harness/             # Templates (incl. features)
│   └── testsReadme.md
└── README.md
```

A pasta `drafts/` contém rascunhos em elaboração e **não** faz parte do kit estável (está no `.gitignore`).

## Princípios

- **MVC simples por defeito** — sem DDD, Clean/Hexagonal ou CQRS global salvo pedido explícito (ver `forbidden_patterns`).
- **Documentação antes de mudanças estruturais** — o agente lê harness docs, não inventa regras; features exigem as 4 respostas do utilizador.
- **Padrões GoF só da doc do projecto** — via `design-patterns-coder` / docs-mcp, nunca da memória do modelo.
- **Skills com escopo fechado** — cada uma cobre um fluxo (TDD, padrões, auditoria, dependências, Jira, …).
- **Boilerplate editável** — templates genéricos; o projeto concreto preenche os detalhes.
- **Paridade Claude / Cursor** — o mesmo kit nos dois agentes; mantenha as pastas alinhadas ao alterar skills ou rules.

## Licença

Defina a licença adequada ao copiar este kit para os seus repositórios.
