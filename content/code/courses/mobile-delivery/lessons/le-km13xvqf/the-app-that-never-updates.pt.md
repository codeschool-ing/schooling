---
title: O app que nunca atualiza
version: 1
---

**Um site é substituído a cada visita; um app instalado continua na versão que era até o dono
atualizar.** As atualizações automáticas das duas lojas fecham a maior parte dessa distância, mas não
toda: um celular com a atualização automática desligada, um que só atualiza no Wi-Fi e quase nunca
está no Wi-Fi, um velho demais para o sistema mínimo da versão nova, um tablet na gaveta que sai uma
vez por semestre. Cada um deles ainda abre o planner, ainda chama a API, e espera que ela responda do
jeito que respondia no dia em que aquela versão saiu.

Então a primeira pergunta desta lição não é técnica. **Quais versões ainda estão por aí, e quantas
pessoas usam cada uma?**

## Contando

O app manda a versão dele em cada requisição, como fazia o cliente do planner na lição 19, e o
servidor conta instalações distintas por versão dentro de uma janela. A janela importa: 28 dias contam
quem usa o app, enquanto "toda instalação desde sempre" conta celulares na gaveta.

Os números abaixo são um exemplo, com o formato de um app real um ano depois do primeiro lançamento:
instalações que abriram o planner nos últimos 28 dias, pela versão que rodavam. Salve-os em
`~/planner` como `seen.json`:

```json
{
  "1.6.0": 3120,
  "1.5.2": 1480,
  "1.5.1": 260,
  "1.5.0": 95,
  "1.4.3": 610,
  "1.4.0": 140,
  "1.3.1": 230,
  "1.2.0": 88,
  "1.1.0": 41,
  "1.0.0": 17
}
```

Salve isto como `support.ts`. Ele imprime a fração de cada versão, a fração naquela versão ou mais
nova, e, para a mínima dada na linha de comando, quantas pessoas dariam com a tela de atualização:

```typescript
// support.ts: share per version, newest first, and who a minimum version would stop
import { readFileSync } from "node:fs";

const seen: Record<string, number> = JSON.parse(readFileSync("seen.json", "utf8"));
const parts = (v: string) => v.split(".").map(Number);
const newer = (a: string, b: string) => {
  const [x, y] = [parts(a), parts(b)];
  for (let i = 0; i < 3; i++) if (x[i] !== y[i]) return x[i] > y[i];
  return false;
};
const versions = Object.keys(seen).sort((a, b) => (newer(a, b) ? -1 : 1));
const total = versions.reduce((n, v) => n + seen[v], 0);
const pct = (n: number) => ((100 * n) / total).toFixed(1).padStart(5) + "%";

let atLeast = 0;
console.log("version  installs  share  this or newer");
for (const v of versions) {
  atLeast += seen[v];
  console.log(`${v.padEnd(7)}  ${String(seen[v]).padStart(8)}  ${pct(seen[v])}  ${pct(atLeast)}`);
}
const minimum = process.argv[2];
if (minimum) {
  const stopped = versions.filter((v) => newer(minimum, v)).reduce((n, v) => n + seen[v], 0);
  console.log(`minimum ${minimum}: ${stopped} of ${total} installs (${pct(stopped).trim()}) meet the update screen`);
}
```

Rode-o com a mínima que o planner definiu na lição 19, 1.5.1, e depois com uma mais branda, 1.4.0,
guardando só a última linha:

```
ana@dev:~/planner$ node support.ts 1.5.1
version  installs  share  this or newer
1.6.0        3120   51.3%   51.3%
1.5.2        1480   24.3%   75.6%
1.5.1         260    4.3%   79.9%
1.5.0          95    1.6%   81.5%
1.4.3         610   10.0%   91.5%
1.4.0         140    2.3%   93.8%
1.3.1         230    3.8%   97.6%
1.2.0          88    1.4%   99.0%
1.1.0          41    0.7%   99.7%
1.0.0          17    0.3%  100.0%
minimum 1.5.1: 1221 of 6081 installs (20.1%) meet the update screen
ana@dev:~/planner$ node support.ts 1.4.0 | tail -n 1
minimum 1.4.0: 376 of 6081 installs (6.2%) meet the update screen
```

**Um ano depois do primeiro lançamento, 18,5% das instalações ainda rodam uma versão anterior à
1.5.** A cauda é longa e fina: as três versões mais velhas juntas são 2,4%, e vão continuar ali no
ano que vem. As duas linhas `minimum` são a troca que a lição 19 deixou em aberto. Uma mínima de 1.5.1
para 1221 instalações, uma em cada cinco, todas de pessoas que não fizeram nada de errado além de não
atualizar. Uma mínima de 1.4.0 para 376, cerca de uma em dezesseis.

## O que a contagem decide

- **A janela de suporte.** Escreva quais versões a API atende, como regra e não como impressão:
  "toda versão lançada nos últimos 12 meses", ou "as três últimas versões menores". A contagem é
  como você confere a regra contra as pessoas que ela deixaria de fora.
- **O sistema mínimo.** A mesma tabela por versão do sistema operacional, que as duas lojas também
  mostram, diz quanto custa subir o sistema mínimo do app. Abandonar uma versão do sistema impede
  instalações novas e atualizações naqueles celulares, e a cópia já instalada continua rodando, sem
  receber mais nada.
- **O que os testes cobrem.** Uma versão com 4% dos seus usuários merece rodar o teste de contrato,
  da seção três, a cada deploy do servidor. Uma versão que ninguém roda merece sair da janela.

A tabela não diz por que uma versão ainda está ali. Um celular preso na 1.2.0 pode estar preso porque
o sistema dele não instala a 1.3; subir a mínima então manda essa pessoa para uma atualização que ela
não consegue instalar. **Confira em que rodam as versões mais velhas antes de mandá-las para uma tela
sem saída.**
