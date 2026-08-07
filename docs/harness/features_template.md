# features/feature-{name}.md

## Purpose

Map the system feature by feature: what each feature is, which problem it solves, and how features relate to each other (composition, inheritance, dependency).

This is a **critical harness**: it must always be created together with `architecture_rules`, `coding_conventions`, `domain_invariants`, `operational_constraints`, and `forbidden_patterns`.

Feature docs are **never monolithic**. They always live inside a `features/` folder, one file per feature:

```
docs/harness/features/
  feature-auth.md
  feature-cart.md
  feature-checkout.md
```

- **Greenfield**: map as many features as possible during the harness-writing phase, before the design docs phase begins.
- **Brownfield**: map the new feature and how it will relate to the already existing project, usually one feature at a time.

## The 4 Mandatory Questions

These questions are the pillar of the feature file. Without them the file cannot be completed correctly. **The user must always be the one to answer them — the agent must never complement or invent the answers.**

Whenever a new feature is suggested — by the user or by the agent during the project — the agent must ask and record the answers to:

### 1 - Como descreve a feature?
### 2 - Qual problema objetivamente ela resolve?
### 3 - Qual a solução esperada? Quais trade-offs ela envolve?
### 4 - Qual exemplo ou contexto temos do problema e da solução?

## Feature File Structure

Each `feature-{name}.md` follows this structure:

```markdown
## Feature: {Name}

### Depende de
- feature-{other} (why it depends on it)

### Descrição
[what the feature does, in user language — derived from question 1]

### Problema
[the problem it objectively solves — derived from question 2]

### Solução e trade-offs
[expected solution and its trade-offs — derived from question 3]

### Fluxo (given/when/then)
- Dado [precondition]
- Quando [action]
- Então [expected outcome]

### Casos de erro (explícitos, não deixar implícito)
- [failure] → [explicit expected behavior]

### Critério de aceite (o que prova que está pronto)
- [ ] Teste: [observable behavior that proves the feature works]
- [ ] Teste: [failure case that must not corrupt state]

### Exemplo / contexto
[example or context of the problem and the solution — derived from question 4; code snippets welcome]

### Design Patterns (Gang of Four) Sugerido
- [based on the 4 answers above, the agent lists which design patterns best fit this use case]
```

The "Critério de aceite" block is what the AI turns into automated tests — it is the verification that does not require reviewing the diff line by line.

## Filled Example

Asking the 4 questions for a shopping cart:

1 - Como descreve esse carrinho?

> Resposta: o usuário final, tendo escolhido os produtos desejados anteriormente nas páginas de compra, acessa o carrinho, seja por link direto ou por redirect no botão comprar do produto escolhido. No carrinho ele faz a revisão dos produtos escolhidos, da soma do valor, aplica cupons de desconto se houver, verifica valor de frete pago caso não tenha acesso ao gratuito.

2 - Qual problema objetivamente ela resolve?

> Resposta: Cliente/usuário final precisa ter uma tela para revisar/concordar com valores e produtos antes de seguir para a página de checkout.

3 - Qual solução esperada? Quais trade-offs ela envolve?

> Resposta: Produtos selecionados para comprar sempre são adicionados ao carrinho via fetch, e salvos automaticamente em um carrinho temporário nos cookies caso ele não tenha login, ou no banco de dados ligado àquele usuário, caso ele tenha feito login ou criado uma conta. O fetch é atômico, e a conexão sempre abre e fecha ao fazer a operação. Os dois principais trade-offs são o baixo TTL do cookie para clientes não logados, e um aumento imperceptível de ms no tempo de gravação de produtos e carrinho no cliente logado.

4 - Qual exemplo de solução aplicada?

> Resposta:

```typescript
export class DiscountStrategy {
  protected discount: number = 0;

  getDiscount(cart: ECommerceShoppingCart): number {
    return cart.getTotal()
  }
}
```

Context (`e-commerce-shopping-cart.ts`) — the cart calls the strategy:

```typescript
getTotalWithDiscount(): number {
  return this._discountStrategy.getDiscount(this);
}
set discount(discount: DiscountStrategy) {
  this._discountStrategy = discount;
}
```

Example of a resulting feature file (`docs/harness/features/feature-checkout.md`):

```markdown
## Feature: Checkout

### Depende de
- feature-auth (usuário precisa estar logado)
- feature-cart

### Descrição
[o que a feature faz, em linguagem de usuário]

### Fluxo (given/when/then)
- Dado carrinho com itens e usuário logado
- Quando usuário confirma checkout
- Então cria pedido, debita estoque, dispara email de confirmação

### Casos de erro (explícitos, não deixar implícito)
- Estoque insuficiente → retornar erro 409, NÃO criar pedido parcial
- Pagamento recusado → pedido fica em status "pending_payment", não "cancelled"

### Critério de aceite (o que prova que está pronto)
- [ ] Teste: checkout com estoque OK cria pedido e debita estoque
- [ ] Teste: checkout com estoque insuficiente não altera nada no banco
- [ ] Teste: checkout sem login retorna 401

### Design Patterns (Gang of Four) Sugerido
- [patterns que melhor se encaixam neste caso de uso, derivados das 4 respostas]
```

## Configuration

This is a critical, always-apply pattern. Each `feature-{name}.md` must be a plain-text mirror of that feature's implemented code.

**No new feature may be implemented without going through this step first.** Even if the user tries to skip it, instruct them through the chat on creating the file correctly first; only implement afterwards.

## Validation

All design docs used by the project mandatorily derive from this features harness.

## Agent Rules

- Never fill the 4 answers on the user's behalf; a feature without user answers stays pending, not fabricated.
- Never consolidate multiple features into a single file.
- Keep dependency references (`Depende de`) pointing to existing `feature-{name}.md` files.
- When the feature's code changes, this file must be updated first (docs → code).
