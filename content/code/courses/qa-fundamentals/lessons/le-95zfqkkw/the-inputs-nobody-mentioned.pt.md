---
title: As entradas que ninguém mencionou
version: 1
---

**Todo requisito descreve as entradas que seu autor imaginou, e todo sistema real recebe outras.** Um
cliente digita uma palavra onde vai um número, deixa um campo vazio, escolhe um horário numa lista que
outra pessoa escreveu. O teste caixa preta tem um segundo hábito, ao lado de combinar condições: dar ao
sistema o que ninguém disse que ele receberia.

## Entradas que o fazem parar

```
lia@lab:~/aurora$ python tickets.py sixty no thu 20:00
Traceback (most recent call last):
  File "/home/lia/aurora/tickets.py", line 33, in <module>
    print(brl(price(int(age), student == "yes", day, time)))
                    ^^^^^^^^
ValueError: invalid literal for int() with base 10: 'sixty'
lia@lab:~/aurora$ python tickets.py 35 no thu
Traceback (most recent call last):
  File "/home/lia/aurora/tickets.py", line 32, in <module>
    age, student, day, time = sys.argv[1:]
    ^^^^^^^^^^^^^^^^^^^^^^^
ValueError: not enough values to unpack (expected 4, got 3)
```

Dois tracebacks: o relato do Python de que o programa parou, com a linha em que parou. De fora, esses são o
resultado certo alcançado do jeito errado. O programa recusou uma idade `sixty` e um horário faltando, o
que está certo; fez isso quebrando em vez de dizer o que estava errado. Para um cliente no site, uma
quebra é uma página em branco ou uma tela de erro, e na linha de comando é uma mensagem que só um
programador consegue ler.

Uma quebra é o tipo de falha mais fácil de julgar, porque **nenhum requisito precisa mencioná-la**. A aula
19 chama isso de oráculo implícito: alguns resultados estão errados diga a regra o que disser, e um
programa que cai diante de uma entrada ruim é um deles.

## Entradas que o fazem mentir

As falhas piores são as silenciosas, em que o programa aceita algo que não deveria e responde mesmo assim,
com um preço confiante.

```
lia@lab:~/aurora$ python tickets.py -5 no thu 20:00
R$ 18,00
lia@lab:~/aurora$ python tickets.py 35 maybe thu 20:00
R$ 36,00
lia@lab:~/aurora$ python tickets.py 35 no Wed 20:00
R$ 36,00
lia@lab:~/aurora$ python tickets.py 35 no thu 25:00
R$ 36,00
```

Cada linha merece uma frase:

- **uma idade de `-5`** é cobrada como criança, porque menos cinco é menor que doze. Ninguém tem menos
  cinco anos; o programa deveria ter recusado;
- **`maybe` para estudante** é lido como não. Só a palavra exata `yes` conta, então qualquer erro de
  digitação tira o desconto em silêncio;
- **`Wed` com W maiúsculo** não é reconhecido como quarta, e o cliente paga inteira no dia mais barato da
  semana;
- **`25:00`** não é um horário, e é cobrado como sessão da noite.

Nenhum deles quebrou, e cada um cobrou um preço. É isso que os torna mais perigosos que os tracebacks:
**nada na tela diz que algo deu errado.** Uma quebra é relatada. Um preço errado para `Wed` é pago.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 230\" role=\"img\" data-fig=\"l06-time-line\" aria-label=\"Três faixas sobre um dia de 00:00 a 24:00. A regra: matinê até 17:00, noite depois. tickets.py com horários escritos com dois dígitos na hora, como 09:30: a mesma divisão, matinê até 17:00 e noite depois. tickets.py com horários escritos com um dígito, como 9:30: da meia-noite à 1:00 é matinê, de 1:00 a 10:00 é noite, e não há horários de um dígito depois das 10:00.\"><text x=\"210.0\" y=\"45.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">a regra</text><rect x=\"220.0\" y=\"30.0\" width=\"311.7\" height=\"30.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"375.8\" y=\"45.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">matinê</text><rect x=\"531.7\" y=\"30.0\" width=\"128.3\" height=\"30.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.1\"></rect><text x=\"595.8\" y=\"45.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">noite</text><text x=\"210.0\" y=\"97.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">tickets.py, horário como 09:30</text><rect x=\"220.0\" y=\"82.0\" width=\"311.7\" height=\"30.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"375.8\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">matinê</text><rect x=\"531.7\" y=\"82.0\" width=\"128.3\" height=\"30.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.1\"></rect><text x=\"595.8\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">noite</text><text x=\"210.0\" y=\"149.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">tickets.py, horário como 9:30</text><rect x=\"220.0\" y=\"134.0\" width=\"18.3\" height=\"30.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><rect x=\"238.3\" y=\"134.0\" width=\"165.0\" height=\"30.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"320.8\" y=\"149.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">noite</text><rect x=\"403.3\" y=\"134.0\" width=\"256.7\" height=\"30.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"531.7\" y=\"149.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">não existem esses horários</text><path d=\"M220.0 186.0 L220.0 192.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"220.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">00:00</text><path d=\"M330.0 186.0 L330.0 192.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"330.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">06:00</text><path d=\"M403.3 186.0 L403.3 192.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"403.3\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10:00</text><path d=\"M440.0 186.0 L440.0 192.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"440.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">12:00</text><path d=\"M531.7 186.0 L531.7 192.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"531.7\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">17:00</text><path d=\"M660.0 186.0 L660.0 192.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"660.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">24:00</text><path d=\"M220.0 186.0 L660.0 186.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path></svg>", "caption": "Comparar horários como texto concorda com a regra para todo horário escrito com dois dígitos, e erra toda hora de 1 a 9 quando ela é escrita com um. Quem testa como caixa preta acha a terceira faixa perguntando como o horário chega ao programa."}
```

## De onde vêm as entradas de um sistema

Se esses casos importam depende de onde as entradas vêm, e isso é uma pergunta para o time, não um chute.
Se o site oferece o dia como uma lista de botões que sempre manda `wed`, um W maiúsculo nunca chega e `Wed`
é uma curiosidade. Se alguém na bilheteria digita o dia, é um defeito esperando a primeira pessoa que
apertar shift. A sessão das 9:30 da aula 4 chegou exatamente assim: uma pessoa digitou um horário numa
lista, e a regra de preço recebeu um formato que ninguém tinha mandado antes.

Então o hábito é: para cada entrada, pergunte **quem ou o que a produz, e o que esse produtor poderia
mandar**. Depois teste as que são possíveis. A resposta para o `tickets.py` foi uma lição de humildade.
Toda entrada chegava a ele como texto que pessoas tinham digitado em algum lugar, e nenhuma era conferida.

## O que a caixa preta achou

Conte os defeitos que esta aula e a aula 4 acharam de fora, sem ler o código: o desconto de quarta se
somando a outro, um horário sem o zero à esquerda, uma quebra com uma palavra onde vai um número, e quatro
tipos de entrada aceitos e cobrados errado em silêncio. A maior parte do que um cliente jamais encontraria
neste programa foi achada assim.

O que a caixa preta não conseguiu achar é qualquer coisa que o programa faça e a que nenhuma entrada da
regra leve. Se o `tickets.py` tivesse uma linha que desse desconto numa data específica, nada na regra da
Joana apontaria para essa data. Achar esse tipo de defeito exige o código, e a aula 7 o abre.
