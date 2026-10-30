---
title: Feature flags, liberação gradual e a chave de desligar
version: 1
---

**Uma feature flag é um valor de configuração remota que decide se um recurso aparece, para quais
instalações.** Ela separa dois momentos que um release amarra: **publicar** o código, que é a
liberação em etapas da lição 8 e leva dias, e **ligá-lo**, que uma flag faz em minutos e consegue
desfazer em minutos.

## Uma fração das instalações, escolhida de forma estável

A tela nova de estatísticas do planner está ligada para 20% das instalações. Quais 20% é decidido
pela mesma ideia dos baldes da lição 8: um hash do nome da flag e do identificador da instalação,
módulo 100, comparado com a porcentagem. Pôr o nome da flag no hash faz com que os 20% que veem as
estatísticas não sejam sempre os mesmos 20% que veem todo recurso novo.

O `flagOn` do `client.ts` é exatamente isso. Aqui ele é perguntado sobre 1000 instalações, depois
sobre duas em particular, depois a chave de desligar é marcada no `config.json` e a mesma instalação
é perguntada de novo. Este programa pequeno o usa; salve-o como `rollout-share.ts`:

```typescript
// rollout-share.ts: how many of 1000 installs the statistics flag reaches, by the client's own rule
import { readFileSync } from "node:fs";
import { flagOn } from "./client.ts";

const config = JSON.parse(readFileSync("config.json", "utf8"));
const on = Array.from({ length: 1000 }, (_, i) => `i${i}`).filter((id) => flagOn(config, "statistics", id)).length;
console.log(`statistics on for ${on} of 1000 installs`);
```

```
ana@dev:~/planner$ node rollout-share.ts
statistics on for 199 of 1000 installs
ana@dev:~/planner$ node client.ts 1.6.0 i009; node client.ts 1.6.0 i042
1.6.0 (config from server): up to date; statistics on for i009
1.6.0 (config from server): up to date; statistics off for i042
ana@dev:~/planner$ sed -i 's/"killed": false/"killed": true/' config.json && node client.ts 1.6.0 i009
1.6.0 (config from server): up to date; statistics off for i009
```

## Lendo o resultado

**199 de 1000 são os 20% pedidos**, mais ou menos a sorte do hash. A instalação `i009` cai dentro e a
`i042` não, e isso vai valer em toda abertura, o que impede uma pessoa de ver uma tela aparecer e
sumir. **A chave de desligar desligou a `i009` com uma edição de uma palavra no servidor**, e a próxima
abertura de toda instalação a lê: esse é o desfazer instantâneo que a lição 8 disse não existir,
disponível só para o que estava atrás de uma flag antes de ser publicado.

## Flags e as lojas

A lição 6 avisou sobre um recurso desligado para o revisor e ligado para todo mundo. Uma flag liberando
um recurso **revisado** é comum; uma flag escondendo um recurso da revisão, ou mudando o que o app é
depois da aprovação, quebra as regras das duas lojas. **O build mandado para revisão deveria conseguir
mostrar todo recurso que as flags dele conseguem ligar**, com as notas de revisão dizendo como.
