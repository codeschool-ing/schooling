---
title: O campo de quantidade
version: 1
---

**O R4 é o requisito com o número que mais importa ao teatro**: "de 1 a 6 ingressos por pedido".
Ele decide quantos lugares uma pessoa pode tirar da venda de uma vez, e a aula 1 pôs o preço de um
pedido, que depende da quantidade, no topo da grade de riscos. Esta seção traça as partições do
campo, escolhe os valores de fronteira, roda-os e encontra o primeiro defeito do curso.

## Partições e fronteiras do R4

A quantidade é um número inteiro de ingressos, então as partições são três faixas, do mesmo
formato dos tamanhos do R2:

- **0 ou menos**, inválida: ninguém reserva nenhum ingresso, e um número negativo não é quantidade;
- **de 1 a 6**, válida: o pedido é reservado;
- **7 ou mais**, inválida: recusada com uma frase dizendo quantos são permitidos.

Existe uma quarta partição, a entrada que nem é um número inteiro, e a seção 05 desta aula dá a ela
uma seção própria. As duas linhas entre as três faixas dão quatro valores de fronteira, 0 e 1, 6 e
7, e um representante do meio da faixa válida, 3, completa cinco casos:

| caso | valor | partição | esperado (R4, R7) |
|---|---|---|---|
| Q1 | 0 | 0 ou menos | recusado, com uma frase |
| Q2 | 1 | de 1 a 6, borda de baixo | pedido reservado |
| Q3 | 3 | de 1 a 6, meio | pedido reservado |
| Q4 | 6 | de 1 a 6, borda de cima | pedido reservado |
| Q5 | 7 | 7 ou mais | recusado, com uma frase |

Todo o resto de cada caso é válido e fixo: a conta de membro, `member@example.org`, que o R4 exige,
e Hamlet, daqui a uma semana, para que nem o horário de fechamento nem os lugares restantes possam
interferir. Cada caso muda uma coisa, a quantidade.

## Rodando os cinco

Reinicie o boxoffice primeiro, para que lugares e pedidos sejam os que a aula 1 descreve. No
navegador, abra **Book**, digite `member@example.org` no campo de e-mail, escolha **Hamlet**,
digite a quantidade no campo marcado *Tickets (1 to 6)* e aperte **Book**. Uma reserva que deu
certo abre uma página com o número do pedido no título; uma que foi recusada volta ao formulário com
uma frase em cima. No terminal, cada caso é uma requisição, e o `grep msg` guarda a linha com essa
frase:

```
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=0' http://127.0.0.1:8000/book | grep msg
<p class="msg">You can book 1 to 6 tickets.</p><form method="post" action="/book">
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=1' http://127.0.0.1:8000/book | grep msg
<p class="msg">Order 1001 reserved.</p>
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=3' http://127.0.0.1:8000/book | grep msg
<p class="msg">Order 1002 reserved.</p>
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=6' http://127.0.0.1:8000/book | grep msg
<p class="msg">You can book 1 to 6 tickets.</p><form method="post" action="/book">
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=7' http://127.0.0.1:8000/book | grep msg
<p class="msg">You can book 1 to 6 tickets.</p><form method="post" action="/book">
```

Quatro dos cinco se comportam: 0 e 7 são recusados com uma frase, 1 e 3 reservam os pedidos 1001 e
1002. **O Q4 falha.** Seis ingressos estão dentro da faixa que o R4 permite e o boxoffice recusa,
com uma frase que contradiz a recusa: "You can book 1 to 6 tickets." Um cliente que quer seis
ingressos para a família ouve que pode ter seis, e não consegue.

Repare em que casos o acharam. O valor do meio, 3, foi reservado. Quem particionasse o campo e
parasse ali teria relatado o R4 como funcionando. O Q5 também se comportou: 7 foi recusado, como
devia. O defeito fica exatamente na fronteira de cima, no único valor que a análise de dois valores
põe do lado válido dessa linha, e em nenhum outro lugar.

## Dizendo exatamente onde está a linha

**Um caso de fronteira que falha levanta uma pergunta antes de ser registrado: onde está a linha
de verdade?** "O 6 é recusado" pode querer dizer que o limite é 5, ou que o 6 tem algo de especial,
ou que todo número acima de algum valor falha. Mais um caso responde. Cinco ingressos, num servidor
em que os pedidos 1001 e 1002 já existem:

```
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=5' http://127.0.0.1:8000/book | grep msg
<p class="msg">Order 1003 reserved.</p>
```

Cinco é reservado e seis não, então o boxoffice traça a linha de cima entre 5 e 6, onde o R4 a
traça entre 6 e 7. É o defeito de fronteira clássico: a linha existe, e está deslocada em um. A
frase que o testador escreve agora é precisa o bastante para um desenvolvedor ir direto à
comparação que traça essa linha, sem ler uma palavra do programa:

| | |
|---|---|
| requisito | R4: de 1 a 6 ingressos por pedido |
| passos | como member@example.org, reservar Hamlet com quantidade 6 |
| esperado | o pedido é reservado |
| obtido | recusado: "You can book 1 to 6 tickets." |
| delimitado | 5 é reservado; 7 é recusado; o limite de cima é 5, não 6 |

Essa tabela é o resultado de um caso, ainda não um relato de defeito. A aula 15 transforma
resultados como esse em relatos que um estranho consegue reproduzir, e a correção do Rui chega na
versão 1.1, que a aula 9 confere.

O defeito também muda o plano da próxima aula. O R5 dá 15% de desconto a "um pedido de 5 ingressos
ou mais", e com seis recusado, cinco é a única quantidade dentro da faixa do R4 que alcança esse
desconto. A aula 5 usa cinco exatamente por isso, e quem não tivesse rodado o Q4 descobriria o
limite no meio da montagem de outra tabela.
