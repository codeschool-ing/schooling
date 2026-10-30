---
title: O cursor: um marcador que o servidor entrega
version: 1
---

**Um cursor é uma posição no histórico de mudanças do servidor, entregue ao aparelho com cada
resposta, e devolvida pelo aparelho da próxima vez para dizer onde parou de ler.** O servidor do
planner numera cada escrita, então o cursor dele é o último número que o aparelho viu. Pedir `GET
/changes?after=2006` quer dizer "toda linha escrita depois da escrita 2006", e a resposta traz o
cursor novo a guardar.

A primeira tentativa comum usa uma hora em vez disso: "tudo o que mudou desde a minha última
sincronização às 10:00". Parece equivalente e não é, e a próxima seção mostra a mudança que isso
perde. Um número de sequência distribuído pelo servidor tem uma propriedade que uma hora não tem:
**ele é decidido num lugar só, na ordem em que as escritas de fato aconteceram**, então nada pode ser
escrito com um número menor que um que o aparelho já leu.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l11-cursor\" aria-label=\"O histórico de escritas do servidor como uma fileira de caixas numeradas: 1 s1, 2 s2, e assim por diante até 2006 h2000, depois 2007 s7. O cursor do celular A fica depois de 2006, então pedir as mudanças depois de 2006 devolve uma linha, s7, e o cursor novo 2007. O cursor do celular B fica depois de 6, então a mesma pergunta feita por B devolve 2001 linhas. Um histórico serve os dois, cada um a partir do próprio lugar.\"><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">o histórico do servidor: toda escrita, numerada na ordem em que chegou</text><rect x=\"20\" y=\"40\" width=\"76\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"58.0\" y=\"55.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">1</text><text x=\"58.0\" y=\"68.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">s1</text><rect x=\"104\" y=\"40\" width=\"76\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"142.0\" y=\"55.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">2</text><text x=\"142.0\" y=\"68.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">s2</text><rect x=\"188\" y=\"40\" width=\"40\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"208.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">…</text><rect x=\"236\" y=\"40\" width=\"76\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"274.0\" y=\"55.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">6</text><text x=\"274.0\" y=\"68.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">s6</text><rect x=\"320\" y=\"40\" width=\"76\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"358.0\" y=\"55.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">7</text><text x=\"358.0\" y=\"68.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">h1</text><rect x=\"404\" y=\"40\" width=\"40\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"424.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">…</text><rect x=\"452\" y=\"40\" width=\"76\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"490.0\" y=\"55.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">2006</text><text x=\"490.0\" y=\"68.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">h2000</text><rect x=\"536\" y=\"40\" width=\"76\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"574.0\" y=\"55.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">2007</text><text x=\"574.0\" y=\"68.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">s7</text><path d=\"M532 34 L532 128\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"532\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">celular A: cursor 2006</text><text x=\"532\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">after=2006 → 1 linha, cursor 2007</text><path d=\"M316 34 L316 178\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"322\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">celular B: cursor 6</text><text x=\"322\" y=\"210\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">after=6 → 2001 linhas, cursor 2007</text></svg>", "caption": "O aparelho guarda o seu lugar num histórico que o servidor escreve. O custo de uma busca acompanha o quanto ela precisa ler, não o quanto existe."}
```

## Buscar pelo cursor

Apague o `planner.db` para o aparelho começar vazio, e busque pelo cursor três vezes: uma a partir
do nada, uma sem nada mudado e uma depois de outro celular mudar uma sessão:

```
ana@dev:~/planner/delta$ rm planner.db
ana@dev:~/planner/delta$ node pull.ts delta
received 2006 rows, 217863 bytes; cursor 2006; 2006 sessions on the device
ana@dev:~/planner/delta$ node pull.ts delta
received 0 rows, 28 bytes; cursor 2006; 2006 sessions on the device
ana@dev:~/planner/delta$ curl -s -o /dev/null -X PUT -d '{"course":"guitar","date":"2026-10-23","minutes":25}' 'http://127.0.0.1:8011/sessions/s7?stamp=2026-10-21T10:00:00Z'
ana@dev:~/planner/delta$ node pull.ts delta
received 1 row, 132 bytes; cursor 2007; 2007 sessions on the device
```

A primeira busca é tão grande quanto buscar tudo, porque um aparelho vazio tem tudo a aprender.
Depois disso **o custo acompanha a mudança**. Sem nada novo, 28 bytes: o cursor e uma lista vazia.
Com uma sessão escrita, uma linha, 132 bytes, e o cursor vai para 2007. A resposta e o marcador
chegam juntos, e o `pull.ts` grava as linhas e o cursor novo numa transação, pelo mesmo motivo que
levou a aula 8 a gravar a linha da caixa de saída com a mudança: um cursor salvo sem as linhas dele
as pularia para sempre, e linhas salvas sem o cursor só são buscadas duas vezes.

## O que o cursor não é

O cursor é opaco para o aparelho. Aqui ele é um número, e mesmo assim o aparelho não deve fazer
contas com ele, compará-lo com o de outro servidor ou inventar um. Um servidor é livre para trocá-lo
por uma string que codifica uma partição e uma posição, e muitos de verdade fazem isso. **O aparelho
guarda o que recebeu e devolve.**

Ele também é por aparelho. Cada celular tem a própria posição no mesmo histórico, e é isso que deixa
o servidor responder a dois celulares que sincronizaram com uma semana de diferença sem guardar nada
por celular. O que o servidor precisa guardar é o próprio histórico, até o cursor mais antigo que
alguém ainda tenha, e a aula 12 é o que acontece quando ele para de guardar.
