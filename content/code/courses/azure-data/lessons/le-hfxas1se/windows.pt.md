---
title: Cinco tipos de janela
version: 1
---

**Esta seção é ensinada a partir da documentação da Microsoft e não foi executada.** O programa do
curso da seção anterior implementa só janelas tumbling; as outras quatro aparecem na linguagem de
consulta do próprio serviço, como a Microsoft as documenta.

**Uma janela transforma um stream sem fim em grupos finitos que uma agregação consegue terminar.**
`COUNT(*)` sobre um stream nunca acaba, porque o stream nunca acaba; `COUNT(*)` sobre os eventos
entre 20:00 e 20:01 é um número. O Stream Analytics tem cinco maneiras de cortar a linha do tempo, e
cada uma responde a uma pergunta diferente. As cinco são escritas no `GROUP BY`, e o
`System.Timestamp()` no `SELECT` é a hora em que a janela termina.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Quatro maneiras de cortar os mesmos oito eventos de uma linha do tempo em janelas. Tumbling: janelas de um minuto, uma depois da outra, cada evento em exatamente uma. Hopping: janelas de dois minutos começando a cada minuto, sobrepostas, então cada evento cai em duas. Sliding: uma janela só existe onde um evento entra ou sai dela, terminando em cada evento. Session: uma janela por rajada de eventos, fechada depois de um intervalo sem eventos, o que dá três sessões.\" data-fig=\"l23-windows\"><text x=\"20\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">tumbling</text><line x1=\"130\" y1=\"76\" x2=\"700\" y2=\"76\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><circle cx=\"158.5\" cy=\"76\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"206.0\" cy=\"76\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"234.5\" cy=\"76\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"377.0\" cy=\"76\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"405.5\" cy=\"76\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"548.0\" cy=\"76\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"567.0\" cy=\"76\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"586.0\" cy=\"76\" r=\"3.5\" fill=\"var(--amber)\"></circle><text x=\"20\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">hopping</text><line x1=\"130\" y1=\"136\" x2=\"700\" y2=\"136\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><circle cx=\"158.5\" cy=\"136\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"206.0\" cy=\"136\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"234.5\" cy=\"136\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"377.0\" cy=\"136\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"405.5\" cy=\"136\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"548.0\" cy=\"136\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"567.0\" cy=\"136\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"586.0\" cy=\"136\" r=\"3.5\" fill=\"var(--amber)\"></circle><text x=\"20\" y=\"188\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sliding</text><line x1=\"130\" y1=\"206\" x2=\"700\" y2=\"206\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><circle cx=\"158.5\" cy=\"206\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"206.0\" cy=\"206\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"234.5\" cy=\"206\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"377.0\" cy=\"206\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"405.5\" cy=\"206\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"548.0\" cy=\"206\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"567.0\" cy=\"206\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"586.0\" cy=\"206\" r=\"3.5\" fill=\"var(--amber)\"></circle><text x=\"20\" y=\"248\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">session</text><line x1=\"130\" y1=\"266\" x2=\"700\" y2=\"266\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><circle cx=\"158.5\" cy=\"266\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"206.0\" cy=\"266\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"234.5\" cy=\"266\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"377.0\" cy=\"266\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"405.5\" cy=\"266\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"548.0\" cy=\"266\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"567.0\" cy=\"266\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"586.0\" cy=\"266\" r=\"3.5\" fill=\"var(--amber)\"></circle><rect x=\"132\" y=\"44\" width=\"91\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"227\" y=\"44\" width=\"91\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"322\" y=\"44\" width=\"91\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"417\" y=\"44\" width=\"91\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"512\" y=\"44\" width=\"91\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"607\" y=\"44\" width=\"91\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"132\" y=\"102\" width=\"186\" height=\"12\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"227\" y=\"116\" width=\"186\" height=\"12\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"322\" y=\"102\" width=\"186\" height=\"12\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"417\" y=\"116\" width=\"186\" height=\"12\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"512\" y=\"102\" width=\"186\" height=\"12\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"130\" y=\"172\" width=\"28.5\" height=\"8\" rx=\"4\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\"></rect><rect x=\"130\" y=\"181\" width=\"76.0\" height=\"8\" rx=\"4\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\"></rect><rect x=\"139.5\" y=\"190\" width=\"95.0\" height=\"8\" rx=\"4\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\"></rect><rect x=\"282.0\" y=\"172\" width=\"95.0\" height=\"8\" rx=\"4\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\"></rect><rect x=\"310.5\" y=\"181\" width=\"95.0\" height=\"8\" rx=\"4\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\"></rect><rect x=\"453.0\" y=\"190\" width=\"95.0\" height=\"8\" rx=\"4\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\"></rect><rect x=\"472.0\" y=\"172\" width=\"95.0\" height=\"8\" rx=\"4\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\"></rect><rect x=\"491.0\" y=\"181\" width=\"95.0\" height=\"8\" rx=\"4\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\"></rect><rect x=\"152.5\" y=\"236\" width=\"88.0\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"371.0\" y=\"236\" width=\"40.5\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"542.0\" y=\"236\" width=\"50.0\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><line x1=\"130\" y1=\"280\" x2=\"130\" y2=\"286\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"130\" y=\"294\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><line x1=\"225\" y1=\"280\" x2=\"225\" y2=\"286\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"225\" y=\"294\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1</text><line x1=\"320\" y1=\"280\" x2=\"320\" y2=\"286\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"320\" y=\"294\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">2</text><line x1=\"415\" y1=\"280\" x2=\"415\" y2=\"286\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"415\" y=\"294\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">3</text><line x1=\"510\" y1=\"280\" x2=\"510\" y2=\"286\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"510\" y=\"294\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">4</text><line x1=\"605\" y1=\"280\" x2=\"605\" y2=\"286\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"605\" y=\"294\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">5</text><line x1=\"700\" y1=\"280\" x2=\"700\" y2=\"286\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"700\" y=\"294\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">6</text><text x=\"700\" y=\"276\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">hora do evento, em minutos</text></svg>", "caption": "Os mesmos oito eventos, cortados de quatro jeitos: um atrás do outro, sobrepostos, onde um evento muda a janela, e uma janela por rajada.", "same": ["tumbling", "hopping", "sliding", "session"]}
```

**Tumbling: fixas, uma atrás da outra, sem sobreposição.** Cada evento pertence a exatamente uma
janela. É a janela de um relatório por minuto ou por hora, e a do job desta lição:

```sql
GROUP BY TumblingWindow(minute, 1)
```

**Hopping: tamanho fixo, começando a um passo fixo, sobrepostas quando o passo é menor que o
tamanho.** "Checkouts nos últimos cinco minutos, atualizados a cada minuto" é uma janela hopping de
cinco minutos com passo de um, e cada evento é contado em cinco janelas. Uma janela hopping cujo passo
é igual ao tamanho é uma janela tumbling.

```sql
GROUP BY HoppingWindow(minute, 5, 1)
```

**Sliding: uma janela que existe onde quer que eventos a mudem.** O serviço produz uma linha só
quando um evento entra na janela ou sai dela, então uma hora calma não produz nada e uma rajada
produz uma linha por evento. Ela responde a "mais de dez checkouts de um cliente caíram em algum
intervalo de dez minutos?", o tipo de pergunta que a checagem de fraude faz, e que uma janela
tumbling perde quando os dez atravessam uma fronteira.

```sql
GROUP BY customer, SlidingWindow(minute, 10)
HAVING COUNT(*) > 10
```

**Session: uma janela por rajada de atividade.** Ela começa com um evento e fica aberta enquanto
eventos continuam chegando dentro de um tempo limite uns dos outros, fechando quando esse tempo passa
sem evento, ou numa duração máxima. Agrupada por cliente, é uma janela por visita ao app, que é o que
os analistas querem dizer quando perguntam quanto dura uma visita.

```sql
GROUP BY customer, SessionWindow(minute, 5, 30)
```

O primeiro número é o tempo limite e o segundo, o máximo que uma sessão pode durar.

**Snapshot: eventos que têm exatamente a mesma hora.** Não há função de janela; agrupar pelo próprio
`System.Timestamp()` agrupa os eventos que carregam a mesma hora, e isso é usado principalmente sobre
a saída de outra janela, para agregar as linhas que um passo anterior produziu num mesmo instante.

```sql
GROUP BY System.Timestamp()
```

## O que uma janela custa enquanto está aberta

**Uma janela guarda estado até fechar**: uma contagem é um número por janela, mas um `COUNT(DISTINCT
customer)` sobre uma hora guarda cada cliente visto naquela hora, e uma janela session agrupada por
cliente guarda uma sessão aberta por cliente que está usando o app. Quanto mais longa e mais fina a
janela, mais memória o job precisa, e memória é parte do que as unidades de streaming da última
seção compram. Uma janela hopping de um dia com passo de um minuto mantém 1.440 janelas sobrepostas
abertas ao mesmo tempo.
