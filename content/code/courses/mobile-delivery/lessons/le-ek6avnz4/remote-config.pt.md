---
title: Configuração remota, e o dia em que o servidor cai
version: 1
---

**Configuração remota é um conjunto de valores que o app lê de um servidor em vez do próprio código,
para que possam mudar sem release.** A versão mínima da seção anterior é um deles; os outros do
planner são a fração das instalações que vê uma tela nova e uma chave para desligá-la. A pergunta de
desenho não é como buscá-los. **É o que o app faz quando não consegue.**

## Três fontes, em ordem

1. **O servidor**, com um tempo limite curto, para que uma rede lenta não segure a abertura do app,
   lição 15.
2. **A última cópia que funcionou**, guardada no aparelho, para que um app aberto num avião se comporte
   como ontem.
3. **Padrões compilados no app**, para a primeira abertura sem rede, e escolhidos para serem
   **seguros**: nenhuma atualização forçada, todo recurso novo desligado.

## A configuração do planner, e um servidor para ela

Salve isto em `~/planner` como `config.json`:

```json
{
  "minimumVersion": "1.5.1",
  "latestVersion": "1.6.0",
  "flags": {
    "statistics": { "rollout": 20, "killed": false }
  }
}
```

O servidor relê o arquivo a cada requisição, então editá-lo é como o valor muda. Salve isto como
`config-server.ts`, e o inicie num segundo terminal com `node config-server.ts`:

```typescript
// config-server.ts: serves config.json as it is on disk at each request, so editing the file changes what apps get
import { createServer } from "node:http";
import { readFileSync } from "node:fs";

createServer((req, res) => {
  if (req.url !== "/config") return res.writeHead(404).end();
  res.writeHead(200, { "content-type": "application/json" }).end(readFileSync("config.json"));
}).listen(4319, "127.0.0.1");
```

## O cliente

Salve isto como `client.ts`. É o que o planner faria na abertura: carregar a configuração das três
fontes, decidir sobre atualizar, e decidir sobre a única feature flag, para a versão e a instalação
dadas na linha de comando:

```schooling-example
{"language": "typescript", "file": "client.ts", "parts": [{"code": "// client.ts: what the planner does with remote config at start-up\nimport { createHash } from \"node:crypto\";\nimport { existsSync, readFileSync, writeFileSync } from \"node:fs\";\n\ntype Config = { minimumVersion: string; latestVersion: string; flags: Record<string, { rollout: number; killed: boolean }> };\nconst DEFAULTS: Config = { minimumVersion: \"0.0.0\", latestVersion: \"0.0.0\", flags: {} };\nconst [version, install] = [process.argv[2], process.argv[3] ?? \"i042\"];", "note": "Os padrões vêm compilados e são seguros: nenhuma versão é velha demais, e nenhuma flag existe, então todo recurso novo fica desligado."}, {"code": "async function load(): Promise<[Config, string]> {\n  try {\n    const res = await fetch(\"http://127.0.0.1:4319/config\", { signal: AbortSignal.timeout(1500) });\n    const fresh = (await res.json()) as Config;\n    writeFileSync(\"config-cache.json\", JSON.stringify(fresh));\n    return [fresh, \"server\"];\n  } catch {\n    if (existsSync(\"config-cache.json\")) return [JSON.parse(readFileSync(\"config-cache.json\", \"utf8\")), \"cache\"];\n    return [DEFAULTS, \"defaults\"];\n  }\n}", "note": "As três fontes em ordem: o servidor, com um tempo limite de um segundo e meio; a última cópia que funcionou; os padrões. Ele diz qual usou."}, {"code": "const older = (a: string, b: string) => {\n  const [x, y] = [a.split(\".\").map(Number), b.split(\".\").map(Number)];\n  for (let i = 0; i < 3; i++) if (x[i] !== y[i]) return x[i] < y[i];\n  return false;\n};", "note": "As versões são comparadas como números, parte por parte, então 1.10.0 é mais nova que 1.9.0."}, {"code": "export function flagOn(c: Config, flag: string, id: string): boolean {\n  const f = c.flags[flag];\n  if (!f || f.killed) return false;\n  const bucket = createHash(\"sha256\").update(`${flag}:${id}`).digest().readUInt32BE(0) % 100;\n  return bucket < f.rollout;\n}", "note": "Uma flag fica desligada se for desconhecida ou morta; fora isso, o balde da instalação, de um hash da flag e do id dela, decide."}, {"code": "if (version) {\n  const [config, from] = await load();\n  const update = older(version, config.minimumVersion) ? \"must update\" : older(version, config.latestVersion) ? \"may update\" : \"up to date\";\n  console.log(`${version} (config from ${from}): ${update}; statistics ${flagOn(config, \"statistics\", install) ? \"on\" : \"off\"} for ${install}`);\n}", "note": "A decisão para a versão e a instalação dadas. Sem versão, ele só exporta o `flagOn`, para o script da próxima seção."}]}
```

Rode para três versões com o servidor no ar, depois pare o servidor, como um servidor que caiu, e abra
mais duas vezes, a segunda sem cache nenhum:

```
ana@dev:~/planner$ node client.ts 1.5.0; node client.ts 1.5.2; node client.ts 1.6.0
1.5.0 (config from server): must update; statistics off for i042
1.5.2 (config from server): may update; statistics off for i042
1.6.0 (config from server): up to date; statistics off for i042
ana@dev:~/planner$ node client.ts 1.5.0
1.5.0 (config from cache): must update; statistics off for i042
ana@dev:~/planner$ rm config-cache.json; node client.ts 1.5.0
1.5.0 (config from defaults): up to date; statistics off for i042
```

**A 1.5.0 está abaixo do mínimo e precisa atualizar; a 1.5.2 pode; a 1.6.0 está em dia.** As duas
últimas linhas são o dia em que o servidor caiu: a primeira abertura depois disso ainda tinha a
configuração de ontem no cache, e uma primeira abertura de todas, sem cache, caiu nos padrões, com os
quais a 1.5.0 pode rodar. Esse é o preço de padrões seguros, e é o preço certo: uma queda do servidor
nunca deveria trancar todo mundo fora do app.

## O que não pertence à configuração remota

- **Segredos.** Tudo o que o app baixa, a pessoa consegue ler.
- **Quem pode acessar o quê.** Um recurso pago ligado por um valor de configuração é ligado por
  qualquer um que edite o próprio cache. Acesso é decisão do servidor, tomada no servidor.
- **Valores que o código não aguenta.** Uma configuração que consegue pôr um tempo limite em 0 um dia
  vai pô-lo em 0; o app valida todo valor contra uma faixa e volta ao padrão dele.
