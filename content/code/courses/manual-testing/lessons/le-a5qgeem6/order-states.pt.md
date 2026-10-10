---
title: Testando os estados do pedido
version: 1
---

**Esta seção roda a tabela de estados do R6 no boxoffice**: os três caminhos que cobrem toda
transição válida, alguns dos dezesseis traços, e depois o traço que o dano pôs em primeiro lugar na
seção 04 desta aula. Ela acha o quarto defeito do curso, e acha numa célula da tabela por onde
nenhuma jornada comum de cliente passa.

## Movendo um pedido no navegador e no terminal

Todo pedido tem uma página própria, em `/order?id=` seguido do número, e a página que abre depois de
uma reserva é essa. Abaixo do preço ela mostra *State:* e o estado atual do pedido, e embaixo quatro
botões, Pay, Cancel, Use e Refund, os quatro sempre ali, seja qual for o estado. Apertar um deles é
o evento. A página que volta traz uma frase em cima dizendo o que aconteceu, e o estado abaixo do
preço.

No terminal, apertar um botão é uma requisição para `/order` com o número do pedido e a ação, e o
`grep msg` guarda a frase.

## As transições válidas

Reinicie o boxoffice, para que os pedidos recomecem em 1001. Depois, os três caminhos: o pedido 1001
é pago e usado, o 1002 é cancelado, o 1003 é pago e reembolsado. Cada caminho começa com uma reserva
de dois ingressos para Hamlet como o membro:

```
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=2' http://127.0.0.1:8000/book | grep msg
<p class="msg">Order 1001 reserved.</p>
ana@laptop:~/boxoffice$ curl -s -d 'id=1001&action=pay' http://127.0.0.1:8000/order | grep msg
<p class="msg">Order is now paid.</p>
ana@laptop:~/boxoffice$ curl -s -d 'id=1001&action=use' http://127.0.0.1:8000/order | grep msg
<p class="msg">Order is now used.</p>
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=2' http://127.0.0.1:8000/book | grep msg
<p class="msg">Order 1002 reserved.</p>
ana@laptop:~/boxoffice$ curl -s -d 'id=1002&action=cancel' http://127.0.0.1:8000/order | grep msg
<p class="msg">Order is now cancelled.</p>
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=2' http://127.0.0.1:8000/book | grep msg
<p class="msg">Order 1003 reserved.</p>
ana@laptop:~/boxoffice$ curl -s -d 'id=1003&action=pay' http://127.0.0.1:8000/order | grep msg
<p class="msg">Order is now paid.</p>
ana@laptop:~/boxoffice$ curl -s -d 'id=1003&action=refund' http://127.0.0.1:8000/order | grep msg
<p class="msg">Order is now refunded.</p>
```

As quatro transições se comportam, e todo estado depois de cada passo é o que a tabela prevê. São
três casos aprovados, e o resultado esperado de cada um estava escrito na tabela da seção 04 antes
de qualquer um rodar.

## Três traços

Com pedidos parados agora em três estados finais, os casos inválidos ficam baratos de alcançar.
Mais uma reserva dá um pedido reservado novo, o 1004; reembolsá-lo é o traço da linha reservado. O
pedido 1002 está cancelado e o 1003 reembolsado; cancelar qualquer um dos dois é um traço na linha de
um estado final:

```
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=2' http://127.0.0.1:8000/book | grep msg
<p class="msg">Order 1004 reserved.</p>
ana@laptop:~/boxoffice$ curl -s -d 'id=1004&action=refund' http://127.0.0.1:8000/order | grep msg
<p class="msg">An order that is reserved cannot be refunded.</p>
ana@laptop:~/boxoffice$ curl -s -d 'id=1002&action=cancel' http://127.0.0.1:8000/order | grep msg
<p class="msg">An order that is cancelled cannot be canceled.</p>
ana@laptop:~/boxoffice$ curl -s -d 'id=1003&action=cancel' http://127.0.0.1:8000/order | grep msg
<p class="msg">An order that is refunded cannot be canceled.</p>
```

