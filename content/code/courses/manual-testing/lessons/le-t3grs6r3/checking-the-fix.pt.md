---
title: Conferindo a correção
version: 1
---

A versão está no disco. A verificação de sanidade da 1.1 tem seis comandos, e os dois primeiros não
têm nada a ver com nenhuma das correções: **antes de conferir uma mudança, garanta que está olhando
para a versão que a contém**. Uma verificação de sanidade rodada na versão antiga falha por um
motivo que nada tem a ver com a correção, e uma rodada sobre um arquivo salvo pela metade pode
passar por um motivo do mesmo tipo.

## Que versão é esta?

Suba a aplicação de novo no terminal dela:

```
ana@laptop:~/boxoffice$ python3 boxoffice.py
boxoffice 1.1 on http://127.0.0.1:8000  (Ctrl-C stops it)
```

E, no segundo terminal, a primeira linha da lista de fumaça da aula 8:

```
ana@laptop:~/boxoffice$ curl http://127.0.0.1:8000/health
ok boxoffice 1.1
```

Os dois dizem 1.1, então a edição 1 entrou e o servidor que responde é o que você acabou de subir.
No navegador, o mesmo fato está no rodapé de toda página, `boxoffice 1.1`. Rode agora também o
resto da lista de fumaça da aula 8; leva poucos minutos, e a sanidade só começa quando ela passa. Se
a versão ainda disser 1.0, o arquivo não foi salvo ou uma cópia antiga do servidor continua rodando,
e o `Address already in use` da aula 1 seção 05 é o sinal comum da segunda hipótese.

## A primeira correção: seis ingressos

O relatório de defeito da aula 4 é o roteiro. Os passos dele, na página Book: e-mail
`member@example.org`, espetáculo Hamlet, 6 no campo Tickets, apertar Book. Na 1.0 a página respondia
*You can book 1 to 6 tickets*. Agora:

```
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=6' http://127.0.0.1:8000/book | grep msg
<p class="msg">Order 1001 reserved.</p>
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=7' http://127.0.0.1:8000/book | grep msg
<p class="msg">You can book 1 to 6 tickets.</p><form method="post" action="/book">
```

A primeira requisição é o reteste, e passa: seis ingressos geram o pedido 1001. A segunda é o
vizinho do outro lado do limite, e também passa, porque o R4 diz no máximo seis e sete continua
recusado com a mesma frase. No navegador, a primeira abre a página do pedido 1001 e a segunda fica
na página Book com a mensagem acima do formulário.

## A segunda correção: um sócio que reserva cinco

O relatório da aula 5: o sócio reserva cinco ingressos para Hamlet e ganha 25% de desconto, quando o
R5 diz que vale o maior desconto isolado, que é 15%. Cinco ingressos a R$ 80,00 são R$ 400,00, e
15% a menos dá R$ 340,00. O comando guarda a linha com o desconto e a linha seguinte, que traz o
total:

```
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=5' http://127.0.0.1:8000/book | grep -A1 'off:'
<p>Hamlet, 5 ticket(s), 15% off:
<strong>R$ 340,00</strong></p>
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=4' http://127.0.0.1:8000/book | grep -A1 'off:'
<p>Hamlet, 4 ticket(s), 10% off:
<strong>R$ 288,00</strong></p>
```

O reteste passa: 15% e R$ 340,00, os dois valores esperados. O vizinho é o sócio que reserva quatro,
em que só o desconto de sócio vale: 10% a menos sobre R$ 320,00 deixa R$ 288,00, e foi isso que
voltou. No navegador, cada requisição abre uma página de pedido com a mesma linha, o desconto e
depois o total em negrito.

## O resultado

| verificação | esperado | 1.1 | veredito |
|---|---|---|---|
| versão | 1.1 | `ok boxoffice 1.1` | passou |
| sócio, Hamlet, 6 ingressos | um pedido | pedido 1001 reservado | passou |
| sócio, Hamlet, 7 ingressos | recusado, R4 | *You can book 1 to 6 tickets.* | passou |
| sócio, Hamlet, 5 ingressos | 15%, R$ 340,00 | 15%, R$ 340,00 | passou |
| sócio, Hamlet, 4 ingressos | 10%, R$ 288,00 | 10%, R$ 288,00 | passou |

**A sanidade passou, e os dois defeitos podem ser marcados como verificados.** A aula 16 dá nome a
esse passo na vida de um defeito; o que importa aqui é que a Ana anota o número da versão ao lado do
resultado, *verificado na 1.1*, porque uma correção é um fato sobre uma versão, e a próxima pode
perdê-la.

Se algum dos retestes tivesse falhado, a versão voltaria agora para o Rui, com a requisição que
falhou e o que ela respondeu, e ninguém gastaria a tarde numa rodada de regressão de uma versão que
seria substituída. É todo o motivo de a sanidade rodar primeiro.

O que esses seis comandos não dizem é nada sobre o resto do boxoffice. A edição 2 reescreveu a
função que decide todo preço que o teatro cobra, e a verificação de sanidade olhou duas das
respostas dela: um sócio que reserva cinco, um sócio que reserva quatro. Toda outra combinação de
descontos passa pelas mesmas três linhas novas e ninguém a experimentou na 1.1. **Essa é a próxima
pergunta, e ela tem nome próprio**: a aula 10 a faz com uma rodada de regressão nesta mesma versão.
Deixe o `boxoffice-1.0.py` onde está, porque essa rodada precisa dele.
