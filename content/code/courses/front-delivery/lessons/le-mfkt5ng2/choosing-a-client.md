---
title: Choosing a client
version: 1
---

**The choice is less about features, which the main clients share, than about how much structure a team
wants imposed, and which framework it uses.**

| | Apollo Client | Relay | lesson 9's `request` |
|---|---|---|---|
| frameworks | any, or none | React only | any, or none |
| schema | any | best with `Node` and connections | any |
| build step | none | a compiler | none |
| normalised cache | yes | yes | no |
| fields per component | a habit | enforced, with data masking | up to you |
| size in the browser | about 56 kB compressed, measured above | a runtime of its own, not measured here | none worth measuring |

Other clients exist and are worth a look for a smaller app: **urql**, a smaller client whose normalised
cache is an add-on, and **TanStack Query** used with lesson 9's `request`, which caches whole answers by
key rather than objects by id.

## Apollo in each framework

Apollo's core is the client the planner uses, and each framework gets a thin layer that turns a watched
query into that framework's kind of reactive value. **None of these four was run for this course**; each
is the form its documentation gave in October 2026, for the planner's `PLANNER` query.

**React**, with the hooks Apollo ships in `@apollo/client/react`:

```tsx
const { data, loading, error } = useQuery(PLANNER);
```

**Angular**, with `apollo-angular`, which wraps the client in an injectable service and returns RxJS
observables:

```typescript
this.apollo.watchQuery({ query: PLANNER }).valueChanges.subscribe(({ data }) => (this.courses = data.courses));
```

**Vue**, with `@vue/apollo-composable`, whose `result` is a reactive reference:

```typescript
const { result, loading, error } = useQuery(PLANNER);
```

**Svelte**, where Apollo publishes no package: a store around `watchQuery` is a few lines, which is
`watchPlanner` from this lesson with a store's interface:

```typescript
export const planner = readable(undefined, (set) => {
  const subscription = client.watchQuery({ query: PLANNER }).subscribe((result) => set(result.data));
  return () => subscription.unsubscribe();
});
```

In all four the cache underneath is the same, and so is everything in this lesson about keys, fetch
policies, lists and optimistic updates.
