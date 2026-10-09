---
title: Avisar a ANPD, as pessoas afetadas e vocês mesmos
version: 1
---

A aula 12 nomeou a regra: o art. 48 da LGPD obriga o controlador a comunicar à ANPD e aos titulares
um incidente de segurança que possa lhes causar risco ou dano relevante, e a Resolução CD/ANPD nº 15
de 2024 fixa o prazo em três dias úteis. Esta seção a aplica ao INC-7.

## É comunicável?

A Resolução 15 chama de relevante o incidente em que duas coisas valem. Ele pode afetar
significativamente os interesses e direitos dos titulares, **e** envolve pelo menos um item de uma
lista curta: dados sensíveis, dados de crianças, adolescentes ou idosos, dados financeiros, dados de
autenticação, dados protegidos por sigilo, ou dados em larga escala. Dois registros de pagamento,
com nome, CPF e valor, lidos por um endereço desconhecido, são dados financeiros nas mãos de alguém
que os pegou de propósito. O curso lê o INC-7 como comunicável. **A decisão é do encarregado**,
tomada no dia e escrita na linha do tempo com os motivos, seja qual for: um incidente julgado não
comunicável também precisa do argumento registrado.

## O prazo, contado

Três dias úteis é fácil de contar errado numa sexta-feira. Os feriados de que a contagem precisa,
escritos pelo curso; cole:

```sh
cat > ~/guard/data/holidays.txt <<'EOF'
# National holidays in Brazil for the rest of 2026, from federal law.
# State and city holidays are added by whoever runs this where they apply.
2026-10-12 Our Lady of Aparecida
2026-11-02 All Souls' Day
2026-11-15 Proclamation of the Republic
2026-11-20 Black Consciousness Day
2026-12-25 Christmas Day
EOF
```

Salve o contador como `~/guard/tools/anpd.py`:

```python
# anpd.py: the deadline for telling the ANPD and the people affected.
#
#   guard anpd --known DATE [--days N]
#
# Resolution CD/ANPD nº 15 of 2024 gives three working days, counted from
# the day the controller learns that the incident affected personal data.
# The course counts that day as day zero and the next working day as day
# one. A working day here is Monday to Friday and not a national holiday in
# data/holidays.txt; a real deployment adds its state's and its city's.
import argparse
import datetime as dt
import os

p = argparse.ArgumentParser(prog="guard anpd")
p.add_argument("--known", required=True)
p.add_argument("--days", type=int, default=3)
a = p.parse_args()

holidays = {}
with open(os.path.expanduser("~/guard/data/holidays.txt"), encoding="utf-8") as f:
    for line in f:
        if line.strip() and not line.startswith("#"):
            day, name = line.rstrip("\n").split(" ", 1)
            holidays[dt.date.fromisoformat(day)] = name

day = dt.date.fromisoformat(a.known)
print("%s  %-9s day 0, the incident is known" % (day, day.strftime("%A")))
count = 0
while count < a.days:
    day += dt.timedelta(days=1)
    if day.weekday() >= 5:
        print("%s  %-9s not a working day" % (day, day.strftime("%A")))
    elif day in holidays:
        print("%s  %-9s not a working day: %s" % (day, day.strftime("%A"), holidays[day]))
    else:
        count += 1
        print("%s  %-9s working day %d" % (day, day.strftime("%A"), count))
print("deadline: the end of %s" % day)
```

```
ana@lab:~/guard$ guard anpd --known 2026-10-09
2026-10-09  Friday    day 0, the incident is known
2026-10-10  Saturday  not a working day
2026-10-11  Sunday    not a working day
2026-10-12  Monday    not a working day: Our Lady of Aparecida
2026-10-13  Tuesday   working day 1
2026-10-14  Wednesday working day 2
2026-10-15  Thursday  working day 3
deadline: the end of 2026-10-15
```

**Quinta, 15 de outubro, não segunda, 12.** "Três dias" contados no calendário caem num feriado;
três dias úteis pulam o fim de semana e Nossa Senhora Aparecida. O outro erro vai na direção
contrária: o prazo começa no dia em que a Tarefa soube que dados pessoais foram afetados, a sexta em
que o blast mostrou as duas leituras, e não quando o relatório fica pronto. Três dias investigando
antes de decidir comunicar são o prazo inteiro perdido. Quando algo ainda é desconhecido no terceiro
dia, a comunicação diz isso e é completada depois; atrasar não é o jeito de esperar pela certeza.

## O que a comunicação diz

O § 1º do art. 48 lista o que entra, e cada item pode ser escrito a partir do arquivo do INC-7:

| o § 1º do art. 48 pede | para o INC-7 |
|---|---|
| a natureza dos dados pessoais afetados | nome, CPF e valor de dois pagamentos |
| informações sobre os titulares envolvidos | dois clientes da Tarefa |
| as medidas técnicas e de segurança usadas para proteger os dados | uma chave com acesso aos registros de pagamento; um canário no prompt de sistema; um alerta sobre ele |
| os riscos relacionados ao incidente | fraude com o CPF, e mensagens aos clientes que citam um pagamento real para parecerem legítimas |
| os motivos da demora, se houver | nenhum, se sair até 15 de outubro |
| as medidas adotadas ou a adotar para reverter ou mitigar os efeitos | chave revogada em 28 minutos; chave nova limitada a reembolsos; prompt corrigido; os clientes avisados |

Os clientes são avisados dentro dos mesmos três dias úteis, em palavras simples: o que aconteceu,
quais dados deles, o que a Tarefa fez, e **o que eles podem fazer**, que aqui é desconfiar de
qualquer mensagem que cite o pagamento deles e peça dinheiro ou um código. Uma mensagem que só pede
desculpas os deixa sem nada para fazer.

## O registro, e a revisão

A Resolução 15 também exige um registro de todo incidente de segurança, comunicado ou não, guardado
por pelo menos cinco anos. O arquivo do INC-7 é o centro dele: o que aconteceu, quando, o que foi
decidido e por quem.

O último passo é a revisão, alguns dias depois, com todos os envolvidos. Ela pergunta como o
incidente se tornou possível e como poderia ter sido pego antes, **nunca quem é o culpado**: uma
revisão que procura culpado ensina as pessoas a escrever linhas do tempo mais vagas. O resultado é
uma lista curta de ações, cada uma com dono e data:

| ação | dono | prazo |
|---|---|---|
| nenhum arquivo sob revisão pode guardar credencial: `keyscan` sobre `data/prompts/` na suíte da aula 23 | ana.lima | 2026-10-16 |
| toda chave restrita ao que os seus usuários precisam, o resto do SEC-42 | bruno.alves | 2026-10-23 |
| a limpeza ganha uma retenção por incidente, para que pausá-la não seja um passo manual | ana.lima | 2026-10-30 |

Cada ação que pode ser verificada vira uma verificação na suíte da aula 23, como falha conhecida com
a data da ação. **Uma revisão cujas ações vivem só num documento é esquecida até o próximo
incidente.** Uma cujas ações estão no build fica vermelha no dia em que uma promessa vence.
