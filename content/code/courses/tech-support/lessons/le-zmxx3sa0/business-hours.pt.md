---
title: Contando em horário comercial
version: 1
---

Contar horas comerciais à mão dá errado nas bordas do dia e da semana. Algumas linhas de Python fazem isso
do mesmo jeito toda vez:

```schooling-example
{"language": "python", "parts": [{"code": "import sys\nfrom datetime import datetime, timedelta", "note": "Só a biblioteca padrão: datas, e os argumentos da linha de comando."}, {"code": "OPEN, CLOSE = 8, 18           # the service desk's hours\nWORKDAYS = range(0, 5)        # Monday to Friday; datetime counts Monday as 0", "note": "**O calendário é o do SLA, não o do relógio.** Esses três números são o que o contrato diz sobre o horário do suporte; um serviço 24 horas não teria nenhum deles."}, {"code": "def deadline(start, hours):\n    t, left = start, timedelta(hours=hours)\n    while left:", "note": "O `t` anda para a frente a partir do momento em que o chamado abriu, e o `left` é quanto do tempo prometido ainda falta gastar."}, {"code": "        if t.weekday() not in WORKDAYS or t.hour >= CLOSE:\n            t = (t + timedelta(days=1)).replace(hour=OPEN, minute=0)", "note": "Fora dos dias úteis, ou depois do fechamento: pula para a abertura da manhã seguinte. Um sábado pula duas vezes, para domingo e depois para segunda."}, {"code": "        elif t.hour < OPEN:\n            t = t.replace(hour=OPEN, minute=0)", "note": "Antes da abertura num dia útil: espera o suporte abrir."}, {"code": "        else:\n            step = min(left, t.replace(hour=CLOSE, minute=0) - t)\n            t, left = t + step, left - step\n    return t", "note": "Dentro do horário: gasta o que falta, ou o que sobra do dia, o que for menor."}, {"code": "start = datetime.strptime(sys.argv[1], \"%Y-%m-%d %H:%M\")\nhours = float(sys.argv[2])\nprint(f\"{start:%a %d/%m %H:%M} + {hours:g} h -> {deadline(start, hours):%a %d/%m %H:%M}\")", "note": "A hora de abertura do chamado e as horas do SLA vêm da linha de comando, e a resposta sai com o dia da semana, porque é o dia da semana que surpreende."}]}
```

Quatro chamados, quatro respostas:

```
ana@host:~$ python3 sla.py "2026-09-24 09:00" 8
Thu 24/09 09:00 + 8 h -> Thu 24/09 17:00
ana@host:~$ python3 sla.py "2026-09-25 16:30" 4
Fri 25/09 16:30 + 4 h -> Mon 28/09 10:30
ana@host:~$ python3 sla.py "2026-09-26 10:00" 1
Sat 26/09 10:00 + 1 h -> Mon 28/09 09:00
ana@host:~$ python3 sla.py "2026-09-25 17:59" 0.25
Fri 25/09 17:59 + 0.25 h -> Mon 28/09 08:14
```

- Oito horas a partir das nove de uma quinta terminam às cinco do mesmo dia: o caso fácil.
- **Quatro horas a partir das quatro e meia de uma sexta terminam às dez e meia de segunda**: uma hora e
  meia na sexta, duas e meia na segunda. Quem abriu ouve "quatro horas" e espera uma resposta antes do fim
  de semana; dizer a hora de verdade faz parte da resposta, aula 4.
- Uma hora a partir de um sábado de manhã começa a contar na segunda às oito.
- Um quarto de hora a partir de um minuto para as seis gasta um minuto na sexta e catorze na segunda.

O que ele deixa de fora são os **feriados**, que mudam por cidade e por ano. Um calendário de SLA de
verdade os lista, e um sistema de chamados lê essa lista; o script também precisaria dela antes que alguém
confiasse nas respostas dele em dezembro.
