---
title: Um primeiro olhar, e o defeito que estava na frase
version: 1
---

**O jeito mais rápido de ver a diferença entre prevenir um defeito e detectá-lo é acompanhar um mesmo
defeito pelos dois caminhos.** Esta é a primeira coisa que a Lia recebeu no Cine Aurora: a regra de
preço da bilheteria online, do jeito que a Joana, a dona do produto, escreveu para os desenvolvedores.

> **Preço dos ingressos.** Um ingresso custa R$ 36,00 numa sessão que começa às 17:00 ou depois, e
> R$ 28,00 numa que começa antes. Estudantes, maiores de 60 e crianças com menos de 12 pagam meia. Às
> quartas-feiras todo ingresso é meia. Um pedido tem de um a seis ingressos.

E isto é o que o Rafael, um dos dois desenvolvedores, construiu a partir dela. Salve em `~/aurora` como
`tickets.py`. Ninguém espera que você saiba escrevê-lo; leia as notas, e o código ao lado de cada uma,
até conseguir dizer com suas palavras o que cada parte decide.

```schooling-example
{"language": "python", "file": "tickets.py", "parts": [{"code": "# tickets.py\nimport sys\n\nEVENING = 3600\nMATINEE = 2800\n", "note": "Os dois preços cheios, em centavos: R$ 36,00 para uma sessão da noite e R$ 28,00 para uma matinê. O dinheiro fica guardado como um número inteiro de centavos, porque uma fração de real não se paga."}, {"code": "\n\ndef price(age, student, day, time):\n    if time < \"17:00\":\n        full = MATINEE\n    else:\n        full = EVENING\n", "note": "`price` recebe quatro fatos sobre um ingresso e responde quanto ele custa. Primeiro a sessão: a que começa antes das 17:00 é matinê."}, {"code": "    half = False\n    if student:\n        half = True\n    if age > 60:\n        half = True\n    if age < 12:\n        half = True\n", "note": "Depois, quem está comprando. Três tipos de cliente pagam meia: estudante, pessoa idosa, criança. Cada `if` é uma linha do requisito virada código."}, {"code": "    if day == \"wed\":\n        full = full // 2\n    if half:\n        return full // 2\n    return full\n", "note": "Quarta-feira é meia para todo mundo. `//` divide e descarta o resto, que nestes preços é zero."}, {"code": "\n\ndef brl(cents):\n    return f\"R$ {cents // 100},{cents % 100:02d}\"\n", "note": "Transforma 1800 centavos no texto `R$ 18,00`, do jeito que um recibo brasileiro escreve."}, {"code": "\n\nif __name__ == \"__main__\":\n    age, student, day, time = sys.argv[1:]\n    print(brl(price(int(age), student == \"yes\", day, time)))\n", "note": "O que roda quando você digita o comando. As quatro palavras depois de `python tickets.py` são a idade, `yes` ou `no` para estudante, o dia em três letras e o horário da sessão."}]}
```

Rode para quatro clientes: um adulto numa sessão da noite de quinta, um estudante na mesma sessão, uma
criança de oito anos numa matinê de sábado e um adulto numa noite de quarta.

```
lia@lab:~/aurora$ python tickets.py 35 no thu 20:00
R$ 36,00
lia@lab:~/aurora$ python tickets.py 20 yes thu 20:00
R$ 18,00
lia@lab:~/aurora$ python tickets.py 8 no sat 14:00
R$ 14,00
lia@lab:~/aurora$ python tickets.py 35 no wed 20:00
R$ 18,00
```

Cada resposta pode ser conferida com a regra acima sem ler uma linha do programa. R$ 36,00 para o
adulto, metade disso para o estudante, metade de R$ 28,00 para a criança, e meia na quarta. Quatro de
quatro.

## Detectando

A Lia não parou em quatro, porque quatro respostas que batem com a regra não dizem nada sobre as
entradas que ninguém tentou. A regra cita três idades; ela testou as bordas de uma delas.

```
lia@lab:~/aurora$ python tickets.py 61 no thu 20:00
R$ 18,00
lia@lab:~/aurora$ python tickets.py 60 no thu 20:00
R$ 36,00
```

**Quem tem sessenta anos paga inteira.** Com sessenta e um paga meia, então o programa dá o desconto; só
que dá um ano tarde demais. A lei brasileira, o estatuto que protege as pessoas idosas, garante a
meia-entrada a partir dos sessenta, e a bilheteria sempre vendeu assim.

Isso é **detecção**: o defeito existia, uma verificação rodou, e a verificação o expôs. A verificação
foi barata, dois comandos, e foi barata porque o programa era pequeno, ninguém tinha vendido ingresso
com ele ainda e a Lia sabia onde olhar. Cada uma dessas três é uma vantagem que desaparece depois, e
esse é o assunto da aula 3.

## Prevenindo

Agora leia a frase de novo. *Maiores de 60.* Quem tem exatamente sessenta anos é maior de sessenta? O
Rafael leu do jeito que um programador lê `maior`, e escreveu `age > 60`. A Joana quis dizer o que a
bilheteria faz. As duas leituras são razoáveis, e a frase permite as duas.

O defeito **estava no requisito antes de estar no código**, e uma pergunta o teria parado ali: *"maiores
de 60, ou a partir de 60?"*, feita no dia em que a regra foi escrita, por qualquer pessoa que lê uma
frase procurando os dois jeitos de entendê-la. Isso é **prevenção**. Custa uma resposta numa conversa,
nada precisa ser consertado, e nenhum cliente paga o preço errado.

**Garantia de qualidade é as duas coisas, e este curso é sobre saber qual delas um momento pede.** A
detecção precisa que algo exista e custa mais quanto mais tarde roda; a prevenção precisa de alguém que
duvide de um plano e não custa quase nada, mas não pega o que ninguém pensou em perguntar.

O `tickets.py` tem pelo menos mais dois defeitos nas suas quarenta linhas, e nenhum deles aparece nas
quatro respostas acima. As aulas 4 e 6 os encontram. Guarde o arquivo: daqui em diante ele é o sistema
sob teste.
