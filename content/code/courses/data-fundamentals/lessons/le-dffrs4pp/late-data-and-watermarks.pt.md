---
title: Dados atrasados e marcas d'água
version: 1
---

**Uma janela contada pelo tempo do evento precisa ser enviada em algum momento, e nesse momento o
processador está apostando que nada mais antigo ainda está a caminho.** Espere pouco demais e viagens
que só estavam demoradas se perdem. Espere demais e a resposta das 08:00 chega quando ninguém precisa
mais dela. Nenhuma configuração evita as duas coisas; só dá para escolher qual pagar.

A aposta tem nome. Uma **marca d'água** (*watermark*) é a estimativa contínua do processador de até onde
o tempo do evento já chegou: um momento tal que ele não espera mais eventos de antes dele. Quando a marca
d'água passa do fim de uma janela, a janela é enviada. Um evento que aparece depois, para uma janela já
enviada, é um **dado atrasado** (*late data*). A aula 7 usou a mesma palavra para algo mais simples, a
mudança mais recente que uma cópia incremental já viu; as duas marcam até onde o dado foi lido, e não são
a mesma coisa.

A marca d'água mais simples, e a usada aqui, é o tempo de evento mais recente visto até agora menos um
**atraso permitido** (*allowed lateness*). Se o evento mais recente aconteceu às 08:40 e o atraso
permitido é de dois minutos, a marca d'água é 08:38, e toda janela que termina até 08:38 é enviada.
Processadores de fluxo de verdade a constroem de jeitos mais cuidadosos, a partir do que cada fonte
informa sobre o próprio progresso, mas toda versão é uma estimativa e nenhuma consegue ver um evento que
ainda não chegou. Salve `stream/watermark.py`:

```schooling-example
{"language": "python", "file": "stream/watermark.py", "parts": [
{"code": "# stream/watermark.py\nimport json\nimport sys\nfrom collections import Counter\nfrom datetime import datetime, timedelta\n\nLATENESS = timedelta(minutes=int(sys.argv[1]))   # how late an event may be\nSTART, SIZE = datetime(2025, 10, 6, 8, 0), timedelta(minutes=15)\nrides, closed, dropped = Counter(), set(), []\nwatermark = datetime.min\n", "note": "O atraso permitido vem da linha de comando, em minutos. As janelas são os quatro quartos de hora a partir das 08:00 de segunda. `closed` guarda as janelas já enviadas, e `watermark` começa no momento mais antigo que existe."},
{"code": "with open('docks.jsonl') as f:\n    for line in f:                               # in order of arrival\n        e = json.loads(line)\n        happened = datetime.fromisoformat(e['event_time'])\n        if e['kind'] == 'undock' and START <= happened < START + 4 * SIZE:\n            w = (happened - START) // SIZE\n            if w in closed:\n                dropped.append(e['id'])          # its window has already been sent\n            else:\n                rides[w] += 1\n", "note": "Cada evento na ordem de chegada, que é a ordem em que um fluxo os vê. Um `undock` dentro da hora vai para a sua janela `w`, numerada de 0 a 3, a não ser que essa janela já tenha sido enviada: aí o evento está atrasado, e o id dele vai para `dropped`."},
{"code": "        watermark = max(watermark, happened - LATENESS)\n        for w in range(4):\n            if w not in closed and watermark >= START + (w + 1) * SIZE:\n                closed.add(w)\n                begins = START + w * SIZE\n                print(f'{begins:%H:%M} window sent at {e[\"arrived\"][11:]}: {rides[w]} rides')\n", "note": "Depois de cada evento a marca d'água vai para o horário de evento mais recente menos o atraso permitido, e nunca volta. Toda janela cujo fim ela já passou é enviada: a contagem é impressa com o horário de chegada do evento que levou a marca d'água além dela."},
{"code": "print('dropped as late:', dropped)\n", "note": "Por último, os eventos atrasados que foram descartados."}
]}
```

Rode duas vezes, permitindo dois minutos de atraso e depois vinte e cinco:

```
ana@lab:~/roda/stream$ python watermark.py 2
08:00 window sent at 08:17:27: 19 rides
08:15 window sent at 08:32:10: 20 rides
08:30 window sent at 08:47:37: 14 rides
08:45 window sent at 09:03:32: 8 rides
dropped as late: ['EV00087', 'EV00116', 'EV00137']
ana@lab:~/roda/stream$ python watermark.py 25
08:00 window sent at 08:40:08: 19 rides
08:15 window sent at 08:55:02: 21 rides
08:30 window sent at 09:10:37: 16 rides
08:45 window sent at 09:26:10: 8 rides
dropped as late: []
```

Com dois minutos, cada janela sai uns dois minutos depois de fechar, e o preço são três viagens. Os
eventos do Parque Barigui chegaram ao servidor às 08:51:30, depois que as janelas a que pertenciam já
tinham sido enviadas, e o programa os descartou; as contagens das 08:15 e das 08:30 saíram erradas e
ficaram erradas.

Com vinte e cinco minutos nada é descartado, e as quatro contagens batem com a coluna do tempo do evento
da seção anterior. O preço é tempo: a janela das 08:00, que fechou às 08:15, é enviada às 08:40. **Toda
resposta agora aparece com uns vinte e cinco minutos de idade, inclusive as de todas as manhãs sem
queda nenhuma.**

## O que fazer com um evento atrasado

Descartar é a escolha mais simples, e a que o programa faz. Um processador de fluxo oferece outras, e a
equipe escolhe pergunta por pergunta:

- atualizar a janela: enviar uma contagem corrigida quando uma viagem atrasada chega, o que serve
  quando quem lê a resposta aceita uma correção, como uma tabela que é sobrescrita;
- separar: gravar os eventos atrasados num lugar só deles, para que sejam contados e alguém possa ver
  quantos foram;
- deixar para o lote: o fluxo dá uma resposta rápida, e o job da madrugada, que lê um dia fechado a
  partir dos eventos brutos, dá a correta.

Nenhum atraso permitido menor que um dia teria pegado os eventos do Passeio Público, que chegaram mais
de vinte e uma horas depois de acontecer. É por isso que a última opção é comum, e ela é o formato da
arquitetura que aparece duas seções adiante.
