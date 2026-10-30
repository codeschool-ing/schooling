---
title: Percentis, e não médias
version: 1
---

**O tempo médio de abertura é o número que esconde as pessoas que estão sofrendo.** Tempos de
abertura não se espalham por igual em volta de um meio: a maioria é curta, e uma cauda longa é muito
longa, em celulares velhos, com armazenamento cheio, num dia corrido. Uma média puxa a cauda para o
meio e informa um número que ninguém viveu. **Percentis** informam o que as pessoas viveram: o
percentil 50, p50, é o tempo que metade das aberturas superou em rapidez; o p90 é o tempo que nove
aberturas em dez batem; o p99 é a de um em cem.

## Uma semana de dados de campo

Números de verdade vêm do Android vitals, do Organizer do Xcode ou das suas próprias medidas mandadas
do jeito que a lição 16 manda eventos. Para ter uma semana deles aqui, um programa curto gera 5000
aberturas a frio em três tipos de celular, cada um com um tempo típico e uma dispersão em volta dele,
a partir de um gerador de números aleatórios com semente, para toda execução gerar a mesma semana.
Salve isto como `field.ts` em `~/planner`:

```schooling-example
{"language": "typescript", "file": "field.ts", "parts": [{"code": "// field.ts: a week of cold starts from the field, and why the average says the wrong thing\nfunction mulberry32(seed: number) {\n  return () => {\n    seed = (seed + 0x6d2b79f5) | 0;\n    let t = Math.imul(seed ^ (seed >>> 15), 1 | seed);\n    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;\n    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;\n  };\n}\nconst random = mulberry32(2026);\nconst normal = () => Math.sqrt(-2 * Math.log(1 - random())) * Math.cos(2 * Math.PI * random());", "note": "Um gerador de números aleatórios pequeno, com semente, para a mesma semana sair em toda execução, e uma distribuição normal feita a partir dele."}, {"code": "const tiers = [\n  { name: \"high-end\", share: 0.3, median: 650 },\n  { name: \"mid-range\", share: 0.5, median: 1100 },\n  { name: \"low-end\", share: 0.2, median: 2400 },\n];\nconst starts: { tier: string; ms: number }[] = [];\nfor (let i = 0; i < 5000; i++) {\n  const r = random();\n  const tier = r < 0.3 ? tiers[0] : r < 0.8 ? tiers[1] : tiers[2];\n  starts.push({ tier: tier.name, ms: Math.round(tier.median * Math.exp(0.35 * normal())) });\n}", "note": "Três tipos de celular nas proporções que um público de verdade tem, cada um com uma abertura a frio típica. Multiplicar pelo `exp` de uma normal dá a cauda longa que tempos de abertura de verdade têm."}, {"code": "function pct(values: number[], p: number): number {\n  const sorted = [...values].sort((a, b) => a - b);\n  return sorted[Math.min(sorted.length - 1, Math.floor((p / 100) * sorted.length))];\n}", "note": "Um percentil: ordenar, e ler o valor abaixo do qual fica a fração dada das aberturas."}, {"code": "function row(label: string, values: number[]) {\n  const mean = Math.round(values.reduce((n, v) => n + v, 0) / values.length);\n  console.log(`${label.padEnd(10)} ${String(values.length).padStart(5)}  ${String(mean).padStart(5)}  ${[50, 90, 99].map((p) => String(pct(values, p)).padStart(5)).join(\"  \")}`);\n}\nconsole.log(`${\"cold start\".padEnd(10)} ${\"n\".padStart(5)}  ${\"mean\".padStart(5)}  ${[\"p50\", \"p90\", \"p99\"].map((h) => h.padStart(5)).join(\"  \")}`);\nrow(\"all\", starts.map((s) => s.ms));\nfor (const t of tiers) row(t.name, starts.filter((s) => s.tier === t.name).map((s) => s.ms));", "note": "Uma linha para todo mundo, depois uma por tipo de celular, cada uma com a contagem, a média e três percentis, em milissegundos."}]}
```

```
ana@dev:~/planner$ node field.ts
cold start     n   mean    p50    p90    p99
all         5000   1313   1055   2489   4346
high-end    1562    697    655   1008   1444
mid-range   2417   1177   1116   1730   2524
low-end     1021   2578   2425   3824   5345
```

## Lendo a tabela

**A média diz 1,3 segundo e o p50 diz 1,1, e os dois descrevem um app rápido.** O p90 diz que uma
abertura em dez leva 2,5 segundos ou mais. Separada por tipo de celular, a linha dos mais simples diz
algo que a primeira linha não consegue: metade dessas pessoas espera 2,4 segundos ou mais, uma em dez
espera 3,8, e uma em cem espera mais de 5.

Três hábitos vêm daí:

- **Olhe o p90 e o p99 ao lado do p50**, nunca a média sozinha. Um release que melhora a média e piora
  o p99 deixou o app mais lento para quem tem mais chance de ir embora.
- **Separe por tipo de celular**, e por versão do sistema. Os usuários do planner são principalmente
  intermediários nesses dados, e o quinto mais simples é onde a cauda longa mora.
- **Compare com o release anterior, nos mesmos dias.** Um p90 de 2,5 segundos não é bom nem ruim
  sozinho; 2,5 depois de 2,1 é uma regressão com uma causa no diff.

## Por que o décimo mais lento decide

As pessoas nos celulares mais lentos não são um erro de arredondamento. São as pessoas cujos
celulares têm menos espaço, lição 18, e menos paciência sobrando para um app que as faz esperar; e
as avaliações de uma estrela delas são lidas por quem tem celular rápido e está decidindo se instala.
**Um percentil é uma promessa sobre uma fração de pessoas reais**, e o p90 é uma promessa para nove em
cada dez delas.
