---
title: "Dados de campo: o número do visitante"
version: 1
---

**Todo número desta aula até aqui foi medido num navegador, num computador, com condições escolhidas
por você.** Isso se chama **dados de laboratório**, e é o que acha causas. Os limites da seção "Bom,
precisa melhorar, ruim" são feitos para **dados de campo**: o que os navegadores de visitantes reais
mediram nos seus próprios aparelhos e redes, juntado de muitas visitas e lido no 75º percentil.

## Dois lugares de onde vêm dados de campo

O **Chrome User Experience Report** do Google, o CrUX, são dados de campo que o Chrome coleta de
usuários que aceitaram compartilhar estatísticas de uso, para sites com tráfego suficiente, agregados
por origem e por página. As ferramentas do Google os mostram ao lado das suas próprias medidas de
laboratório, e a aula 6 é sobre essas ferramentas. Um site pequeno, ou uma página nova, não tem
nenhum.

**A sua própria coleta**, geralmente chamada de **RUM**, real user monitoring: a página mede a si
mesma, como o `vitals.ts` já faz, e manda os valores para um servidor seu. Funciona para qualquer site,
toda página e todo navegador que dê suporte às métricas, e pode levar o que o CrUX não leva, como qual
página de curso era. O resto desta seção acrescenta isso ao planner.

## Mandando os valores para casa

Os valores que o navegador de uma pessoa informa enquanto ela lê uma página não são finais até ela
sair: o CLS pode crescer, e a interação mais lenta pode ser a última. Por isso a biblioteca informa
cada valor final **quando a página é escondida ou deixada**, e nesse momento um `fetch` comum pode ser
cortado junto com a página. **O `navigator.sendBeacon` é feito exatamente para esse momento**: o
navegador mantém a requisição andando depois de a página ter ido embora.

No `src/vitals.ts`, mude a primeira linha para ela também importar o tipo de um valor:

```typescript
import { onCLS, onINP, onLCP, type Metric } from "web-vitals/attribution";
```

e acrescente estas linhas no fim. Elas registram as três métricas uma segunda vez, sem o
`reportAllChanges`, para cada uma mandar uma vez por visualização de página, com o seu valor final:

```typescript

// Once per page view, when the visitor leaves or hides the page, the final values go to the
// server. sendBeacon is made for this: it outlives the page that sent it.
const send = (m: Metric) => navigator.sendBeacon("/vitals",
  JSON.stringify({ name: m.name, value: Math.round(m.value * 1000) / 1000, rating: m.rating, page: location.pathname }));
onLCP(send);
onINP(send);
onCLS(send);
```

O `server.ts` precisa de um endereço que os receba. Acrescente estas linhas logo depois da linha que
lê o `pathname`, antes da que confere se é um arquivo:

```typescript
  if (req.method === "POST" && pathname === "/vitals") {
    // A visitor's browser reporting its Core Web Vitals: one line in the log for each.
    let body = "";
    for await (const chunk of req) body += chunk;
    console.log(`vitals ${body}`);
    res.writeHead(204).end();
    return;
  }
```

Build e reinício. O `vitals.ts` já deixa a página no fim de cada rodada, como um visitante faz, então
uma rodada com um clique basta:

```
ana@dev:~/planner$ node tools/vitals.ts http://localhost:3000/courses/git --click "[data-done]"
[vitals] LCP 68 ms good #notice
[vitals] CLS 0.000 good 
```

E o segundo terminal, onde roda o `server.ts`:

```
ana@dev:~/planner$ npm run build >/dev/null && TZ=UTC node server.ts
planner on http://localhost:3000
vitals {"name":"LCP","value":68,"rating":"good","page":"/courses/git"}
vitals {"name":"CLS","value":0,"rating":"good","page":"/courses/git"}
```

**Chegaram duas linhas, LCP e CLS, e nenhum INP.** O clique foi rápido, e a biblioteca só escuta
interações de 40 milissegundos ou mais, então uma visita cujas interações foram todas rápidas não tem
INP para mandar. Essa é uma propriedade dos dados para lembrar na hora de contá-los: a parcela de
visitas com INP não é a parcela de visitas com interação.

## O que uma linha de log não é

Uma linha de log é uma visita. O que responde "esta página passa" são muitas delas, agrupadas por
página e por tipo de aparelho, e lidas no 75º percentil, o que é trabalho para o que quer que guarde os
outros logs e métricas da aplicação. Duas cautelas vão junto com a própria coleta:

- **são dados sobre visitantes**, mandados dos navegadores deles: o endereço que liam, o aparelho que
  usavam. Um site com política de privacidade tem de prestar contas disso, como de qualquer outra
  medida;
- **o endpoint aceita qualquer coisa que alguém mandar**. Nada aqui confia nele além de escrever uma
  linha; um de verdade confere o formato e o tamanho do que recebe antes de guardar.
