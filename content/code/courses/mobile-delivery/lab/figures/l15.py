"""Lesson 15: field.ts."""
P = [
    ("// field.ts: a week of cold starts from the field, and why the average says the wrong thing\nfunction mulberry32(seed: number) {\n  return () => {\n    seed = (seed + 0x6d2b79f5) | 0;\n    let t = Math.imul(seed ^ (seed >>> 15), 1 | seed);\n    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;\n    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;\n  };\n}\nconst random = mulberry32(2026);\nconst normal = () => Math.sqrt(-2 * Math.log(1 - random())) * Math.cos(2 * Math.PI * random());",
     "A small seeded random number generator, so the same week comes out on every run, and a normal distribution made from it.",
     "Um gerador de números aleatórios pequeno, com semente, para a mesma semana sair em toda execução, e uma distribuição normal feita a partir dele."),
    ("const tiers = [\n  { name: \"high-end\", share: 0.3, median: 650 },\n  { name: \"mid-range\", share: 0.5, median: 1100 },\n  { name: \"low-end\", share: 0.2, median: 2400 },\n];\nconst starts: { tier: string; ms: number }[] = [];\nfor (let i = 0; i < 5000; i++) {\n  const r = random();\n  const tier = r < 0.3 ? tiers[0] : r < 0.8 ? tiers[1] : tiers[2];\n  starts.push({ tier: tier.name, ms: Math.round(tier.median * Math.exp(0.35 * normal())) });\n}",
     "Three kinds of phone in the shares a real audience has, each with a typical cold start. Multiplying by `exp` of a normal gives the long tail real start-up times have.",
     "Três tipos de celular nas proporções que um público de verdade tem, cada um com uma abertura a frio típica. Multiplicar pelo `exp` de uma normal dá a cauda longa que tempos de abertura de verdade têm."),
    ("function pct(values: number[], p: number): number {\n  const sorted = [...values].sort((a, b) => a - b);\n  return sorted[Math.min(sorted.length - 1, Math.floor((p / 100) * sorted.length))];\n}",
     "A percentile: sort, and read the value that the given share of starts is below.",
     "Um percentil: ordenar, e ler o valor abaixo do qual fica a fração dada das aberturas."),
    ("function row(label: string, values: number[]) {\n  const mean = Math.round(values.reduce((n, v) => n + v, 0) / values.length);\n  console.log(`${label.padEnd(10)} ${String(values.length).padStart(5)}  ${String(mean).padStart(5)}  ${[50, 90, 99].map((p) => String(pct(values, p)).padStart(5)).join(\"  \")}`);\n}\nconsole.log(`${\"cold start\".padEnd(10)} ${\"n\".padStart(5)}  ${\"mean\".padStart(5)}  ${[\"p50\", \"p90\", \"p99\"].map((h) => h.padStart(5)).join(\"  \")}`);\nrow(\"all\", starts.map((s) => s.ms));\nfor (const t of tiers) row(t.name, starts.filter((s) => s.tier === t.name).map((s) => s.ms));",
     "One row for everybody, then one per kind of phone, each with its count, mean and three percentiles, in milliseconds.",
     "Uma linha para todo mundo, depois uma por tipo de celular, cada uma com a contagem, a média e três percentis, em milissegundos."),
]
EXAMPLES = {"percentiles-not-averages": [{"language": "typescript", "file": "field.ts", "parts": P}]}
