// crdt.ts: a counter and a set whose copies always merge to the same state.

// A grow-only counter: each device counts its own additions, and the total is the sum.
export type GCounter = Record<string, number>;
export const add = (c: GCounter, device: string, n: number): GCounter => ({ ...c, [device]: (c[device] ?? 0) + n });
export const total = (c: GCounter) => Object.values(c).reduce((a, b) => a + b, 0);
export function mergeCounter(a: GCounter, b: GCounter): GCounter {
  const out = { ...a };
  for (const [d, n] of Object.entries(b)) out[d] = Math.max(out[d] ?? 0, n);
  return out;
}

// An observed-remove set: every add gets a tag, and a remove deletes only the tags it has seen.
export type ORSet = { adds: Record<string, string[]>; removed: string[] };
export const empty = (): ORSet => ({ adds: {}, removed: [] });
export function insert(s: ORSet, value: string, tag: string): ORSet {
  return { ...s, adds: { ...s.adds, [value]: [...(s.adds[value] ?? []), tag] } };
}
export function remove(s: ORSet, value: string): ORSet {
  return { ...s, removed: [...s.removed, ...(s.adds[value] ?? [])] };
}
export function values(s: ORSet): string[] {
  return Object.keys(s.adds).filter((v) => s.adds[v].some((t) => !s.removed.includes(t))).sort();
}
export function mergeSet(a: ORSet, b: ORSet): ORSet {
  const adds: Record<string, string[]> = {};
  for (const v of new Set([...Object.keys(a.adds), ...Object.keys(b.adds)])) {
    adds[v] = [...new Set([...(a.adds[v] ?? []), ...(b.adds[v] ?? [])])].sort();
  }
  return { adds, removed: [...new Set([...a.removed, ...b.removed])].sort() };
}
