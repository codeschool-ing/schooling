---
title: Os dados e o estado, por escrito
version: 1
---

Um caso tem duas entradas além dos passos, e são as que os autores esquecem, porque nenhuma delas
aparece na tela enquanto os passos são seguidos. **Os dados** são todos os valores que os passos
digitam ou escolhem. **O estado** é tudo o que a aplicação já guarda quando o passo 1 começa: as
contas, os pedidos, os lugares livres, até a hora. Um estranho que usa outros dados, ou parte de
outro estado, executa outro teste, e o caso não lhe dá como saber.

Quatro execuções no boxoffice mostram o que um estado não escrito faz com um veredito. Cada uma
segue passos perfeitamente claros.

## Os mesmos passos, duas vezes

O TC-BOOK-01 da aula 2 reserva dois ingressos para Hamlet como o membro. Execute-o duas vezes sem
reiniciar o boxoffice no meio, e olhe a mensagem de cada vez e a página Shows no fim:

```
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=2' http://127.0.0.1:8000/book | grep msg
<p class="msg">Order 1001 reserved.</p>
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=2' http://127.0.0.1:8000/book | grep msg
<p class="msg">Order 1002 reserved.</p>
ana@laptop:~/boxoffice$ curl -s http://127.0.0.1:8000/ | grep -o '<tr><td>[^<]*</td><td>[^<]*</td><td>[^<]*</td><td>[0-9]*</td>'
<tr><td>The Seagull</td><td>2026-10-10 20:00</td><td>R$ 60,00</td><td>120</td>
<tr><td>Hamlet</td><td>2026-10-17 20:00</td><td>R$ 80,00</td><td>76</td>
<tr><td>The Little Prince</td><td>2026-10-18 16:00</td><td>R$ 30,00</td><td>200</td>
```

A segunda execução é o pedido 1002, e Hamlet está em 76 em vez de 78. Um caso que esperasse *Order
1001* ou *78 lugares livres* passa na primeira vez e falha em todas as seguintes, enquanto o
boxoffice se comporta exatamente como o R4 manda. Por isso a aula 2 deixou o número do pedido fora
do TC-BOOK-01 e pôs *Hamlet tem 80 lugares livres* na pré-condição.

Há dois jeitos de fazer um resultado assim se sustentar. **Declarar o ponto de partida**, como faz
o TC-BOOK-01, para o estranho saber que deve reiniciar o boxoffice se ele não valer. Ou **escrever
o resultado em relação ao início**: *os lugares livres de Hamlet caem 2*. O segundo sobrevive a
qualquer estado, e pede ao estranho que leia o número antes do passo 1 além de depois, o que os
passos então precisam dizer.

## Dados que se gastam

Alguns dados só podem ser usados uma vez. O TC-SIGNUP-01 da aula 2 cria uma conta para
`ana@example.org`. Execute-o uma segunda vez no mesmo servidor:

```
ana@laptop:~/boxoffice$ curl -s -d 'name=Ana+Lima&email=ana@example.org&password=boxoffice-2026' http://127.0.0.1:8000/signup | grep msg
<p class="msg">Account created. We sent a link to ana@example.org.</p>
ana@laptop:~/boxoffice$ curl -s -d 'name=Ana+Lima&email=ana@example.org&password=boxoffice-2026' http://127.0.0.1:8000/signup | grep msg
<p class="msg">There is already an account with that e-mail.</p><form method="post" action="/signup">
```

A segunda execução já não é o TC-SIGNUP-01. É o TC-SIGNUP-02, a recusa de um endereço já usado, com
o endereço da Ana no lugar do do membro. **O caso gastou os próprios dados**, e por isso a
pré-condição dele diz que nenhuma conta usa `ana@example.org`, e diz como tornar isso verdade: uma
inicialização limpa tem só o membro.

## Uma conta em outro estado

O rascunho da seção 02 dizia *um membro*. Eis a mesma reserva feita pela conta nova da Ana, criada
um instante antes e nunca confirmada:

```
ana@laptop:~/boxoffice$ curl -s -d 'name=Ana+Lima&email=ana@example.org&password=boxoffice-2026' http://127.0.0.1:8000/signup | grep msg
<p class="msg">Account created. We sent a link to ana@example.org.</p>
ana@laptop:~/boxoffice$ curl -s -d 'email=ana@example.org&show=S2&quantity=2' http://127.0.0.1:8000/book | grep -A3 'class="msg"'
<p class="msg">Order 1001 reserved.</p>
<p>Hamlet, 2 ticket(s), 0% off:
<strong>R$ 160,00</strong></p>
<p>State: <strong>reserved</strong></p>
```

0% de desconto e R$ 160,00, contra os 10% de desconto e R$ 144,00 do membro na aula 2. Os dois
estão certos: o R5 dá o desconto a uma conta confirmada, e esta não está. **Uma conta só vira dado
quando o estado dela está escrito ao lado**: que endereço, e se está confirmada.

## A hora também é estado

O R4 fecha as reservas uma hora antes do espetáculo, então se uma reserva para o espetáculo de hoje
é aceita depende de quando o caso roda. A mesma requisição para The Seagull, feita com o relógio da
aplicação às sete e meia da noite:

```
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S1&quantity=2' http://127.0.0.1:8000/book | grep msg
<p class="msg">Booking for this show has closed.</p><form method="post" action="/book">
```

Às duas da tarde a mesma requisição reserva um pedido. As duas respostas estão certas, e um caso que
reserva The Seagull sem dizer quando roda vai passar para quem o executar de manhã e falhar para quem
o executar depois do expediente. **Quando a hora não é o que o caso confere, ele escolhe dados
longe da borda**: Hamlet, daqui a uma semana, responde igual a qualquer hora de hoje. Quando a hora
é o que o caso confere, a pré-condição dá a hora.

## De onde vem o estado

Uma pré-condição diz o que precisa ser verdade. O estranho também precisa saber como tornar aquilo
verdade, e há três jeitos:

- **uma reinicialização**: parar o boxoffice e iniciá-lo de novo, o que dá o estado que a aula 1
  descreve, três espetáculos, lugares cheios, um membro confirmado e nenhum pedido;
- **passos de preparação** dentro da pré-condição: *cadastre `ana@example.org` e não confirme*;
- **outro caso**, citado pelo id: *o TC-CONFIRM-01 passou*.

O terceiro é o mais barato de escrever e o mais frágil de executar, porque quando o caso anterior
falha, este fica bloqueado, como mostrou a seção 05 da aula 2. Um caso que precisa rodar sozinho,
num dia em que nada mais rodou, usa os dois primeiros. De onde vêm os dados de teste num sistema
maior, e como se reinicia uma suíte inteira, é a aula 20.
