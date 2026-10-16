---
title: Dois números com um nome só
version: 1
---

A Ipê Crédito usa a palavra *inadimplência* em dois lugares. No relatório que vai para fora, e na
seção de risco de crédito da aula 17, um empréstimo está inadimplente quando uma parcela tem **90 dias
ou mais de atraso**, a linha que os reguladores bancários que seguem os padrões do Comitê de Basileia
traçam. No painel da equipe de cobrança, um empréstimo está "inadimplente" a partir de **30 dias**,
porque é quando a equipe começa a ligar, e um empréstimo que espera até 90 dias por uma ligação é bem
mais difícil de recuperar. Em inglês os dois viram *default*, e a confusão é a mesma nas duas línguas.

Nenhuma das definições está errada. Elas servem a duas decisões diferentes: o relatório de fora diz
quanto da carteira está em problema sério, por uma regra que toda financeira aplica do mesmo jeito; o
número da cobrança diz quantos clientes precisam de uma ligação nesta semana. **A armadilha é a
reunião em que os dois números são postos lado a lado com o mesmo nome**, e alguém pergunta qual está
certo.

## Uma carteira, duas respostas

Doze empréstimos pessoais da Ipê em 31 de dezembro de 2025, escolhidos para mostrar todos os casos, e
não sorteados como amostra da carteira. A coluna B são os dias de atraso nessa data e a coluna C o
saldo devedor, em milhares de reais:

| | A | B | C |
|---|---|---|---|
| 1 | Empréstimo | Dias de atraso | Saldo |
| 2 | 1 | 0 | 8,4 |
| 3 | 2 | 0 | 12 |
| 4 | 3 | 12 | 5,6 |
| 5 | 4 | 35 | 9,8 |
| 6 | 5 | 0 | 15,2 |
| 7 | 6 | 95 | 7,1 |
| 8 | 7 | 41 | 6,3 |
| 9 | 8 | 0 | 11,5 |
| 10 | 9 | 130 | 4,2 |
| 11 | 10 | 8 | 10 |
| 12 | 11 | 62 | 7,7 |
| 13 | 12 | 0 | 9,6 |

Em D1 digite `90+` e em E1 `30+`. Na linha 2, uma marca para cada definição, copiada até a linha 13:

```localised
=SE(B2>=90;1;0)      0
=SE(B2>=30;1;0)      0
```

Na linha 14, as somas de C, D e E. Depois, a parcela do saldo em cada definição. Multiplicar cada
saldo pela sua marca e somar é o que `SOMARPRODUTO` faz:

```localised
=SOMA(C2:C13)      107,4
=SOMARPRODUTO(C2:C13;D2:D13)      11,3
=ARRED(SOMARPRODUTO(C2:C13;D2:D13)/C14*100;1)      10,5
=ARRED(SOMARPRODUTO(C2:C13;E2:E13)/C14*100;1)      32,7
```

**Os mesmos doze empréstimos estão 10,5% inadimplentes ou 32,7% inadimplentes**, dependendo da
palavra de qual equipe se usa. Contando empréstimos em vez de reais, são 2 contra 5. Nenhum dos dois
números é erro, e se os dois aparecerem num slide com o rótulo "inadimplência", um deles vai ser lido
como o outro.

## Mantenha os dois, rotule os dois, nunca concilie editando

Há três jeitos errados de sair dessa reunião, e os três já foram tentados em algum lugar:

- **descartar um**: a cobrança perde o alerta antecipado com que trabalha, ou o conselho perde o
  número que o regulador vê;
- **fazer a média ou "ajustar"** até os dois ficarem parecidos, o que produz um número que não bate
  com definição nenhuma;
- **editar o número de fora** para concordar com um relatório interno que alguém já apresentou, o que
  transforma um problema de rótulo num relatório falso.

O jeito certo é sem graça. **Cada número ganha o seu próprio nome e o seu próprio cartão de
definição**: os painéis da Ipê dizem *inadimplência (90+ dias, regulatória)* e *atraso (30+ dias,
cobrança)*, e o cartão da aula 10 de cada um diz a fonte. Onde os dois aparecem na mesma página,
aparecem juntos e com os nomes, e a diferença entre eles vira informação em vez de contradição. A
visão mensal de risco de Fernanda mostra as duas linhas num gráfico só: a linha de 30+ se mexe
primeiro e a de 90+ vem dois meses depois, que é o alerta antecipado que a cobrança existe para usar.

A regra vale além das financeiras. O tempo de espera interno de um hospital e o que ele informa a um
regulador podem começar a contar em momentos diferentes; a taxa de refugo interna de uma fábrica e a
do acordo de qualidade com um cliente podem contar defeitos diferentes. **Onde uma regra de fora
define um número, a versão de dentro ganha outro nome**, e ninguém muda o de fora para concordar.
