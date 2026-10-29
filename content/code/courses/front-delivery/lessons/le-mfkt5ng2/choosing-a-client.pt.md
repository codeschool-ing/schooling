---
title: Escolhendo um cliente
version: 1
---

**A escolha tem menos a ver com recursos, que os principais clientes compartilham, do que com quanta
estrutura uma equipe quer que lhe imponham, e com qual framework ela usa.**

| | Apollo Client | Relay | o `request` da aula 9 |
|---|---|---|---|
| frameworks | qualquer um, ou nenhum | só React | qualquer um, ou nenhum |
| schema | qualquer um | melhor com `Node` e connections | qualquer um |
| passo de build | nenhum | um compilador | nenhum |
| cache normalizado | sim | sim | não |
| campos por componente | um hábito | obrigatório, com data masking | você decide |
| tamanho no navegador | cerca de 56 kB comprimidos, medido acima | um runtime próprio, não medido aqui | nada que valha medir |

Há outros clientes que valem uma olhada para um app menor: o **urql**, um cliente menor cujo cache
normalizado é um complemento, e o **TanStack Query** usado com o `request` da aula 9, que faz cache de
respostas inteiras por chave, e não de objetos por id.

## O Apollo em cada framework

O núcleo do Apollo é o cliente que o planner usa, e cada framework ganha uma camada fina que transforma
uma consulta observada no tipo de valor reativo daquele framework. **Nenhum dos quatro foi executado para
este curso**; cada um é a forma que a documentação dele dava em outubro de 2026, para a consulta `PLANNER`
do planner.

**React**, com os hooks que o Apollo distribui em `@apollo/client/react`:

```tsx
const { data, loading, error } = useQuery(PLANNER);
```

**Angular**, com o `apollo-angular`, que envolve o cliente num serviço injetável e devolve observables do
RxJS:

```typescript
this.apollo.watchQuery({ query: PLANNER }).valueChanges.subscribe(({ data }) => (this.courses = data.courses));
```

**Vue**, com o `@vue/apollo-composable`, cujo `result` é uma referência reativa:

```typescript
const { result, loading, error } = useQuery(PLANNER);
```

**Svelte**, para o qual o Apollo não publica pacote: uma store em volta do `watchQuery` são poucas linhas,
o `watchPlanner` desta aula com a interface de uma store:

```typescript
export const planner = readable(undefined, (set) => {
  const subscription = client.watchQuery({ query: PLANNER }).subscribe((result) => set(result.data));
  return () => subscription.unsubscribe();
});
```

Nos quatro, o cache por baixo é o mesmo, e também tudo o que esta aula disse sobre chaves, fetch
policies, listas e atualizações otimistas.
