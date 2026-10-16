---
title: O risco escolhe a volta
version: 1
---

**A pergunta central da espiral é fácil de enunciar e difícil de responder: de tudo o que pode dar errado, o
que tem mais chance de nos afundar, e qual o jeito mais barato de descobrir?** Vale ver como isso fica numa
decisão real.

## As primeiras voltas do Cine Aurora

Suponha que o Cine Aurora tivesse construído a loja online como uma espiral. Antes de qualquer código, a
Joana, o Rafael, o Tomás e a Lia listaram o que poderia fazer o projeto fracassar, com um julgamento grosso
de quão provável e quão grave era cada coisa:

| risco | quão provável | quão grave | o jeito mais barato de descobrir |
|---|---|---|---|
| os clientes não entendem o mapa de assentos | médio | alto: nenhuma venda | protótipo de papel, cinco clientes fiéis, uma tarde |
| dois compradores levam o mesmo assento no mesmo instante | médio | alto: clientes bravos, reembolsos | um programa pequeno que tenta isso mil vezes |
| a regra de preço está errada | baixo | médio: reembolsos | revisá-la com a Célia |
| o provedor de pagamento fica lento em noites de estreia | baixo | alto | pedir os números ao provedor |

A primeira volta pega o topo da lista: um protótipo de papel do mapa de assentos, mostrado a cinco clientes
fiéis. Dois deles não conseguiam distinguir um assento ocupado de um livre. Isso custou uma tarde e um novo
desenho. Achado depois de a loja estar pronta, significaria reprojetar a tela da qual todas as outras partes
dependem.

A segunda volta pega o risco seguinte: assentos vendidos duas vezes. O Rafael escreve o menor programa de
reserva que consegue e a Lia escreve outro que tenta pegar o mesmo assento de dois lugares ao mesmo tempo,
mil vezes. É um experimento, e o resultado decide como a reserva de verdade vai ser construída.

A regra de preço, a que este curso dedicou oito aulas, fica em terceiro. **Não porque não importa, mas porque
é a mais barata de corrigir tarde**: uma função, nada construído em cima, como mostraram os quatro custos da
aula 3. Uma espiral ainda a teria revisado com a Célia, barato, cedo, e *maiores de 60* bem poderia ter
aparecido nessa revisão.

## Probabilidade e impacto

A tabela julgou cada risco por duas coisas: **quão provável** ele é e **quão grave** seria. Esse par é a base
de quase todo jeito de priorizar testes, e a aula 20 o transforma num método com números. O que importa aqui
é o hábito que a espiral cria: antes de decidir o que fazer, liste o que pode dar errado, julgue cada item
nos dois eixos, e comece pelos que são ao mesmo tempo prováveis e graves.

## O que quem testa traz para a lista

Quem testa é bom nessa lista, pelo mesmo motivo por que é bom em achar defeitos: passa os dias pensando em
como as coisas falham. Numa conversa sobre riscos, as contribuições de quem testa costumam ser:

- **riscos que ninguém listou**, porque vêm de olhar como pessoas reais usam as coisas: a bilheteria e o site
  vendendo o mesmo assento, uma sessão digitada com a hora de um dígito só;
- **experimentos mais baratos** para um risco já listado, porque desenhar um teste capaz de refutar uma
  crença é o trabalho;
- **honestidade sobre o que um experimento não mostrou**: as mil tentativas que nunca venderam um assento
  duas vezes não provam nada sobre dez mil.

Poucos times usam a espiral com esse nome hoje. O hábito de escolher o próximo trabalho pelo risco, e de
tratar a suposição mais arriscada como uma hipótese a testar primeiro, está em toda parte, e você vai vê-lo de
novo nas aulas 11 e 20.
