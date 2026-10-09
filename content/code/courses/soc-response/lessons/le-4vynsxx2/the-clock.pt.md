---
title: O prazo
version: 1
---

O RCIS dá ao controlador **três dias úteis** para comunicar, tanto à ANPD quanto às pessoas envolvidas, contados de
quando ele **soube** que o incidente afetou dados pessoais. A comunicação pode ser **complementada em até vinte dias
úteis** depois de enviada, então a primeira leva o que se sabe e diz o que ainda está sendo apurado. Um **agente de
tratamento de pequeno porte**, como definido pela Resolução CD/ANPD nº 2, de 2022, tem o **dobro** do prazo; se a
empresa se enquadra é pergunta para o advogado, e o plano seguro não conta com isso.

Quando a empresa soube? O registro da aula 12 responde, e é por isso que o registro tem horário: o incidente foi
declarado às 09:12 de **quinta-feira, 17 de setembro**, e a mensagem das 09:30 já dizia que dados pessoais eram
possíveis. O encarregado toma esse dia como início.

Dias úteis pulam fins de semana e feriados, e uma contagem no calendário é fácil de errar sob pressão. Um programa
curto faz isso. Escreva isto como `prazo.py`:

```schooling-example
{"language": "python", "file": "prazo.py", "parts": [{"code": "# prazo.py START N: the date N business days after START, skipping weekends and the holidays listed\nimport datetime as dt\nimport sys"}, {"code": "\nHOLIDAYS = {  # national holidays from September 2026; add the state's and the city's before relying on it\n    dt.date(2026, 9, 7), dt.date(2026, 10, 12), dt.date(2026, 11, 2),\n    dt.date(2026, 11, 15), dt.date(2026, 11, 20), dt.date(2026, 12, 25),\n}", "note": "Só feriados nacionais, e só a partir de setembro de 2026. Um prazo em São Paulo também pula os do estado e os da cidade, e um advogado confirma a lista."}, {"code": "\n\ndef add_business_days(start, n):\n    day = start\n    while n > 0:\n        day += dt.timedelta(days=1)  # the start day itself never counts\n        if day.weekday() < 5 and day not in HOLIDAYS:\n            n -= 1\n    return day", "note": "Dia a dia a partir do início: o dia do início nunca conta, e um dia só conta se for dia de semana e não for feriado."}, {"code": "\n\nstart = dt.date.fromisoformat(sys.argv[1])\nn = int(sys.argv[2])\nprint(f\"{n} business days after {start:%a %d %b %Y}: {add_business_days(start, n):%a %d %b %Y}\")"}]}
```

Depois, três perguntas: o prazo, o prazo se a empresa for agente de pequeno porte, e o prazo do complemento se a
primeira comunicação sair no último dia permitido:

```
ana@soc:~$ python3 prazo.py 2026-09-17 3
3 business days after Thu 17 Sep 2026: Tue 22 Sep 2026
ana@soc:~$ python3 prazo.py 2026-09-17 6
6 business days after Thu 17 Sep 2026: Fri 25 Sep 2026
ana@soc:~$ python3 prazo.py 2026-09-22 20
20 business days after Tue 22 Sep 2026: Wed 21 Oct 2026
```

**Terça, 22 de setembro** para a comunicação: sexta, depois o fim de semana, depois segunda e terça. Sexta, 25, se o
prazo for dobrado. E **quarta, 21 de outubro** para o complemento, um dia depois do que uma contagem simples de quatro
semanas daria, porque **12 de outubro** é feriado nacional e o programa o pula. Esse um dia é exatamente o tipo de
erro que uma contagem à mão comete.

A lista de feriados é só nacional. Um prazo também é afetado por feriados estaduais e municipais, e pelo jeito como a
própria ANPD conta os dias, então as datas são **conferidas com o advogado** antes de alguém contar com elas. O
trabalho do programa é tornar a contagem visível e repetível, não ser a palavra final.
