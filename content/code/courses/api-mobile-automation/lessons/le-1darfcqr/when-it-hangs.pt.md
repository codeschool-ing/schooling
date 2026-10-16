---
title: Quando o app nunca fica ocioso
version: 1
---

**O Detox espera um app ocioso, então um app que nunca fica ocioso faz cada passo esperar até o tempo
limite do próprio teste.** Nada na tela está errado. A lista está lá, a linha está lá, e a spec nunca
chega a ela. Esta é a falha que pertence à sincronização de caixa cinza, e toda suíte de Detox a
encontra mais cedo ou mais tarde.

## Como um app continua ocupado

Suponha que uma desenvolvedora faça a lista manter os lugares atualizados perguntando de novo ao
boxoffice a cada segundo. É um pedido comum para uma bilheteria durante uma venda. No `App.tsx` são três
linhas, no lugar do `useEffect` que carrega uma vez:

```tsx
useEffect(() => {
  load();
  const every = setInterval(load, 1000);
  return () => clearInterval(every);
}, [load]);
```

Agora olhe a tabela da seção 03. Há sempre um timer para disparar, e uma requisição ao boxoffice em
andamento durante parte de cada segundo. **O app está correto e nunca fica ocioso.** O primeiro
`expect` da spec espera, e espera, até os dois minutos do Jest em `e2e/jest.config.js` acabarem e o
teste falhar. Enquanto espera, o Detox pode imprimir a lista do que está mantendo o app ocupado. O
timer e a requisição de rede estariam os dois nela. Essa mensagem é o lugar por onde começar: ela
nomeia a causa, e não o elemento.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 332\" role=\"img\" aria-label=\"Duas linhas do tempo do que mantém um app ocupado: rede, timers, a thread de JavaScript e a thread principal. Na primeira, o app carrega os espetáculos uma vez: uma requisição, depois trabalho de JavaScript, depois o desenho, e a partir daí toda faixa está vazia e o Detox toca. Na segunda, o app pergunta de novo ao boxoffice a cada segundo: há sempre um timer pendente e requisições e trabalho de JavaScript voltam sem parar, então nunca há um momento em que todas as faixas estão vazias, e o toque espera até o teste estourar o tempo.\"><text x=\"350\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">carrega uma vez</text><text x=\"350\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">pergunta de novo a cada segundo</text><text x=\"140\" y=\"48\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">rede</text><line x1=\"150\" y1=\"48\" x2=\"690\" y2=\"48\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"5 4\"></line><rect x=\"165\" y=\"41\" width=\"165\" height=\"14\" rx=\"3\" fill=\"var(--phosphor-dim)\"></rect><text x=\"140\" y=\"74\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">timers</text><line x1=\"150\" y1=\"74\" x2=\"690\" y2=\"74\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"5 4\"></line><text x=\"140\" y=\"100\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">JavaScript</text><line x1=\"150\" y1=\"100\" x2=\"690\" y2=\"100\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"5 4\"></line><rect x=\"330\" y=\"93\" width=\"50\" height=\"14\" rx=\"3\" fill=\"var(--phosphor-dim)\"></rect><text x=\"140\" y=\"126\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">thread principal</text><line x1=\"150\" y1=\"126\" x2=\"690\" y2=\"126\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"5 4\"></line><rect x=\"375\" y=\"119\" width=\"45\" height=\"14\" rx=\"3\" fill=\"var(--phosphor-dim)\"></rect><line x1=\"440\" y1=\"34\" x2=\"440\" y2=\"140\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></line><text x=\"440\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">tudo ocioso: o Detox toca</text><text x=\"140\" y=\"208\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">rede</text><line x1=\"150\" y1=\"208\" x2=\"690\" y2=\"208\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"5 4\"></line><rect x=\"165\" y=\"201\" width=\"135\" height=\"14\" rx=\"3\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"345\" y=\"201\" width=\"125\" height=\"14\" rx=\"3\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"525\" y=\"201\" width=\"125\" height=\"14\" rx=\"3\" fill=\"var(--phosphor-dim)\"></rect><text x=\"140\" y=\"234\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">timers</text><line x1=\"150\" y1=\"234\" x2=\"690\" y2=\"234\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"5 4\"></line><rect x=\"150\" y=\"227\" width=\"540\" height=\"14\" rx=\"3\" fill=\"var(--phosphor-dim)\"></rect><text x=\"140\" y=\"260\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">JavaScript</text><line x1=\"150\" y1=\"260\" x2=\"690\" y2=\"260\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"5 4\"></line><rect x=\"300\" y=\"253\" width=\"40\" height=\"14\" rx=\"3\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"470\" y=\"253\" width=\"40\" height=\"14\" rx=\"3\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"650\" y=\"253\" width=\"40\" height=\"14\" rx=\"3\" fill=\"var(--phosphor-dim)\"></rect><text x=\"140\" y=\"286\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">thread principal</text><line x1=\"150\" y1=\"286\" x2=\"690\" y2=\"286\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"5 4\"></line><rect x=\"335\" y=\"279\" width=\"25\" height=\"14\" rx=\"3\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"505\" y=\"279\" width=\"25\" height=\"14\" rx=\"3\" fill=\"var(--phosphor-dim)\"></rect><text x=\"420\" y=\"316\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">nunca tudo ocioso ao mesmo tempo: o toque espera até o teste estourar o tempo</text></svg>", "caption": "O Detox age no primeiro momento em que nada está ocupado. Um app que consulta sem parar nunca tem esse momento.", "same": ["JavaScript", "timers"]}
```

Outras causas comuns, cada uma mantendo uma linha daquela tabela verdadeira para sempre:

- uma animação em loop, como um selo *ao vivo* pulsando ou um indicador de carregamento que ninguém
  para;
- uma conexão longa que o app mantém aberta, para preços ou chat, que o Detox vê como uma requisição
  que nunca termina;
- um timer usado como batimento, para analytics ou para renovar um token.

## Três saídas, a melhor primeiro

**Deixar o app quieto no build de teste.** Se a consulta periódica é um recurso, os desenvolvedores
podem desligá-la, ou espaçá-la, quando o app é compilado para testes. A spec continua exatamente
como está. É de novo o argumento da lição 16 a favor do `CountingIdlingResource`: o app ajuda os
testes dele, de propósito. Os testes mantêm a sincronização completa em todo o resto.

**Dizer ao Detox que ignore um endereço.** O `device.setURLBlacklist` recebe uma lista de padrões, e
requisições a uma URL que corresponde deixam de contar como trabalho em andamento. O resto da
sincronização continua ligado:

```js
await device.setURLBlacklist(['.*/v1/shows.*']);
```

Ele resolve a requisição e não o timer, que sozinho ainda pode manter o Detox esperando. É por isso
que o primeiro jeito é melhor quando é possível.

**Desligar a sincronização na parte que nunca se acalma, e esperar explicitamente ali.** É o estilo
da lição 15, dentro do Detox:

```js
it('opens a show while the list keeps polling', async () => {
  await device.disableSynchronization();
  try {
    await waitFor(element(by.id('show-sh-103'))).toBeVisible().withTimeout(10000);
    await element(by.id('show-sh-103')).tap();
    await waitFor(element(by.id('chosen'))).toBeVisible().withTimeout(5000);
  } finally {
    await device.enableSynchronization();
  }
});
```

O `waitFor(…).withTimeout(…)` pergunta de novo até a condição valer ou o prazo passar, como o
`waitForDisplayed` do WebdriverIO. Sem sincronização, um `expect` simples olharia uma vez, na hora, e
falharia numa lista ainda não desenhada. **O `finally` importa.** Imagine uma spec que falha com a
sincronização desligada e nunca a religa. Toda spec seguinte do arquivo roda então sem ela, passando ou
falhando por motivos que não têm nada a ver com elas.

Nada disso foi executado para este curso, pelo motivo que a seção 04 deu. Foi escrito a partir da API
documentada do Detox, e cada um é um punhado de linhas que um teste pode carregar até os
desenvolvedores deixarem o app quieto.
