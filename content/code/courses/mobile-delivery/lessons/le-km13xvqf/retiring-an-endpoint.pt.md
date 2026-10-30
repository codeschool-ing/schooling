---
title: Aposentando um endpoint de propósito
version: 1
---

**Uma versão antiga é aposentada anunciando uma data, avisando o app em toda resposta, subindo a
versão mínima, e só então removendo o que ela chama.** Pular um passo funciona para todo usuário,
menos para os que estão naquela versão, e eles descobrem por uma tela que não carrega mais.

## A ordem

1. **Decida a data pela contagem.** A tabela da primeira seção diz quantas instalações ainda chamam
   o endpoint. Escolha uma data longe o bastante para a maioria ter atualizado, e escreva-a.
2. **Diga isso em toda resposta.** O cabeçalho `Sunset`, da RFC 8594, carrega a data depois da qual
   o endpoint pode parar de responder, e um `Link` com a relação `sunset` aponta para uma página que
   explica. Um app que os lê pode avisar quem o usa; um desenvolvedor lendo logs os vê sem ninguém
   contar.
3. **Suba a versão mínima antes da data.** A mínima da lição 19 é o que transforma "isto vai parar de
   funcionar" em "atualize para continuar", numa tela que o próprio app desenha. Subi-la no dia
   seguinte ao fim é tarde demais para quem abre o app naquele dia.
4. **Depois da data, responda com algo que um app antigo entenda.** Nem um 404, nem um erro de
   servidor. Um `410 Gone`, com um corpo dizendo qual versão instalar, deixa até a versão mais velha
   que confere o status mostrar uma frase em vez de uma lista em branco.

Os passos 3 e 4 só funcionam para versões que já sabiam lê-los. **A checagem da versão mínima e o
tratamento do `410` são as duas partes do contrato que nunca podem ser removidas,** porque são como
toda outra parte é aposentada. O lugar delas é na 1.0.0.

*O cabeçalho `Sunset` é descrito a partir da RFC 8594, que a máquina de gravação não conseguiu
acessar; o servidor abaixo é real e foi rodado.*

## Um servidor que anuncia o próprio fim

Salve isto em `~/planner` como `sunset-server.ts`. Ele recebe o dia como argumento, para você rodá-lo
antes e depois da data sem esperar:

```typescript
// sunset-server.ts: /v1/sessions announces its end, then answers 410 with what to install
import { createServer } from "node:http";

const SUNSET = "2027-03-31";
const today = process.argv[2];
const week = [{ id: "s-101", course: "statistics", minutes: 25, day: "2026-10-12", status: "done" }];

createServer((req, res) => {
  if (req.url !== "/v1/sessions") return res.writeHead(404).end();
  if (today > SUNSET) {
    return res.writeHead(410, { "content-type": "application/json" })
      .end(JSON.stringify({ error: "update required", minimumVersion: "1.5.1" }));
  }
  res.writeHead(200, {
    "content-type": "application/json",
    sunset: new Date(`${SUNSET}T23:59:59Z`).toUTCString(),
    link: '<https://planner.example/v1-sunset>; rel="sunset"',
  }).end(JSON.stringify(week));
}).listen(4320, "127.0.0.1");
```

Suba-o num segundo terminal para um dia de outubro de 2026, `node sunset-server.ts 2026-10-30`, e
olhe a linha de status e os dois cabeçalhos. Depois pare-o, suba de novo para um dia depois do fim,
`node sunset-server.ts 2027-04-01`, e pergunte outra vez:

```
ana@dev:~/planner$ curl -si http://127.0.0.1:4320/v1/sessions | grep -iE '^(HTTP|sunset|link)'
HTTP/1.1 200 OK
sunset: Wed, 31 Mar 2027 23:59:59 GMT
link: <https://planner.example/v1-sunset>; rel="sunset"
ana@dev:~/planner$ curl -si http://127.0.0.1:4320/v1/sessions | grep -iE '^HTTP'; curl -s http://127.0.0.1:4320/v1/sessions; echo
HTTP/1.1 410 Gone
{"error":"update required","minimumVersion":"1.5.1"}
```

**Antes da data, o endpoint antigo ainda responde 200 e diz quando acaba; depois dela, a resposta é
410 com a versão a instalar.** Os cabeçalhos não custam nada para mandar durante meses, e são o único
aviso que chega tanto a quem integra com a sua API quanto ao seu próprio app. O corpo depois da data
é o que a 1.3.1 mostraria, se a 1.3.1 tivesse sido escrita para mostrá-lo.

## O que as lojas acrescentam

Nenhuma das lojas aposenta uma versão por você, e nenhuma deixa você impedir uma versão instalada de
abrir. O que elas oferecem é o que as lições 9 e 19 usaram: o In-App Updates do Google Play, para
pedir uma atualização numa folha que o app abre, e nas duas lojas uma página para onde mandar a
pessoa. Subir o sistema mínimo do app impede instalações novas em celulares velhos, e deixa as cópias
instaladas exatamente como estão, chamando a sua API.
