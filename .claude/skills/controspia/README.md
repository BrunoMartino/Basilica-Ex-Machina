# Controspia — bloco de segurança do harness

Conjunto fechado de **skills de cibersegurança** incorporadas neste toolkit: auditoria de código e infraestrutura, resposta a incidentes, triagem de findings, operações ofensivas autorizadas e comunicação de segurança.

Não é o catálogo completo do projecto de origem — só as skills escolhidas para este harness.

[English](README-ENG.md)

## Estrutura

```
controspia/
├── owasp-audit/          # OWASP Top 10 (2021) sobre o código-fonte
├── api-audit/            # OWASP API Security Top 10 (2023) por endpoint
├── container-audit/      # Dockerfile, Helm/Kustomize, Kubernetes, runtime
├── incident-triage/      # Resposta a incidentes (NIST SP 800-61)
├── finding-triage/       # Um finding → disposição defensável
├── offensive/            # ⚠️ exige autorização explícita do alvo
│   ├── recon/            # Enumeração de superfície de ataque
│   ├── osint-recon/      # Inteligência de fontes abertas
│   ├── web-pentest/      # Pentest web black-box / grey-box
│   └── red-legio/        # Engajamento de red team
├── report/
│   └── security-comms/   # Traduzir segurança para audiências não técnicas
└── README.md / README-ENG.md
```

Cada skill vive numa pasta com o seu `SKILL.md`, no formato normal do harness. As subpastas `offensive/` e `report/` são organizacionais: separam o que exige autorização formal e o que é entregável de comunicação.

> Se o agente não descobrir skills em subpastas na sua versão, copie a pasta-folha (ex.: `offensive/web-pentest/`) directamente para `.claude/skills/` — o conteúdo do `SKILL.md` não muda.

## Como usar

1. Copie `controspia/` para `.claude/skills/` (Claude Code) ou `.cursor/skills/` (Cursor) do projecto de destino. As duas cópias deste repositório são idênticas.
2. Invoque pelo nome (`/owasp-audit`, `/finding-triage`, …) ou descreva a tarefa — cada `SKILL.md` traz na `description` os gatilhos que a activam ("OWASP", "BOLA", "incident response", "triage this finding", …).
3. Dê contexto de stack e prioridades. As skills trazem a metodologia e o formato de relatório; o que é crítico no seu domínio vem de você e de `docs/harness/`.
4. As skills ofensivas param e pedem prova de autorização antes de qualquer passo activo. Isso é intencional — não contorne.

### Relação com o resto do harness

- `docs/harness/` continua vinculante (rule `all-for-harness`): severidade e prioridade de findings devem ser lidas contra `domain_invariantes.md`, `operational_constraints.md` e `forbidden_patterns.md`.
- Antes de inferir arquitectura ou fluxos durante uma auditoria, vale a rule `graphify-first` — consulte o grafo, depois abra os ficheiros que ele indicou.
- Correcções de produção que precisem de cobertura seguem `persisted-tester`: testes novos, os antigos ficam intactos.
- Complementos já existentes no toolkit: agente `security-auditor` (vulnerabilidades exploráveis em backend), `dependency-guardsman` (CVEs e supply-chain npm), `data-guardsman` (cripto, segredos, acesso a dados), `audit-guardsman` (logs de auditoria), `wordpress-developer` (superfície WordPress).

## Skills de auditoria e resposta

### `owasp-audit` — auditoria OWASP Top 10 (2021)

**O que faz.** Varredura de código-fonte pelas dez categorias (A01 controlo de acesso → A10 SSRF), com padrões de grep concretos por categoria, verificação de correcções em runtime e um segundo passe de revisão. Classifica cada finding em **Fixed / Deferred / Accepted Risk** — a convenção que as outras skills reutilizam.

**Quando usar.** Revisão de segurança de uma codebase ou de um PR grande; "procura vulnerabilidades", IDOR, SQL injection, XSS, SSRF, misconfiguração.

**Quando não usar.** Se a superfície é só de API, `api-audit` é mais direto; contentores e Kubernetes são de `container-audit`; um único finding já conhecido vai para `finding-triage`.

### `api-audit` — OWASP API Security Top 10 (2023)

**O que faz.** Passe endpoint a endpoint sobre REST, GraphQL e RPC: BOLA, autenticação, BOPLA/BFLA e exposição excessiva de dados, consumo de recursos, fluxos de negócio sensíveis, SSRF, misconfiguração, inventário de versões e consumo inseguro de APIs de terceiros. Inclui secções específicas de GraphQL e de REST.

**Quando usar.** Existe contrato de API (OpenAPI, schema GraphQL, router) e quer cobertura por endpoint, incluindo rotas-irmãs que escapam ao guard principal.

**Quando não usar.** Como substituto do sweep de codebase — as duas skills cruzam-se e são complementares, não alternativas.

### `container-audit` — contentores e orquestração

**O que faz.** Audita Dockerfile (imagem base e supply chain, exposição de segredos em build, postura de runtime), manifests Kubernetes (Pod Security Standards e admission via OPA Gatekeeper / Kyverno, network policies, segredos, RBAC, limites de recursos, política de imagem) e a camada de runtime.

**Quando usar.** Há Docker, Helm, Kustomize ou Kubernetes no caminho de deploy; hardening de imagem, rootless, distroless.

**Quando não usar.** IAM e serviços gerenciados de cloud, e CVEs de pacotes da aplicação, estão fora — o primeiro não está neste bloco, o segundo é do `dependency-guardsman`.

### `incident-triage` — resposta a incidentes (NIST SP 800-61)

**O que faz.** Conduz a triagem: classificação e severidade, contenção inicial, preservação de prova (ordem de volatilidade), análise inicial, extracção de IOCs e um relatório de incidente com estado (Triage → Contained → Analyzing → Resolved).

