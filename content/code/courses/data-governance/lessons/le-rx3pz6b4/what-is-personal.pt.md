---
title: O que faz um dado ser pessoal
version: 1
---

A definição da LGPD tem uma linha, e a maior parte da lei pende dela. **Artigo 5º, I**: dado pessoal
é *informação relacionada a pessoa natural identificada ou identificável*.

Duas palavras dela carregam o peso.

**"Relacionada a"** é largo. Não é só dado *sobre* alguém, como um nome ou uma data de nascimento,
mas qualquer coisa que diga algo sobre a pessoa: um pedido feito, um chamado escrito, a hora em que
uma entrega chegou, o fato de ela ter aceitado marketing. Uma tabela de pedidos sem nome nenhum é
uma tabela de coisas que pessoas fizeram.

**"Identificável"** é mais largo ainda. Uma pessoa não precisa estar nomeada no dado; basta que
*possa* ser identificada, pelo controlador ou por outra pessoa, com o dado e outras informações. O
`customer_id` 2 da Ipê não nomeia ninguém — e faz join com uma linha com nome, e-mail e CPF. Uma
linha de pedido com `customer_id = 2` é, portanto, dado pessoal, e tudo o que se liga a ela também.

A aula 5 mediu até onde isso chega: sem identificador nenhum, data de nascimento, sexo e CEP
destacam 5.988 de 6.012 clientes. **A maior parte do dado no banco operacional de uma empresa é dado
pessoal**, e a pergunta útil raramente é "isto é pessoal?", e sim "quão diretamente isto identifica,
e o que revela?"

## O que não é dado pessoal

- **Dado sobre uma empresa**, não uma pessoa: o CNPJ de um fornecedor, o endereço de uma loja. (O de
  um empresário individual é sobre uma pessoa.)
- **O catálogo**: os produtos da Ipê e seus preços não dizem nada de ninguém até alguém comprar um.
- **Dado anonimizado** no sentido da aula 5 — medido, e enquanto a medição se sustentar.
- **Dado sobre pessoas falecidas** costuma ser lido como fora da definição da LGPD, que fala dos
  direitos de uma pessoa natural viva; outras regras — o sigilo médico entre elas — continuam valendo
  para ele.

## Quem é quem

A lei nomeia papéis que o resto do curso usa:

| papel | na LGPD | na Ipê |
|---|---|---|
| **titular** | a pessoa a quem o dado se refere | cada cliente |
| **controlador** | quem decide por que e como o dado é tratado | a Farmácia Ipê |
| **operador** | quem trata o dado em nome do controlador | o provedor de pagamento, um provedor de nuvem |
| **encarregado** | o canal entre controlador, titulares e a autoridade | o Davi |

O controlador responde pelo que o operador faz com o dado que recebeu. A aula 7 põe deveres em cada
um.