Os três são recusados com uma frase e deixam o pedido onde estava, que é o que os traços dizem. **Três
de dezesseis é uma amostra, e uma amostra é uma escolha a registrar**: a lista de casos deve dizer
quais células rodaram.

## O traço que importa

A seção 04 pôs o reembolso de um pedido usado em primeiro lugar entre os traços, porque se ele
funcionasse faria dois danos de uma vez: dinheiro devolvido por um ingresso que alguém já usou, e os
lugares devolvidos. O caso precisa de um recomeço próprio, para a contagem de lugares ficar limpa:
reinicie o boxoffice, reserve dois ingressos, pague, use, e leia os lugares restantes de Hamlet na
página inicial antes e depois do reembolso. No navegador, a tabela Shows tem uma coluna para isso.
No terminal, o `grep -o` recorta a linha de Hamlet da tabela:

```
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=2' http://127.0.0.1:8000/book | grep msg
<p class="msg">Order 1001 reserved.</p>
ana@laptop:~/boxoffice$ curl -s -d 'id=1001&action=pay' http://127.0.0.1:8000/order | grep msg
<p class="msg">Order is now paid.</p>
ana@laptop:~/boxoffice$ curl -s -d 'id=1001&action=use' http://127.0.0.1:8000/order | grep msg
<p class="msg">Order is now used.</p>
ana@laptop:~/boxoffice$ curl -s http://127.0.0.1:8000/ | grep -o '<td>Hamlet</td><td>[^<]*</td><td>[^<]*</td><td>[0-9]*</td>'
<td>Hamlet</td><td>2026-10-17 20:00</td><td>R$ 80,00</td><td>78</td>
ana@laptop:~/boxoffice$ curl -s -d 'id=1001&action=refund' http://127.0.0.1:8000/order | grep msg
<p class="msg">Order is now refunded.</p>
ana@laptop:~/boxoffice$ curl -s http://127.0.0.1:8000/ | grep -o '<td>Hamlet</td><td>[^<]*</td><td>[^<]*</td><td>[0-9]*</td>'
<td>Hamlet</td><td>2026-10-17 20:00</td><td>R$ 80,00</td><td>80</td>
```

**O reembolso é aceito.** Um pedido usado vira reembolsado, com a mesma frase que um reembolso
válido recebe, e os lugares de Hamlet vão de 78 de volta a 80. O R6 só permite reembolso a partir de
pago, e a tabela de estados tem um traço na coluna reembolsar da linha usado. O boxoffice trata
usado como se fosse pago.

Lido como o teatro leria, as duas metades do dano são reais. O cliente que usou dois ingressos e
depois apertou Refund recebe o dinheiro de volta por um espetáculo em que entrou. E os dois lugares
em que ele sentou voltam à venda, então numa noite lotada a bilheteria pode vender os mesmos dois
lugares uma segunda vez para pessoas que vão encontrá-los ocupados.

| | |
|---|---|
| requisito | R6: um pedido pago pode ser usado, ou reembolsado antes de o espetáculo começar |
| passos | reservar 2 ingressos para Hamlet como o membro; pagar; usar; reembolsar |
| esperado | recusado com uma frase; o pedido continua usado; os lugares restantes ficam em 78 |
| obtido | "Order is now refunded."; os lugares restantes voltam a 80 |
| delimitado | reembolsar a partir de pago funciona como deve; reembolsar a partir de reservado é recusado |

## O que a tabela comprou

O caminho feliz, reservar, pagar, usar, passou. Os outros dois caminhos válidos também. Quem
parasse nas transições do diagrama teria relatado o R6 como funcionando, e o defeito seria achado
pelo primeiro cliente que reparasse que o botão Refund ainda funcionava em ingressos já usados na
porta. Ele foi achado aqui porque a tabela de estados transformou os movimentos proibidos numa
lista, e o dano de cada um pôs esta célula no topo.

Doze traços não rodaram nesta seção. A seção 06 desta aula pergunta sobre alguns, e o resto vale
rodar na sua própria máquina. Cada um é um botão e uma frase para ler, e um dos dezesseis já mostrou
que um traço é uma promessa que o boxoffice nem sempre cumpre.
