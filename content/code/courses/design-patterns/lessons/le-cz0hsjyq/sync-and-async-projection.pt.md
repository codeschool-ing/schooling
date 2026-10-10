---
title: Projeção síncrona e assíncrona
version: 1
---

**Um projetor pode rodar dentro do comando, para o modelo de leitura estar em dia antes de o comando
retornar, ou depois dele, para o comando ser rápido e o modelo de leitura alcançá-lo mais tarde.** O
primeiro mantém toda tela exata e amarra a velocidade e a disponibilidade da escrita às de cada
modelo de leitura. O segundo libera a escrita e deixa a tela desatualizada por um tempo. Nenhum dos
dois é o jeito CQRS; escolher é a decisão, e ela é tomada por modelo de leitura, não por sistema.

O erro a evitar é achar que a projeção assíncrona deixa o sistema errado. O modelo de escrita nunca
está desatualizado: ele recusa o empréstimo de um exemplar emprestado no instante em que o exemplar
sai. O que pode ficar desatualizado é uma tela, e a pergunta é se quem a lê consegue perceber, e se
isso importa.

```schooling-example
{"language": "python", "file": "lag.py", "parts": [
 {"code": "# lag.py\nfrom collections import deque\nfrom datetime import date\nfrom commands import Lending, LendCopy, handle\nfrom read_model import CATALOGUE, Availability", "note": "O modelo de escrita e o modelo de leitura de disponibilidade dos dois programas anteriores, sem mudança."},
 {"code": "\n\nclass Outbox:\n    def __init__(self, projection: Availability):\n        self.projection = projection\n        self.pending: deque = deque()\n        self.published = 0\n        self.applied = 0\n\n    def publish(self, event) -> None:\n        self.pending.append(event)\n        self.published += 1\n\n    def pump(self) -> None:\n        while self.pending:\n            self.projection.apply(self.pending.popleft())\n            self.applied += 1", "note": "Entre eles, uma fila. `publish` é o que o modelo de escrita chama: só acrescenta. `pump` é o worker: aplica o que estiver esperando. Os dois contadores dizem o quanto o modelo de leitura está atrasado."},
 {"code": "\n\ndef screen(shelf: Availability, outbox: Outbox, label: str) -> None:\n    rows = {title: n for title, _, n in shelf.available_now()}\n    lag = outbox.published - outbox.applied\n    print(f\"{label:<28} Dom Casmurro on shelf: {rows.get('Dom Casmurro', 0)}\"\n          f\"   ({lag} event{'s' if lag != 1 else ''} behind)\")", "note": "A tela do balcão, que lê só o modelo de leitura e imprime quantos eventos ele ainda não viu."},
 {"code": "\n\nif __name__ == \"__main__\":\n    day = date(2026, 3, 2)\n\n    print(\"-- synchronous: the projection runs inside the command\")\n    lending, shelf = Lending({\"C1\": \"T1\", \"C2\": \"T1\"}), Availability(CATALOGUE)\n    outbox = Outbox(shelf)\n    lending.listeners += [outbox.publish, lambda e: outbox.pump()]\n    handle(lending, LendCopy(\"C1\", \"bia\", day))\n    screen(shelf, outbox, \"right after lending C1\")", "note": "Primeiro o arranjo síncrono: a fila é esvaziada dentro da mesma chamada que publicou, então o modelo de leitura está em dia antes de `handle` retornar."},
 {"code": "\n    print(\"-- asynchronous: the projection runs when the worker gets to it\")\n    lending, shelf = Lending({\"C1\": \"T1\", \"C2\": \"T1\"}), Availability(CATALOGUE)\n    outbox = Outbox(shelf)\n    lending.listeners.append(outbox.publish)\n    handle(lending, LendCopy(\"C1\", \"bia\", day))\n    screen(shelf, outbox, \"right after lending C1\")\n    handle(lending, LendCopy(\"C2\", \"caio\", day))\n    screen(shelf, outbox, \"right after lending C2\")\n    outbox.pump()\n    screen(shelf, outbox, \"after the worker ran\")", "note": "Depois os mesmos comandos sem ninguém esvaziar a fila até o fim. Num sistema de verdade o worker roda em outra thread ou processo e ninguém escolhe o momento; aqui ele é chamado à mão para toda execução imprimir as mesmas linhas."}
]}
```

```
ana@laptop:~/patterns/cqrs$ python3 lag.py
-- synchronous: the projection runs inside the command
right after lending C1       Dom Casmurro on shelf: 1   (0 events behind)
-- asynchronous: the projection runs when the worker gets to it
right after lending C1       Dom Casmurro on shelf: 2   (1 event behind)
right after lending C2       Dom Casmurro on shelf: 2   (2 events behind)
after the worker ran         Dom Casmurro on shelf: 0   (0 events behind)
```

