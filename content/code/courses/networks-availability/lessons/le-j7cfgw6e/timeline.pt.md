---
title: Horários, e o fuso em que estão
version: 1
---

A linha do tempo é a espinha de um registro: o que aconteceu, em ordem, com a hora em que cada coisa foi
vista. É como se separa causa de coincidência, como em "os downloads pararam poucos minutos depois de a
mudança no firewall ser aplicada", e como suas notas se alinham com logs de máquinas que você não
administra. Os momentos que merecem uma linha são o primeiro sintoma, o primeiro chamado, o início do
diagnóstico, a causa encontrada, a correção aplicada e a correção conferida, porque **os intervalos entre
eles são aquilo contra o que as promessas da aula 17 são medidas**: tempo para perceber, tempo para
restabelecer.

As transcrições da aula 21 não trazem hora nenhuma. Cada comando e sua saída estão lá, e a ordem deles é
conhecida, mas não quando qualquer um deles rodou, e nada consegue recuperar isso agora. **Essa é a
primeira regra de uma linha do tempo: a hora se escreve quando a coisa é vista**, porque depois ela se
perde. Num terminal isso quer dizer um prompt que mostra a hora, ou um `date` rodado antes de um comando
que importa; nas notas quer dizer o relógio antes da frase. Nenhum dos dois foi feito no laboratório da
aula 21, e por isso o registro dela tem ordem e não tem horários.

Quando os horários são escritos, o fuso decide se eles podem ser comparados. O único horário de relógio
que estas aulas imprimiram está na aula 22, onde o mtr abriu cada relatório com uma linha como `Start:
2026-09-28T18:17:16-0300`. **O `-0300` é a diferença para o UTC**, e está ali porque o relógio do
laboratório segue `America/Sao_Paulo`. Um sistema de chamados em UTC, o suporte de um provedor em outro
país e um console de nuvem num fuso próprio vão escrever o mesmo instante cada um de um jeito. Umas linhas
de Python mostram o que a diferença compra, usando as duas linhas de início do mtr:

```schooling-example
{"language": "python", "file": "when.py", "parts": [{"code": "from datetime import datetime, timezone"}, {"code": "# The two Start lines of the mtr reports in lesson 22, as printed.\nfirst = datetime.strptime(\"2026-09-28T18:17:16-0300\", \"%Y-%m-%dT%H:%M:%S%z\")\nsecond = datetime.strptime(\"2026-09-28T18:17:40-0300\", \"%Y-%m-%dT%H:%M:%S%z\")", "note": "As duas linhas de início exatamente como o mtr as imprimiu na aula 22, lidas com um formato que mantém o `-0300`. O que sai é um instante, não uma leitura de relógio."}, {"code": "print(\"local:\", first.isoformat())\nprint(\"UTC:  \", first.astimezone(timezone.utc).isoformat())\nprint(\"apart:\", second - first)", "note": "O mesmo instante escrito no fuso do laboratório e em UTC, e o intervalo entre os dois relatórios. Subtrair dois instantes que levam a diferença dá certo seja qual for o fuso em que cada um foi escrito."}, {"code": "# The same clock reading with its offset thrown away, then taken for UTC.\nnaive = datetime.strptime(\"2026-09-28 18:17:16\", \"%Y-%m-%d %H:%M:%S\")\nwrong = naive.replace(tzinfo=timezone.utc)\nprint(\"off by:\", first - wrong)", "note": "O erro de que esta seção trata: a leitura do relógio mantida, a diferença jogada fora e o resultado tomado como UTC, como acontece quando uma linha de log é colada num chamado."}], "output": "local: 2026-09-28T18:17:16-03:00\nUTC:   2026-09-28T21:17:16+00:00\napart: 0:00:24\noff by: 3:00:00"}
```

Os dois relatórios começaram com 24 segundos de diferença, e essa diferença é a mesma em qualquer fuso. A
mesma leitura com a diferença jogada fora e tomada como UTC fica **três horas errada**, e três horas
bastam para pôr um efeito antes da causa numa linha do tempo montada a partir de duas fontes.

Então a linha do tempo de um registro segue quatro regras:

1. Todo horário leva a diferença, `2026-09-28T18:17:16-03:00`, ou está em UTC e diz isso com um `Z` ou
   `+00:00`.
2. A linha do tempo escolhe um fuso, em geral o UTC, converte tudo para ele e diz qual no título.
3. Um lugar se registra pelo nome do fuso e um instante pela diferença. São Paulo teve horário de verão
   até 2019, então "horário de São Paulo" num registro antigo não dá a diferença sem a data; a diferença
   no carimbo de hora dá.
4. Os relógios são sincronizados, por NTP, antes de alguém precisar deles. Duas máquinas com alguns
   segundos de diferença trocam a ordem de todo evento que aconteceu dentro desses segundos, e nenhum
   cuidado depois conserta isso.
