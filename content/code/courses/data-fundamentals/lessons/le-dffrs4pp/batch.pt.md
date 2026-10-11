---
title: Lote, um job sobre uma janela que já fechou
version: 1
---

**Um job em lote responde a uma pergunta sobre uma janela que já fechou.** As viagens de segunda por
estação podem ser contadas depois que a segunda acaba, e não antes: até a meia-noite ainda podem
começar viagens. Então o job é agendado para depois do fim da janela, lê tudo o que está dentro dela e
escreve uma resposta.

Na Roda Livre esse job roda à 01:00, toda noite, para o dia anterior. Alguma coisa precisa iniciá-lo à
01:00, conferir que terminou e iniciá-lo de novo quando falha; isso é um agendador ou um orquestrador, e
é em `pipelines-etl` que eles são construídos. Aqui você inicia o job à mão. Salve-o como
`stream/daily.py`:

```python
# stream/daily.py
import csv
import json
import sys
from collections import Counter

day = sys.argv[1]                                     # the window: one whole day
asof = sys.argv[2] if len(sys.argv) > 2 else '9999'  # only what had arrived by then
rides = Counter()
with open('docks.jsonl') as f:
    for line in f:
        e = json.loads(line)
        if e['kind'] == 'undock' and e['event_time'].startswith(day) and e['arrived'] < asof:
            rides[e['station']] += 1
with open(f'daily-{day}.csv', 'w', newline='') as f:  # the day's file, replaced whole
    out = csv.writer(f)
    out.writerow(['station', 'rides'])
    out.writerows(sorted(rides.items()))
print(f'{day}: {sum(rides.values())} rides, written to daily-{day}.csv')
```

Uma viagem começa com um `undock`, então o job conta os `undock` cujo `event_time` cai no dia. O segundo
argumento existe só para esta aula. O arquivo já tem as três manhãs, e um job que tivesse rodado de
verdade à 01:00 de terça só poderia ter visto o que havia chegado até então; o `asof` faz o programa ver
exatamente isso e nada depois. Rode a segunda-feira como o job da 01:00 teria rodado:

```
ana@lab:~/roda/stream$ python daily.py 2025-10-06 "2025-10-07 01:00"
2025-10-06: 118 rides, written to daily-2025-10-06.csv
ana@lab:~/roda/stream$ cp daily-2025-10-06.csv first-run.csv
```

O gerador fez 120 viagens por manhã, então faltam duas, e nada na saída diz isso. A cópia,
`first-run.csv`, guarda essa resposta para comparar depois.

## Um backfill é o mesmo job, rodado de novo para janelas no passado

As duas viagens que faltam saíram do Passeio Público, cujos sensores perderam o link às 09:20 de segunda
e mandaram tudo o que guardavam às 07:02 de terça, seis horas depois de o job ter rodado. A janela
estava fechada pelo relógio e ainda aberta de fato.

**Rodar um job em lote de novo sobre janelas que já foram processadas é um backfill.** Isso acontece por
três motivos corriqueiros: dados que chegaram depois de o job rodar, um bug corrigido no job, e uma
coluna nova que alguém quer para o histórico inteiro e não só de hoje em diante. Aqui é o primeiro
motivo, e o backfill roda o job para os três dias:

```
ana@lab:~/roda/stream$ for day in 2025-10-06 2025-10-07 2025-10-08; do python daily.py $day; done
2025-10-06: 120 rides, written to daily-2025-10-06.csv
2025-10-07: 120 rides, written to daily-2025-10-07.csv
2025-10-08: 120 rides, written to daily-2025-10-08.csv
ana@lab:~/roda/stream$ diff first-run.csv daily-2025-10-06.csv
5c5
< ST04,8
---
> ST04,10
```

A segunda-feira agora tem as suas 120 viagens, e a única linha que mudou é a do Passeio Público, `ST04`,
de 8 para 10.

Duas coisas tornaram isso seguro, e as duas vêm da aula 3. O job **substitui** o arquivo do dia em vez
de acrescentar a ele, então rodá-lo duas vezes deixa uma resposta, e não duas somadas. E os eventos
brutos são **guardados**: um backfill lê o passado de novo, e só consegue fazer isso se o passado não
foi jogado fora depois da primeira execução.

## No que o lote é bom

Um job em lote é simples de escrever, simples de testar e simples de rodar de novo. Ele vê a janela
inteira de uma vez, então uma contagem, uma junção ou um ranking é calculado sobre tudo. Quando falha, é
iniciado de novo, e nada se perdeu nesse meio-tempo porque a entrada continua lá. Entre uma execução e
outra, não custa nada.

O que ele não consegue é responder cedo. Uma viagem que começou às 08:00 de segunda aparece num
relatório à 01:00 de terça, dezessete horas depois, e esse atraso faz parte do projeto, não é culpa de
uma máquina lenta. Quando uma resposta vale menos depois de dezessete horas, ou depois de dezessete
minutos, o job precisa de outro formato.
