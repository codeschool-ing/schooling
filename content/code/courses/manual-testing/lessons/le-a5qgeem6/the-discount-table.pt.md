---
title: Rodando a tabela de descontos
version: 1
---

**Uma tabela de decisão vira casos de teste uma coluna de cada vez.** Cada regra da seção 02 desta
aula é um caso: preparar as três condições que a coluna pede, fazer um pedido e comparar o desconto
e o total com o que a coluna diz. Esta seção roda as oito no boxoffice e acha o terceiro defeito do
curso na coluna que a frase mais difícil do requisito governa.

## Tornando cada condição verdadeira ou falsa

Cada condição precisa de um jeito de ser definida, e vale decidir isso antes do primeiro pedido,
porque um caso só é tão bom quanto a preparação dele:

- **estudante**: o formulário de reserva tem uma caixa de marcar, *Student (half price)*. Marcada é
  S. No terminal, é o campo `student=on` na requisição; deixar o campo de fora é N;
- **membro**: o R5 chama uma conta confirmada de membro. A conta semeada, `member@example.org`, é
  confirmada, então é S. Para N você precisa de uma conta que exista, já que o R4 não deixa mais
  ninguém reservar, e que não tenha sido confirmada: cadastre uma nova e ignore o e-mail que ela
  manda;
- **5 ingressos ou mais**: 5 para S e 2 para N, como a seção 02 escolheu.

Todo pedido é para Hamlet, a R$ 80,00 o ingresso, então os totais esperados saem fácil à mão: o
número de ingressos, vezes 80, menos o desconto. Cinco ingressos a preço cheio são R$ 400,00, dois
são R$ 160,00.

| regra | estudante | membro | 5+ | desconto esperado | total esperado |
|---|---|---|---|---|---|
| 1 | S | S | S | 50% | R$ 200,00 |
| 2 | S | S | N | 50% | R$ 80,00 |
| 3 | S | N | S | 50% | R$ 200,00 |
| 4 | S | N | N | 50% | R$ 80,00 |
| 5 | N | S | S | 15% | R$ 340,00 |
| 6 | N | S | N | 10% | R$ 144,00 |
| 7 | N | N | S | 15% | R$ 340,00 |
| 8 | N | N | N | 0% | R$ 160,00 |

Os totais esperados são escritos antes de qualquer coisa rodar. Quem os calcula depois, olhando o
que o boxoffice cobrou, está conferindo se um número parece plausível, e um desconto errado numa
conta sempre parece plausível.

## Rodando

Reinicie o boxoffice e crie a conta que não é de membro. No navegador, abra **Sign up** e crie uma
conta para `caio@example.org` com qualquer nome e uma senha de oito caracteres ou mais. No terminal:

```
ana@laptop:~/boxoffice$ curl -s -d 'name=Caio Lima&email=caio@example.org&password=12345678' http://127.0.0.1:8000/signup | grep msg
<p class="msg">Account created. We sent a link to caio@example.org.</p>
```

Agora os oito pedidos. No navegador, cada um é uma reserva na página **Book** com o e-mail, o
espetáculo, a quantidade e a caixa de marcar como a coluna diz; a página do pedido então mostra
uma linha como *Hamlet, 5 ticket(s), 50% off:* com o total embaixo. No terminal, o
`grep -A1 'off:'` imprime essa linha e a seguinte, que tem o total. Os pedidos seguem a ordem da
tabela, a regra 1 primeiro:

```
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=5&student=on' http://127.0.0.1:8000/book | grep -A1 'off:'
<p>Hamlet, 5 ticket(s), 50% off:
<strong>R$ 200,00</strong></p>
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=2&student=on' http://127.0.0.1:8000/book | grep -A1 'off:'
<p>Hamlet, 2 ticket(s), 50% off:
<strong>R$ 80,00</strong></p>
ana@laptop:~/boxoffice$ curl -s -d 'email=caio@example.org&show=S2&quantity=5&student=on' http://127.0.0.1:8000/book | grep -A1 'off:'
<p>Hamlet, 5 ticket(s), 50% off:
<strong>R$ 200,00</strong></p>
ana@laptop:~/boxoffice$ curl -s -d 'email=caio@example.org&show=S2&quantity=2&student=on' http://127.0.0.1:8000/book | grep -A1 'off:'
<p>Hamlet, 2 ticket(s), 50% off:
<strong>R$ 80,00</strong></p>
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=5' http://127.0.0.1:8000/book | grep -A1 'off:'
<p>Hamlet, 5 ticket(s), 25% off:
<strong>R$ 300,00</strong></p>
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=2' http://127.0.0.1:8000/book | grep -A1 'off:'
<p>Hamlet, 2 ticket(s), 10% off:
<strong>R$ 144,00</strong></p>
ana@laptop:~/boxoffice$ curl -s -d 'email=caio@example.org&show=S2&quantity=5' http://127.0.0.1:8000/book | grep -A1 'off:'
<p>Hamlet, 5 ticket(s), 15% off:
<strong>R$ 340,00</strong></p>
ana@laptop:~/boxoffice$ curl -s -d 'email=caio@example.org&show=S2&quantity=2' http://127.0.0.1:8000/book | grep -A1 'off:'
<p>Hamlet, 2 ticket(s), 0% off:
<strong>R$ 160,00</strong></p>
```

Sete dos oito batem com a tabela. **A regra 5 não**: um membro comprando cinco ingressos levou 25%
de desconto e pagou R$ 300,00, onde o R5 pede 15% e R$ 340,00. Os 25 são 10 e 15 somados,
exatamente o que "descontos não se somam" proíbe. Cada pedido assim custa ao teatro R$ 40,00 num
espetáculo de R$ 80,00, e acontece com os clientes que o teatro mais quer: membros que trazem um
grupo.

## Por que a tabela achou

Veja o que o plano de três casos da seção 02 teria rodado. Um estudante sozinho é a regra 4, e ela
passou. Um membro comprando dois ingressos é a regra 6, e ela passou. Cinco ingressos para quem não
é membro é a regra 7, e ela passou. Cada desconto funciona sozinho. **O defeito só existe onde dois
deles se encontram**, e um plano que testa cada condição separada nunca os junta. A tabela não
precisou que ninguém adivinhasse que a regra 5 era a perigosa; ela listou as oito, e a regra 5
estava entre elas.

As regras 1 e 3 também são combinações, um estudante que é também membro ou que compra cinco, e
passaram: a meia-entrada venceu, como o R5 manda. Esse resultado vale a pena. Ele diz que o
problema não é "os descontos se combinam errado" em geral, e sim especificamente os descontos de
membro e de quantidade, o que delimita o defeito do jeito que a aula 4, seção 04, delimitou o
limite de quantidade:

| | |
|---|---|
| requisito | R5: descontos não se somam; vale o maior |
| passos | como member@example.org, reservar 5 ingressos para Hamlet, Student desmarcado |
| esperado | 15% de desconto, R$ 340,00 |
| obtido | 25% de desconto, R$ 300,00 |
| delimitado | as regras 1, 3, 6 e 7 passam: os 50% do estudante vencem os dois, e 10% e 15% estão certos sozinhos |

A correção do Rui para o desconto está na versão 1.1, que a aula 9 confere, e a aula 10 roda esta
mesma tabela de novo na 1.1 para ver se a correção deixou todo o resto no lugar. Uma tabela
guardada, com a coluna do esperado, é uma suíte de regressão esperando para rodar, e esse é mais um
argumento para escrevê-la em vez de guardá-la na cabeça.
