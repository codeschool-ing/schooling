---
title: Menor privilégio para um agente
version: 1
---

Um agente pode fazer o que as ferramentas dele podem fazer, e a escolha de ferramenta e de argumentos
de um modelo é a saída do laço da aula 1 seção 02: provável, não garantida. A aula 11 acrescenta um
caso pior, texto dentro de um resultado de ferramenta escrito para conduzir o modelo. **Então todo
limite é imposto abaixo do modelo, no host ou na ferramenta, onde as escolhas do modelo não
alcançam.**

## A ferramenta recusa o que não deve fazer

Um modelo que pede uma página do manual chamada `../../.env` está pedindo à ferramenta que leia um
arquivo fora do manual. A ferramenta não confia no argumento:

```
ana@dev:~/shop$ python lab/tools.py read_handbook shipping
is_error: False | # Shipping

Orders ship within two working days from the warehouse in Campinas. Delivery
i
ana@dev:~/shop$ python lab/tools.py read_handbook ../../.env
Tool 'read_handbook' failed: "Error executing tool read_handbook: '../../.env' is not a page of the handbook"
is_error: True | Error executing tool read_handbook: '../../.env' is not a page of the handbook
```

A primeira chamada lê a página. A segunda é recusada pela ferramenta, com uma mensagem com que o
modelo consegue agir, e o servidor a registra. **A checagem é sobre aonde o argumento leva**, não
sobre a cara dele: o `resolve()` transforma `../../.env` num caminho real, e o caminho é comparado
com a pasta do manual.

## Uma pessoa aprova o que muda as coisas

O `issue_refund` é a única ferramenta que não é só leitura, então o host pergunta antes de chamá-la.
Aqui a operadora diz não:

```
ana@dev:~/shop$ echo n | python agent.py "Refund order 1042, the customer changed their mind."
[1] call:   issue_refund({"order_id": "1042", "cents": 7980})
allow issue_refund({"order_id": "1042", "cents": 7980})? [y/N] n
[1] result: refused by the operator
[2] model:  The refund was not issued: the operator declined it.
ana@dev:~/shop$ cat data/refunds.log 2>&1
cat: data/refunds.log: No such file or directory
```

O host devolveu *refused by the operator* ao modelo como resultado de erro, o modelo informou que o
reembolso não foi feito, e o registro de reembolsos não existe: **nada foi pago.** O mesmo pedido com
um sim:

```
ana@dev:~/shop$ echo y | python agent.py "Refund order 1042, the customer changed their mind."
[1] call:   issue_refund({"order_id": "1042", "cents": 7980})
allow issue_refund({"order_id": "1042", "cents": 7980})? [y/N] y
[1] result: refunded 7980 cents on order 1042
[2] model:  Refunded 79.80 on order 1042, the two mugs. Shipping was not refunded, since the handbook refunds it only when the whole order is returned.
ana@dev:~/shop$ cat data/refunds.log
1042 7980
```

Um reembolso, registrado, dos 79,80 que o modelo pediu. A aprovação mostrou os argumentos exatos antes
de qualquer coisa acontecer, e é esse o ponto: uma pessoa aprovando "um reembolso" não está aprovando
"um reembolso de 7980 centavos no pedido 1042".

## As regras

- **Só leitura por padrão.** Dê a um agente ferramentas que só leem até ele ter motivo para mudar
  algo, e então uma ferramenta estreita para essa mudança.
- **Confira os argumentos na ferramenta.** Caminhos, valores, ids que precisam ser do cliente atual. O
  esquema confere tipos; a ferramenta confere sentido.
- **Pergunte a uma pessoa antes de tudo o que custa dinheiro, manda uma mensagem, apaga ou publica**,
  e mostre os argumentos, não um resumo.
- **Rode o agente com o menor acesso que funciona**: credenciais próprias, restritas ao que as
  ferramentas dele precisam, nunca as do próprio dev.
- **Registre toda chamada e todo resultado**, com quem aprovou o quê. Quando um agente faz algo
  surpreendente, o registro é o único relato do porquê.