**Quando usar.** Agora, com algo a acontecer: acesso suspeito, malware, credenciais expostas, "fomos comprometidos".

**Quando não usar.** Findings em estado estacionário (scanner, auditoria, advisory) — isso é `finding-triage`. A comunicação a clientes e stakeholders que o incidente gera é `report/security-comms`.

### `finding-triage` — um finding, uma disposição

**O que faz.** Cinco passos: reescrever o finding em linguagem própria, verificar se é verdadeiro (falso positivo, alcançabilidade), severidade contextual em vez de nota de scanner, escolher a disposição e escrever o texto que a sustenta — com campos de ticket, dono e prazo.

**Quando usar.** "Isto é real?", "vale corrigir?", plano de mitigação, justificação de risco aceite, controlos compensatórios, CVSS contextualizado.

**Quando não usar.** Para varrer a codebase inteira (use as skills de auditoria) e para fogo activo (use `incident-triage`).

## `offensive/` — só com autorização explícita

Estas quatro skills abrem com uma verificação de autorização e recusam alvos ambíguos. Use-as em pentests contratados, programas de bug bounty com escopo publicado, CTFs e laboratórios próprios. Guarde o escopo, a janela e a autorização por escrito antes de começar.

### `offensive/recon` — enumeração de superfície

**O que faz.** Recon passivo (DNS, certificados, subdomínios, fingerprint de tecnologias) e, só com autorização explícita, a fase activa; termina num mapa de superfície de ataque com prioridades.

**Quando usar.** Primeira fase de um pentest ou bug bounty autorizado, mapeamento de footprint externo.

**Quando não usar.** Contra alvos que não são seus e não têm escopo publicado.

### `offensive/osint-recon` — inteligência de fontes abertas

**O que faz.** Recolha e correlação de fontes públicas: infraestrutura e domínio, organização, e-mails e usernames, metadados de documentos, threat intel. Inclui verificação de ética antes da recolha.

**Quando usar.** Avaliação de footprint digital, investigação de um domínio, threat intelligence, contexto para engenharia social autorizada.

**Quando não usar.** Perfilamento de pessoas sem propósito legítimo e documentado. É o par investigativo do `recon`, não um substituto.

### `offensive/web-pentest` — pentest de aplicação web

**O que faz.** Nove fases sobre um alvo vivo: configuração e deployment, gestão de identidade, autenticação, **autorização** (a fase de maior rendimento), sessão, validação de input, tratamento de erros, lógica de negócio e client-side. Fluxos de Burp Suite e OWASP ZAP, e formato de relatório com reprodução.

**Quando usar.** Já tem lista de alvos, credenciais (ou acesso convidado) e autorização — idealmente depois do `recon`.

**Quando não usar.** Para ler código (é `owasp-audit`) ou para testar detecção e resposta (é `red-legio`).

### `offensive/red-legio` — engajamento de red team

**O que faz.** Planeamento e execução de um engajamento autorizado, de várias semanas e orientado a objectivos: três modelos (externo, assumed breach, purple), pré-engajamento com sponsor executivo e rules of engagement, plano de emulação ATT&CK, deconflicção com a equipa azul, execução e debrief com acompanhamento das recomendações até ao fecho.

**Quando usar.** O objectivo é testar se a detecção e a resposta funcionam, não encontrar vulnerabilidades.

**Quando não usar.** Se o objectivo é "encontrar vulnerabilidades", use `web-pentest` ou uma skill de auditoria. É a skill com a postura de recusa mais forte do bloco.

> Renomeada a partir de `red-team-engagement` no projecto de origem: a pasta e o campo `name` do `SKILL.md` são `red-legio`. Invoque por esse nome.

## `report/` — comunicação

### `report/security-comms` — traduzir segurança para quem decide

**O que faz.** Escreve (ou revê) entregáveis para sete audiências — board, liderança executiva, liderança de engenharia, engenheiro individual, customer success / sales engineering, clientes sob divulgação pública, e procurement / legal / compliance — com o que cada uma precisa e o que a faz ignorar o texto. Dois modos: redigir a partir de input técnico ou revisar um rascunho. Traz templates (update de incidente ao board, sumário executivo, divulgação a cliente, justificação de risco e de investimento).

**Quando usar.** O trabalho técnico está feito e precisa de aterrar fora da segurança: comunicação de incidente, narrativa de post-mortem, findings de auditoria para stakeholders, justificação de gasto.

**Quando não usar.** Como fonte de detalhe técnico de remediação — isso vem das skills de auditoria e do `finding-triage`.

## Referências a skills não incluídas

Os `SKILL.md` mantêm o texto original e citam skills do catálogo de origem que **não** foram trazidas — entre outras: `dependency-audit`, `cloud-audit`, `iam-audit`, `siem-detection`, `disk-forensics`, `breach-patterns`, `soc-operations`, `threat-hunting`, `vuln-research`, `threat-modeling`, `secrets-audit`, `prompt-injection`, `privacy-engineering`, `pci-audit`, `hipaa-audit`, `ai-risk-management`, `csf-mapping`.

Quando uma dessas aparecer, trate-a como sugestão de leitura e não como skill invocável. Alguns cruzamentos têm equivalente local: `dependency-audit` → `dependency-guardsman`; `secrets-audit` / cripto → `data-guardsman`; A09 (logging) → `audit-guardsman`.

## Origem e licença

Skills adaptadas de [briiirussell/cybersecurity-skills](https://github.com/briiirussell/cybersecurity-skills) — MIT License, © 2026 Bri Russell (ver [LICENSE](LICENSE)). Alterações neste harness: selecção parcial do catálogo, reorganização em `offensive/` e `report/`, e a renomeação `red-team-engagement` → `red-legio`.