No modo síncrono, a tela mostra um exemplar sobrando no instante em que o C1 é emprestado. No
assíncrono, ela continua dizendo 2 depois que o C1 sai, e ainda 2 depois que o C2 sai, dois eventos
atrasada; só quando o worker roda ela pula para 0. Durante essa janela a tela do balcão oferece um
livro que não está na estante.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l08-lag\" aria-label=\"Uma linha do tempo da execução assíncrona de lag.py, da esquerda para a direita. Faixa de cima, o modelo de escrita: C1 é emprestado à Bia, depois C2 ao Caio, e depois de cada um o modelo de escrita sabe o novo número de exemplares na estante, 1 e depois 0. Faixa de baixo, o modelo de leitura: ele continua dizendo 2 depois dos dois empréstimos, porque os dois eventos estão esperando na caixa de saída. Quando o worker roda, aplica os dois e o modelo de leitura diz 0. O trecho entre o primeiro empréstimo e a execução do worker é a janela em que uma consulta vê o valor antigo.\"><defs><marker id=\"l08-lag-dp-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l08-lag-dp-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20.0\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">modelo de escrita</text><text x=\"20.0\" y=\"170.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">modelo de leitura</text><path d=\"M230.0 170.0 L570.0 170.0\" stroke=\"var(--scan)\" stroke-width=\"40\" fill=\"none\"></path><path d=\"M140.0 70.0 L700.0 70.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-lag-dp-ah-paper-dim)\"></path><path d=\"M140.0 170.0 L700.0 170.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-lag-dp-ah-paper-dim)\"></path><text x=\"690.0\" y=\"248.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">tempo</text><circle cx=\"230.0\" cy=\"70.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"230.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">lend C1</text><text x=\"270.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">na estante 1</text><path d=\"M230.0 76.0 L230.0 108.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l08-lag-dp-ah-amber)\"></path><text x=\"230.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">evento na fila</text><circle cx=\"380.0\" cy=\"70.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"380.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">lend C2</text><text x=\"420.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">na estante 0</text><path d=\"M380.0 76.0 L380.0 108.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l08-lag-dp-ah-amber)\"></path><text x=\"380.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">evento na fila</text><text x=\"160.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">na estante 2</text><text x=\"400.0\" y=\"205.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">desatualizado: na estante 2, eventos esperando</text><circle cx=\"570.0\" cy=\"170.0\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"570.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">o worker aplica os dois</text><text x=\"630.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">na estante 0</text></svg>", "caption": "O modelo de escrita fica certo na hora; o de leitura, depois que o worker roda. O trecho sombreado é o atraso que um leitor consegue ver."}
```

## O que a janela custa

**O lado da escrita continua recusando corretamente.** Se o balcão, enganado pela tela, manda
`LendCopy` para o C2 uma segunda vez, `Lending` recusa: a regra lê o modelo de escrita, que soube na
hora. Leituras desatualizadas causam viagens perdidas e telas confusas, não regras quebradas, desde
que **nenhuma regra jamais leia um modelo de leitura**. Um handler que conferisse a disponibilidade
consultando `Availability` transformaria o atraso num bug de correção.

O pior caso é quem acabou de agir. A Bia pega um livro, a página recarrega a partir do modelo de
leitura, e o empréstimo dela não está lá. Ela tenta de novo e o lado da escrita recusa, porque ela já
está com ele. É o problema de *ler as próprias escritas* que a lição 9 de `architecture` descreve
para réplicas, chegando aqui por um projetor. Os remédios de costume, em ordem de custo:

| remédio | como funciona aqui |
|---|---|
| mostrar o resultado do comando, não uma consulta nova | o balcão imprime "C1 emprestado, vence 16/03" a partir do que mandou, e atualiza a lista depois |
| esperar pela posição | o comando devolve quantos eventos foram publicados; a tela espera até `applied` chegar lá |
| projetar de forma síncrona só para esta tela | os empréstimos do próprio membro são projetados no comando; as contagens da estante continuam assíncronas |

O segundo remédio é o motivo de `Outbox` contar. Um número de versão ou uma posição no log viajando
da escrita até a tela é como sistemas reais fazem isso, com nomes como *causality token*.

## Escolher

Projete de forma síncrona quando a escrita e a leitura dividem um banco, os modelos de leitura são
poucos e baratos de atualizar, e alguém vai olhar a tela logo depois de agir: o balcão de empréstimos
é esse caso. Projete de forma assíncrona quando um modelo de leitura é lento de atualizar, mora em
outro armazenamento, ou faria toda escrita falhar quando estivesse fora do ar; um índice de busca
reconstruído a partir dos empréstimos é esse caso. A maioria dos sistemas mistura os dois, e a
tabela acima é o vocabulário para dizer quais telas toleram quanto atraso.

A fila aqui é uma lista em memória, então uma queda entre a escrita e o worker perde os eventos.
Filas de saída de verdade são gravadas na mesma transação da escrita, para um evento existir
exatamente quando a sua mudança existe, e um processo separado os encaminha; as transações da lição
10 são o que torna isso possível.
