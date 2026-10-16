---
title: Consistência eventual, vista de uma projeção
version: 1
---

**Num sistema com event sourcing os eventos são gravados primeiro e toda projeção fica sabendo deles
depois, então uma projeção está sempre em algum ponto atrás do store, e "eventualmente consistente"
quer dizer que ela chega à ponta do store quando a escrita para.** Quanto atrás, e por quanto tempo,
depende do worker, da carga e do armazenamento em que ele escreve. O store em si nunca está atrás:
um comando dobra o stream, que é a verdade.

A lição 9 de `architecture` trata a consistência eventual como propriedade de sistemas replicados, e
a lição 8 deste curso mostrou a janela de atraso com um worker chamado à mão. Esta seção acrescenta o
que o event sourcing muda: um worker de verdade na sua própria thread, uma posição que diz
exatamente quanto uma projeção está atrás, e um reinício que não perde nada.

```schooling-example
{"language": "python", "file": "lag.py", "parts": [
 {"code": "# lag.py\nimport queue\nimport threading\nimport time\nfrom projections import FinesOwed\nfrom store import EventStore", "note": "A projeção de multas de duas seções atrás e o store, desta vez com uma thread de verdade e uma fila da biblioteca padrão entre eles."},
 {"code": "\nstore = EventStore(\":memory:\")\nfines = FinesOwed()\ninbox: queue.Queue = queue.Queue()", "note": "Um store, uma projeção, uma caixa de entrada. Só a thread principal toca no store; o worker só toca na projeção, e é por isso que nenhuma trava é necessária."},
 {"code": "\n\ndef worker() -> None:\n    while True:\n        position, event = inbox.get()\n        time.sleep(0.05)  # a projection that is slower than the write\n        fines.apply(position, event)\n        inbox.task_done()", "note": "O worker espera eventos, leva um vigésimo de segundo em cada um, como faria uma projeção escrevendo num armazenamento mais lento, aplica-o e avisa que terminou."},
 {"code": "\n\npublished = 0\n\n\ndef record(stream: str, events: list[dict]) -> None:\n    global published\n    store.append(stream, store.version(stream), events)\n    for published, event in store.read_all(after=published):\n        inbox.put((published, event))", "note": "Registrar uma mudança: acrescentar ao store e depois entregar à caixa de entrada todo evento que o store ainda não entregou. `published` é a posição do último entregue."},
 {"code": "\n\nif __name__ == \"__main__\":\n    threading.Thread(target=worker, daemon=True).start()\n    record(\"member-dani\", [{\"type\": \"CopyLent\", \"copy\": \"C1\", \"title\": \"Dom Casmurro\"},\n                           {\"type\": \"CopyReturned\", \"copy\": \"C1\", \"fine\": 100}])\n    print(\"just after the return:\", fines.owed, \"| projection at\", fines.position, \"of 2\")\n    inbox.join()\n    print(\"after the worker caught up:\", fines.owed, \"| projection at\", fines.position, \"of 2\")\n\n    record(\"member-dani\", [{\"type\": \"FinePaid\", \"amount\": 100}])\n    print(\"just after paying:\", fines.owed, \"| projection at\", fines.position, \"of 3\")\n    inbox.join()\n    print(\"after the worker caught up:\", fines.owed, \"| projection at\", fines.position, \"of 3\")", "note": "A Dani devolve um livro atrasado, e a projeção é lida na hora, e depois de `inbox.join()`, que espera o worker aplicar tudo o que está na fila. O mesmo de novo para o pagamento dela."},
 {"code": "\n    restarted = FinesOwed()\n    restarted.position, restarted.owed = 2, {\"dani\": 100}  # its saved checkpoint\n    for position, event in store.read_all(after=restarted.position):\n        restarted.apply(position, event)\n    print(\"restarted from its checkpoint at 2:\", restarted.owed, \"| at\", restarted.position)", "note": "Por fim, uma projeção reiniciada a partir de um checkpoint que tinha salvo na posição 2. Ela lê só o que veio depois, e chega à mesma resposta da que nunca parou."}
]}
```

```
ana@laptop:~/patterns/events$ python3 lag.py
just after the return: {} | projection at 0 of 2
after the worker caught up: {'dani': 100} | projection at 2 of 2
just after paying: {'dani': 100} | projection at 2 of 3
after the worker caught up: {'dani': 0} | projection at 3 of 3
restarted from its checkpoint at 2: {'dani': 0} | at 3
```

Lida logo depois da devolução atrasada da Dani, a projeção está vazia e na posição 0 de 2: o worker
ainda não tinha terminado o primeiro evento. Depois do `join` ela mostra os 100 centavos devidos, em
2 de 2. O pagamento repete o padrão, e a projeção reiniciada, partindo da posição 2 salva, aplica um
evento e concorda: a Dani não deve nada.

**Desta vez o tempo é real, e em princípio ele varia.** O worker dorme 50 milissegundos por evento, e
a thread principal lê depois de microssegundos, então em qualquer máquina comum a primeira leitura
acontece antes de o primeiro evento ser aplicado; numa máquina muito carregada os números poderiam
ser outros. As posições são o que torna a janela descritível: a projeção está em 0 enquanto o store
está em 2, diga o relógio o que disser.

## A posição é o vocabulário

O checkpoint de uma projeção e a ponta do store são dois números, e a diferença entre eles é o
atraso, medido em eventos. **Esse número é o que um sistema mostra, monitora com alertas e espera.**
Uma tela pode dizer "atualizado às 14:02:31" carregando a hora do último evento aplicado; um comando
pode devolver a posição que gravou, e a página seguinte pode esperar a projeção chegar lá, o remédio
que a lição 8 chamou de esperar pela posição. Um operador vigia a distância: uma projeção cujo
checkpoint não se move há dez minutos enquanto a ponta se move é um worker travado.

## Reiniciar, e aplicar duas vezes

Um worker que cai depois de aplicar um evento mas antes de salvar o checkpoint vai, ao reiniciar, ler
esse evento de novo. **A entrega de um store para uma projeção é pelo menos uma vez**, então uma
projeção precisa sobreviver a ver um evento duas vezes. Duas respostas comuns:

| abordagem | como funciona |
|---|---|
| salvar o checkpoint junto com o resultado | gravar as linhas da projeção e a posição numa transação, para os dois avançarem ou nenhum |
| tornar cada aplicação idempotente | `FinesOwed` lembraria as posições já aplicadas e pularia uma repetição, ou atribuiria valores em vez de somá-los |

`FinesOwed` aqui não faz nenhuma das duas, já que vive em memória e parte de um checkpoint conhecido,
e esse é o limite honesto de uma demonstração deste tamanho. No SQLite ou no PostgreSQL a primeira
abordagem é a escolha de costume: as tabelas da projeção e uma tabela `checkpoint` de uma linha,
atualizadas na mesma transação, o que a lição 10 explica.

## Ordem

Os eventos de um stream são aplicados em ordem de versão, e a `position` do store dá uma ordem única
entre streams. Uma projeção que lê por posição vê os eventos de todos os membros na ordem em que
foram gravados, que é aquilo de que `FinesOwed` depende. Stores distribuídos muitas vezes garantem
ordem só dentro de um stream, e aí uma projeção que combina dois streams precisa tolerar ver uma
devolução antes do empréstimo que ela encerra. É um motivo para manter os fatos de que uma projeção
precisa dentro de um evento, como `CopyReturned` carrega a própria multa.
