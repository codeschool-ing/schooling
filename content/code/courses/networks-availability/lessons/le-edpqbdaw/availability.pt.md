---
title: Disponibilidade é um número
version: 1
---

As pessoas descrevem um sistema como confiável, ou dizem que ele nunca cai, e nenhuma das duas coisas dá
para conferir. **Disponibilidade é uma fração: o tempo em que um serviço estava utilizável, dividido pelo
tempo em que deveria estar.** Uma loja que ficou fora do ar por 8 horas e 46 minutos no ano passado esteve
disponível em 99,9% dele, e esse número pode ser comparado com uma promessa, com um concorrente ou com o
ano anterior.

A fração é dita em noves, e o erro comum é ler os noves como quase a mesma coisa. 99% parece quase
perfeito. Permite mais de três dias e meio fora do ar por ano. Cada nove a mais divide a margem por dez,
então o passo de três noves para quatro é o passo de quase um dia de trabalho para menos de uma hora. Este
programa faz a conta para um ano de 365 dias, um doze avos desse ano e um dia:

```schooling-example
{"language": "python", "file": "nines.py", "parts": [{"code": "YEAR = 365 * 24 * 60 * 60  # seconds in a year that is not a leap year", "note": "Um ano de 365 dias, em segundos. Tudo é calculado em segundos e só convertido na hora de imprimir."}, {"code": "for nines in (2, 3, 4, 5):\n    up = 1 - 10 ** -nines  # 0.99, 0.999, 0.9999, 0.99999\n    down = YEAR * (1 - up)  # the seconds the rest of the year is allowed", "note": "Dois noves são 1 − 10⁻², ou seja, 0,99. Cada nove a mais divide por dez o que sobra, e `down` é essa fatia que sobra do ano."}, {"code": "    print(f\"{up * 100:>7g}%  \"\n          f\"{down / 3600:6.2f} h = {down / 60:7.1f} min a year  \"\n          f\"{down / 60 / 12:6.2f} min a month  \"\n          f\"{down / 365:6.2f} s a day\")", "note": "A mesma margem de três jeitos: horas e minutos num ano, minutos em um doze avos do ano e segundos num dia."}], "output": "     99%   87.60 h =  5256.0 min a year  438.00 min a month  864.00 s a day\n   99.9%    8.76 h =   525.6 min a year   43.80 min a month   86.40 s a day\n  99.99%    0.88 h =    52.6 min a year    4.38 min a month    8.64 s a day\n 99.999%    0.09 h =     5.3 min a year    0.44 min a month    0.86 s a day"}
```

Leia as linhas como orçamentos, não como notas. **Com quatro noves a margem do ano inteiro é de 52,6
minutos**, o que é uma atualização feita na hora errada. Com cinco noves são 5,3 minutos, 0,86 de segundo
por dia, e o tempo que uma pessoa leva para ver um alarme e abrir o notebook já gastou isso várias vezes.
Cinco noves nunca se alcançam com gente respondendo rápido. Alcançam-se com máquinas que assumem o lugar
umas das outras sem ninguém envolvido, que é o que as aulas 15 e 16 montam.

Dois detalhes decidem o que um número desses quer dizer, e a aula 17 dá uma seção a cada um. O primeiro é
o que conta como fora do ar: um site que responde depois de trinta segundos está no ar para um ping de
monitoramento e fora do ar para um cliente. O segundo é a janela. Uma margem mensal de 43,80 minutos não
pode ser guardada e gasta numa tarde comprida do mês seguinte.

## Falhar menos, ou voltar mais cedo

Mais dois números andam junto com a disponibilidade. **MTBF**, o tempo médio entre falhas, é quanto
tempo uma coisa funciona antes de quebrar. **MTTR**, o tempo médio de reparo, é quanto tempo ela fica
quebrada depois. A disponibilidade é o MTBF dividido pelo MTBF mais o MTTR, e a fórmula mostra que há
exatamente dois jeitos de aumentá-la: falhar menos vezes, ou voltar mais depressa.

Um servidor que falha uma vez por ano e leva nove horas para um técnico trocar fica em cerca de 99,9%. Dê
a ele um gêmeo que assume em três segundos e o servidor falha exatamente tantas vezes quanto antes, porque
o MTBF dele não mudou. O que mudou foi o tempo de reparo como o cliente o vê, que foi de nove horas para
três segundos, enquanto o servidor quebrado continua esperando o técnico.

**Redundância não faz nada falhar menos. Faz cada falha durar menos**, e tudo nesta aula e nas duas
seguintes se apoia nessa frase. Ela também explica por que redundância não vale nada se a troca for lenta:
um gêmeo que precisa de alguém para entrar e ligá-lo tem o tempo de reparo do técnico, não o da máquina.
