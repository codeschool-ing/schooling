---
title: Timeouts, e a tela que para de esperar
version: 1
---

**Uma requisição tem etapas, e ela pode empacar em qualquer uma delas.** Antes que o seu servidor
veja um byte, o celular precisa achar o endereço do servidor e abrir uma conexão com ele; depois
envia a requisição, espera o primeiro byte da resposta e lê o resto. Um timeout é um limite numa
dessas esperas, e vale distinguir três tipos:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l14-timeline\" aria-label=\"Uma requisição desenhada como cinco etapas ao longo do tempo: achar o endereço do servidor, abrir a conexão, enviar a requisição, esperar o primeiro byte, ler o corpo. Acima das duas primeiras, o timeout de conexão. Acima das duas últimas, o timeout de leitura, o maior silêncio entre dois pedaços de dados, que recomeça sempre que chegam dados. Abaixo das cinco, o prazo da requisição inteira, que o AbortSignal.timeout define. Uma marca na espera do primeiro byte diz que o /hang para ali: conectado, requisição enviada, e nenhum byte chega.\"><defs><marker id=\"l14-timeline-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l14-timeline-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l14-timeline-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"92\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"107.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">achar o</text><text x=\"80.0\" y=\"120.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">endereço</text><rect x=\"160\" y=\"92\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"220.0\" y=\"107.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">abrir a</text><text x=\"220.0\" y=\"120.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">conexão</text><rect x=\"300\" y=\"92\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"107.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">enviar a</text><text x=\"360.0\" y=\"120.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">requisição</text><rect x=\"440\" y=\"92\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"500.0\" y=\"107.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">esperar o</text><text x=\"500.0\" y=\"120.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">primeiro byte</text><rect x=\"580\" y=\"92\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"640.0\" y=\"107.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">ler o</text><text x=\"640.0\" y=\"120.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">corpo</text><path d=\"M140 114 L160 114\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-timeline-ah-paper-dim)\"></path><path d=\"M280 114 L300 114\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-timeline-ah-paper-dim)\"></path><path d=\"M420 114 L440 114\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-timeline-ah-paper-dim)\"></path><path d=\"M560 114 L580 114\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-timeline-ah-paper-dim)\"></path><path d=\"M20 66 L280 66\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-timeline-ah-phosphor)\" marker-start=\"url(#l14-timeline-ah-phosphor)\"></path><text x=\"150\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">timeout de conexão</text><path d=\"M440 66 L700 66\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-timeline-ah-phosphor)\" marker-start=\"url(#l14-timeline-ah-phosphor)\"></path><text x=\"570\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">timeout de leitura: o maior silêncio, zerado a cada byte</text><path d=\"M20 162 L700 162\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-timeline-ah-amber)\" marker-start=\"url(#l14-timeline-ah-amber)\"></path><text x=\"360\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">o prazo da requisição inteira</text><text x=\"500\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">o /hang para aqui: nenhum byte chega</text><path d=\"M500 196 L500 138\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l14-timeline-ah-paper-dim)\"></path><text x=\"690\" y=\"222\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">tempo →</text></svg>", "caption": "Três limites numa requisição. Só o prazo de baixo cobre todas as etapas, e é por isso que é dele que uma tela precisa."}
```

- Um **timeout de conexão** limita quanto tempo o celular tenta abrir a conexão. Ele pega um
  servidor fora do ar ou inalcançável, e um elevador onde a conexão nunca se forma.
- Um **timeout de leitura** limita o maior *silêncio* depois de conectado: o relógio recomeça toda
  vez que chega algum dado. A documentação da Apple para `URLSession`, lida em 30 de outubro de
  2026, chama isso de timeout da requisição e lhe dá um padrão de 60 segundos.
- Um **prazo da requisição inteira** limita tudo, do primeiro passo ao último byte. A mesma página
  dá à versão do `URLSession`, o timeout do recurso, um padrão de sete dias.

**O timeout de leitura sozinho não salva você de um gotejamento lento**: um servidor que manda um
byte a cada cinquenta segundos nunca estoura um timeout de leitura de 60 segundos e nunca termina.
Um prazo para a requisição inteira é o limite de que uma tela realmente precisa, porque quem está
esperando a semana não se importa com qual etapa está lenta.

## Um cliente com prazo

O `fetch`, no Node.js como no navegador e no React Native, aceita um `AbortSignal`: um objeto que
pode receber a ordem de parar, e que para a requisição quando recebe. Salve isto como
`fetchweek.ts`:

```schooling-example
{"language": "typescript", "file": "fetchweek.ts", "parts": [{"code": "// fetchweek.ts: ask for the week with a deadline, a way to cancel, and a bounded retry\nimport { parseArgs } from \"node:util\";\n\nexport type Options = {\n  timeoutMs?: number; // the whole request: connecting, waiting, reading the body\n  signal?: AbortSignal; // aborted by the screen that asked, when it goes away\n  retries?: number; // extra attempts after the first, for a 5xx answer only\n  backoffMs?: number; // the first wait between attempts; each one after doubles\n};\n", "note": "As quatro coisas que quem chama pode decidir. Todas são opcionais, então `fetchWeek(url)` sozinho é uma requisição simples sem limite nenhum, que é o caso por onde esta etapa começa."}, {"code": "export async function fetchWeek(url: string, o: Options = {}) {\n  let wait = o.backoffMs ?? 500;\n  for (let attempt = 1; ; attempt++) {\n    const stops: AbortSignal[] = [];\n    if (o.signal) stops.push(o.signal);\n    if (o.timeoutMs) stops.push(AbortSignal.timeout(o.timeoutMs));\n    const res = await fetch(url, { signal: AbortSignal.any(stops) });\n", "note": "Cada tentativa ganha um prazo novo, criado por `AbortSignal.timeout`. `AbortSignal.any` o junta ao sinal da tela, então a requisição para no que vier primeiro: o prazo ou a tela indo embora."}, {"code": "    if (res.ok) return res.json();\n    if (res.status < 500 || attempt > (o.retries ?? 0)) {\n      throw new Error(`HTTP ${res.status} after ${attempt} attempt(s)`);\n    }\n    console.log(`attempt ${attempt}: HTTP ${res.status}, waiting ${wait} ms`);\n    await new Promise((r) => setTimeout(r, wait));\n    wait *= 2;\n  }\n}\n", "note": "Só um status 500 ou maior é tentado de novo, e só quantas vezes `retries` permitir; o resto é lançado na hora. A espera dobra a cada falha. A próxima etapa roda esta parte."}, {"code": "// Run as `node fetchweek.ts PATH [--timeout MS] [--leave MS] [--retries N]`.\nif (process.argv[1]?.endsWith(\"fetchweek.ts\")) {\n  const { values, positionals } = parseArgs({\n    allowPositionals: true,\n    options: { timeout: { type: \"string\" }, leave: { type: \"string\" }, retries: { type: \"string\" } },\n  });\n  const url = new URL(positionals[0] ?? \"/week\", \"http://127.0.0.1:8014\").href;\n  const screen = new AbortController();\n  if (values.leave) setTimeout(() => screen.abort(), Number(values.leave)).unref();\n", "note": "Esta parte só roda quando o arquivo é o que o `node` recebeu, então o `screen.ts` pode importar `fetchWeek` sem disparar isto. `screen` representa a tela que pediu; `--leave` a aborta depois de tantos milissegundos."}, {"code": "  console.log(`asking ${url}`);\n  const start = performance.now();\n  try {\n    console.log(await fetchWeek(url, {\n      timeoutMs: values.timeout ? Number(values.timeout) : undefined,\n      signal: screen.signal,\n      retries: Number(values.retries ?? 0),\n    }));\n  } catch (e: any) {\n    console.log(`${e.name}: ${e.message}${e.cause?.code ? ` (${e.cause.code})` : \"\"}`);\n  }\n  console.log(`after ${((performance.now() - start) / 1000).toFixed(1)} s`);\n}", "note": "O que acontecer é impresso com o nome, que é como as transcrições abaixo distinguem um timeout de um cancelamento, e com quanto tempo levou, em décimos de segundo."}]}
```

## A requisição que nunca volta

Primeiro, o `/hang` sem prazo nenhum. No elevador não há nada que faça o app parar de esperar,
então a transcrição empresta um de fora: o comando `timeout` mata um programa que ainda está
rodando depois de cinco segundos, e sai com 124 para dizer que precisou fazer isso:

```
ana@dev:~/planner$ timeout 5 node fetchweek.ts /hang; echo "exit $?"
asking http://127.0.0.1:8014/hang
exit 124
```

**Nada foi impresso depois de `asking`**: nenhum erro, nenhuma resposta. Deixado em paz, o Node.js
acaba desistindo, e é nesta hora:

```
ana@dev:~/planner$ node fetchweek.ts /hang
asking http://127.0.0.1:8014/hang
TypeError: fetch failed (UND_ERR_HEADERS_TIMEOUT)
after 301.0 s
```

Cinco minutos, e esse número não é decisão de ninguém sobre a sua tela: é um padrão dentro da
biblioteca por trás do `fetch` do Node.js. Cada plataforma tem o seu, e eles discordam, que é a
razão para definir o seu em vez de herdar o deles. Agora a mesma requisição com um prazo de dois
segundos, e o `/slow` com um prazo de cinco, que ele cumpre:

```
ana@dev:~/planner$ node fetchweek.ts /hang --timeout 2000
asking http://127.0.0.1:8014/hang
TimeoutError: The operation was aborted due to timeout
after 2.0 s
ana@dev:~/planner$ node fetchweek.ts /slow --timeout 5000
asking http://127.0.0.1:8014/slow
{ monday: '2026-10-19', planned: 180, done: 120 }
after 3.1 s
```

O `AbortSignal.timeout(2000)` parou a requisição em 2,0 segundos com um `TimeoutError`, e os três
segundos que o `/slow` levou couberam num limite de cinco. **Quanto tempo é o certo é um juízo sobre
a tela, não sobre a rede**: dois a dez segundos para algo que uma pessoa está olhando, mais para um
upload que ela iniciou de propósito e cujo progresso consegue acompanhar. Os tempos aqui foram
medidos uma vez, no computador em que este curso foi gravado, e variam um décimo de segundo de uma
execução para outra.

## Quando a tela vai embora

**Uma requisição pertence à tela que a pediu.** Se a aluna abre a semana e sai dela antes de a
resposta chegar, a resposta não tem para onde ir, e terminar a requisição gasta bateria e dados à
toa. Pior: uma resposta que chega atrasada pode ser desenhada por cima da tela para onde a aluna
foi. Então a tela guarda um `AbortController` e o aborta quando vai embora. O `--leave 1000` faz o
papel de uma aluna que sai depois de um segundo:

```
ana@dev:~/planner$ node fetchweek.ts /slow --leave 1000
asking http://127.0.0.1:8014/slow
AbortError: This operation was aborted
after 1.0 s
```

**As duas paradas têm nomes diferentes de propósito.** Um `TimeoutError` quer dizer que a rede foi
lenta demais, e a tela deve dizer isso. Um `AbortError` quer dizer que o próprio app parou a
requisição, ninguém está esperando o resultado, e não há nada a mostrar nem a relatar. O
`AbortSignal.any` em `fetchWeek` junta os dois, então qualquer um deles para a requisição.

As três plataformas amarram uma requisição à sua tela cada uma do seu jeito, que os cursos depois da
bifurcação ensinam: em Kotlin, uma coroutine iniciada no escopo da tela é cancelada junto com ela;
em Swift, uma `.task` presa a uma view é cancelada quando a view desaparece; no React, a função de
limpeza de um efeito chama `abort()`. Isso é o curso `android-apps` na aula 11, o `ios-apps` na aula
12 e o `react-native` na aula 10, conforme o caminho que você seguir.
