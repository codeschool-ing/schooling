---
title: Quatro pedidos, e como respondê-los
version: 1
---

A conta desta aula leva uma tarde. Defendê-la leva mais, porque todo mundo que já ouviu falar de um
modelo tem opinião sobre onde a linha deve ficar. Quatro pedidos chegam à Ana na semana em que o modelo
entra no ar. Cada um tem uma resposta que soa prestativa e está errada, e uma que se sustenta.

**1. "Use 0,5. É o padrão."** A líder de marketing leu isso num tutorial.

0,5 é o padrão de uma função, escolhido por ninguém para este negócio. Quer dizer "mais provável sair
que ficar", e o crédito da Feira em Casa se paga com 0,278, pouco mais da metade disso. A resposta é a curva de
valor: em 0,5 o modelo faz R$ 9.088 nos meses de teste, e no corte calculado dos custos faz
R$ 21.672. **Um padrão não precisa de defesa até alguém mostrar quanto ele custa.**

**2. "Mande para todo mundo acima de 0,1, por segurança."** O atendimento prefere desperdiçar crédito a
perder gente.

Soa cauteloso, e nestes dados é a escolha imprudente. Em 0,1 o programa faz R$ 1.848, e um pouco abaixo
perde dezenas de milhares, porque quem fica supera quem sai em quinze para um. "Seguro" aqui tem de
querer dizer seguro para o dinheiro também, não só para o assinante. Se o atendimento acredita que
perder um assinante custa mais que R$ 480, **isso é uma mudança num número do enquadramento**, e o
corte segue dela: discuta o número, e o corte se move sozinho.

**3. "Use o que deu mais dinheiro no semestre passado."** O diretor quer a evidência.

O melhor corte nos meses de teste foi 0,23 e fez R$ 23.832, e foi escolhido olhando as respostas. Ele
venceu por causa de um aumento de preço que ninguém poderia prever em junho, e a surpresa do próximo
semestre vai ser outra. A resposta são as três linhas do `choose_cut.py`: o corte escolhido antes, o
escolhido num período de validação e o escolhido a posteriori, **com o último marcado como teto e não
como resultado**.

**4. "Só conseguimos fazer 150 ligações por mês."** Operações, e este não é uma opinião.

É uma restrição, e ela muda a política em vez do corte: ordene cada mês e ligue para os 150 de cima.
Isso fez R$ 23.616, em parte porque uma lista não sofre com chances que saem baixas. A resposta é
concordar, e levar a tabela do `capacity.py` para a próxima reunião sobre quantas pessoas contratar.

## O que os quatro têm em comum

Cada pedido é sobre as mesmas três coisas: **os custos, a restrição e a evidência.** Um corte defendido
com "o modelo diz" perde todas essas conversas, porque o modelo nunca disse nada sobre onde a linha
fica. Um corte defendido com os números do próprio negócio, escritos no enquadramento e combinados
antes, ganha a maioria delas, e as que ele perde mudam um número em vez do método.
