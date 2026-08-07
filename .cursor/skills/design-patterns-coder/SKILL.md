---
name: design-patterns-coder
description: Enforces GoF design patterns exactly as documented by the developer (docs-mcp source gof-design-patterns; fallback GitHub repo). Use when writing or refactoring code with design patterns, during green-phase implementations (fase{n}.md / fase{n}Task.md), or when the user mentions GoF, design patterns, Strategy, Facade, Builder, Factory, Observer, etc.
---

# Design Patterns Coder

Garante que todo código com padrões GoF siga a documentação escrita pelo próprio desenvolvedor — nunca outra fonte.

## Fonte da verdade (ordem obrigatória)

1. **docs-mcp primeiro**: no servidor `user-docs-mcp`, rode `search_docs` com `source_id: gof-design-patterns` buscando o padrão desejado; use `get_chunk` para ler o README do padrão e o exemplo na linguagem alvo.
2. **Fallback único**: apenas se o docs-mcp não existir ou a fonte/chunks não estiverem ingeridos, leia o repositório `https://github.com/BrunoMartino/design-patterns-exemples-GoF.git` (README do padrão + exemplo da linguagem).
3. **Proibido** usar padrões de qualquer outra origem: código existente, internet ou memória do modelo.

## Regras de implementação

- Só use linguagens e padrões presentes na documentação; se a linguagem não tiver exemplo ou o padrão não estiver na doc, não use.
- Padrões que causam explosão de subclasses (Template Method, Chain of Responsibility, Bridge etc.) são proibidos, salvo pedido explícito do usuário.
- Composição sobre herança; herança apenas quando compor não for possível.
- Se a linguagem permitir versões simplificadas em functions (ex.: Strategy Function em TypeScript), prefira esse caminho.
- Priorize classes/objetos reutilizáveis pelas features já listadas ou por features futuras.
- O código deve seguir o mesmo formato, escrita e organização do exemplo lido (ou o mais parecido possível); `docs/harness/coding_convention.md` tem prioridade sobre o estilo do exemplo.

## Validação

Se a solução exigir linguagem ou padrão ausente da documentação, pare e valide os próximos passos com o usuário antes de implementar.
