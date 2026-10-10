---
title: Pondo as hipóteses umas contra as outras
version: 1
---

**Um experimento vale a pena quando o resultado mudaria aquilo em que você acredita.** Rodar de novo a
compra exata da família só confirmaria o que a Célia já disse. As execuções úteis são aquelas em que as
três hipóteses restantes preveem preços *diferentes*.

## É o domingo?

Se o domingo fosse a causa, um adulto numa matinê de domingo à tarde também pagaria o preço da noite. Se
não for, paga R$ 28,00.

```
lia@lab:~/aurora$ python tickets.py 35 no sun 15:00
R$ 28,00
lia@lab:~/aurora$ python tickets.py 8 no sun 9:30
R$ 18,00
```

R$ 28,00. **O domingo não é a causa.** Um comando, uma hipótese a menos. A criança às 9:30 confirma a conta
do balcão: metade do preço da noite, então o desconto da criança funciona e o que está errado é a sessão.

## É a hora, ou o jeito como a hora foi escrita?

Restam duas hipóteses, e elas preveem coisas diferentes para horários diferentes. Se a loja trata qualquer
hora cedo como noite, então 9:30 e 10:00 são ambos cobrados a mais. Se o problema é como o horário foi
escrito, então o mesmo momento escrito de dois jeitos vai dar dois preços.

```
lia@lab:~/aurora$ python tickets.py 35 no sun 9:30
R$ 36,00
lia@lab:~/aurora$ python tickets.py 35 no sun 9:59
R$ 36,00
lia@lab:~/aurora$ python tickets.py 35 no sun 10:00
R$ 28,00
lia@lab:~/aurora$ python tickets.py 35 no sun 09:30
R$ 28,00
```

Isso as separa de forma limpa. **10:00 é matinê e 9:30 não é**, então não é a hora em si. E `9:30` e
`09:30`, o mesmo momento escrito com e sem o zero à esquerda, custam valores diferentes. A terceira
hipótese sobrevive: o horário chegou à regra de preço numa forma que ela não trata.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 230\" role=\"img\" data-fig=\"l04-refutes\" aria-label=\"Uma grade de três hipóteses contra cinco execuções. Execuções: adulto no domingo às 15:00, R$ 28,00; criança no domingo às 9:30, R$ 18,00; adulto às 9:30, R$ 36,00; adulto às 10:00, R$ 28,00; adulto às 09:30, R$ 28,00. A hipótese 1, é o domingo, é refutada pela primeira execução. A hipótese 2, horas cedo contam como noite, é refutada pela execução das 10:00 e pela das 09:30. A hipótese 3, o jeito de escrever o horário, bate com todas.\"><text x=\"256.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">adulto, dom 15:00</text><text x=\"256.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">R$ 28,00</text><text x=\"348.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">criança, dom 9:30</text><text x=\"348.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">R$ 18,00</text><text x=\"440.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">adulto, 9:30</text><text x=\"440.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">R$ 36,00</text><text x=\"532.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">adulto, 10:00</text><text x=\"532.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">R$ 28,00</text><text x=\"624.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">adulto, 09:30</text><text x=\"624.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">R$ 28,00</text><text x=\"200.0\" y=\"86.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">1 · é o domingo</text><rect x=\"213.0\" y=\"67.0\" width=\"86.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"256.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">refutada</text><rect x=\"305.0\" y=\"67.0\" width=\"86.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"348.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">bate</text><rect x=\"397.0\" y=\"67.0\" width=\"86.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"440.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">bate</text><rect x=\"489.0\" y=\"67.0\" width=\"86.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"532.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">bate</text><rect x=\"581.0\" y=\"67.0\" width=\"86.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"624.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">bate</text><text x=\"200.0\" y=\"130.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">2 · horas cedo contam como noite</text><rect x=\"213.0\" y=\"111.0\" width=\"86.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"256.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">bate</text><rect x=\"305.0\" y=\"111.0\" width=\"86.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"348.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">bate</text><rect x=\"397.0\" y=\"111.0\" width=\"86.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"440.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">bate</text><rect x=\"489.0\" y=\"111.0\" width=\"86.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"532.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">refutada</text><rect x=\"581.0\" y=\"111.0\" width=\"86.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"624.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">refutada</text><text x=\"200.0\" y=\"174.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">3 · o jeito de escrever o horário</text><rect x=\"213.0\" y=\"155.0\" width=\"86.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"256.0\" y=\"174.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">bate</text><rect x=\"305.0\" y=\"155.0\" width=\"86.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"348.0\" y=\"174.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">bate</text><rect x=\"397.0\" y=\"155.0\" width=\"86.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"440.0\" y=\"174.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">bate</text><rect x=\"489.0\" y=\"155.0\" width=\"86.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"532.0\" y=\"174.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">bate</text><rect x=\"581.0\" y=\"155.0\" width=\"86.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"624.0\" y=\"174.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">bate</text></svg>", "caption": "Cada execução foi escolhida porque alguma hipótese previa um preço diferente para ela. Só a terceira sobrevive às cinco, e é isso que faz valer a pena abrir o código."}
```

## Por quê, agora que sabemos onde olhar

Só neste ponto vale a pena abrir o `tickets.py`. A linha que decide a sessão é `if time < "17:00":`. O
horário é comparado como **texto**, não como hora do dia, e o Python compara dois textos do jeito que um
dicionário ordena palavras: caractere por caractere, a partir da esquerda. Dá para perguntar diretamente:

```
lia@lab:~/aurora$ python -c 'print("10:00" < "17:00")'
True
lia@lab:~/aurora$ python -c 'print("09:30" < "17:00")'
True
lia@lab:~/aurora$ python -c 'print("9:30" < "17:00")'
False
```

`"9:30" < "17:00"` é falso, porque os primeiros caracteres são comparados primeiro e `9` vem depois de `1`.
Então 9:30 fica arquivado depois de 17:00, como se fosse uma sessão tardia, e é cobrado como uma. `"09:30"`
começa com `0`, que vem antes de `1`, então funciona. Toda sessão que o cinema já tinha tido começava às
10:00 ou depois, e todas têm dois dígitos antes dos dois-pontos. O defeito estava no código desde o
primeiro dia e ninguém conseguia vê-lo, porque **nenhuma entrada jamais tinha tido o formato que chega
nele**. A primeira sessão matinal tinha.

## O que o método comprou

Conte as execuções. Duas para o domingo e a criança, quatro para os horários, três para perguntar ao
Python. Nove comandos, cada um escolhido porque seu resultado podia refutar algo, e o defeito foi de *uma
família foi cobrada a mais no domingo de manhã* para *um horário escrito sem o zero à esquerda é comparado
como texto e tratado como sessão da noite*. Essa é uma frase com que um desenvolvedor age em um minuto, e
com que ninguém discute, porque cada palavra dela vem com um comando que a mostra.

O contraste é com o método que a maioria das pessoas usa primeiro: **mudar alguma coisa, tentar de novo,
repetir até o problema sumir.** Às vezes acha a correção. Raramente acha a causa, não deixa evidência, e um
problema que some sem ser entendido tem o hábito de voltar no domingo seguinte.
