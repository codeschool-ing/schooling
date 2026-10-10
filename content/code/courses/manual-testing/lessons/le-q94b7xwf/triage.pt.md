---
title: Triagem
version: 1
---

A palavra vem dos hospitais de campanha, onde queria dizer separar os feridos por quem precisava de
ajuda primeiro, e o empréstimo é exato. **A triagem decide o que acontece com cada relato novo e em
que ordem os abertos são corrigidos.** Ela não corrige nada, e uma reunião de triagem que vira
sessão de depuração acaba sem tempo e com metade da lista sem decisão, que é o único resultado pior
que uma decisão rápida e errada.

## Quem está lá, e o que cada um traz

Três papéis, seja qual for o nome que o time dá a eles:

- **o dono do produto**, no boxoffice o gerente do teatro, que sabe quanto cada defeito custa ao
  negócio e por isso é dono da prioridade;
- **um desenvolvedor**, o Rui, que sabe mais ou menos quanto custa cada correção e quais delas
  mexem no mesmo código;
- **quem testa**, a Ana, que conhece os relatos, consegue reproduzir qualquer um ali mesmo e é dona
  da severidade.

Times pequenos fazem triagem em quinze minutos duas vezes por semana; os grandes têm rodízio e fila.
O tamanho não muda nada nas perguntas.

## As perguntas, em ordem

Para cada relato **novo** a reunião pergunta quatro coisas, e para na primeira que o encerra:

1. **É um defeito?** O programa contradiz um requisito, ou algo que o produto claramente deveria
   fazer? Se não, é rejeitado, com o motivo escrito nele.
2. **Já foi relatado?** Se sim, é duplicado, ligado ao original.
3. **Conseguimos ver?** Se a reprodução funciona, sim. Se ninguém consegue, o relato volta para quem
   o escreveu pedindo mais, e ainda não é rejeitado.
4. **Quão grave, e quando?** A severidade é confirmada ou corrigida; a prioridade é definida; o nome
   de alguém vai nele.

Para os relatos **abertos** a reunião pergunta só se algo mudou: um prazo, a reclamação de um
cliente, uma correção que se mostrou mais difícil do que parecia. A prioridade se move; a severidade
fica, a não ser que os fatos sobre o estrago se movam.

## Uma triagem no boxoffice 1.1

A versão 1.1 é a atual. Há sete defeitos abertos, das aulas que os encontraram, e três relatos
chegaram nesta semana. Esta é a lista da reunião ao terminar:

| relato | de onde | severidade | decisão |
|---|---|---|---|
| estudantes não pagam metade | aula 10 | crítica | P1, Rui, próximo build |
| um pedido usado pode ser reembolsado, e os lugares voltam | aula 5 | crítica | P1, Rui, próximo build |
| um reembolso é aceito depois que o espetáculo começou | aula 11 | maior | P1, Rui, próximo build |
| a tabela de espetáculos tem 760 pixels de largura no celular | aula 7 | menor | P1: a campanha da temporada começa semana que vem |
| uma quantidade que não é número inteiro responde 500 com traceback | aula 15 | maior | P2, nesta versão |
| o campo de ingressos tem placeholder e nenhum rótulo | aula 14 | maior | P2, nesta versão |
| "cannot be payed", "cannot be useed" | aula 11 | trivial | adiado para a próxima versão |
| NOVO: pagar um pedido pago diz "cannot be payed" | esta semana | | duplicado da linha acima |
| NOVO: um membro que reserva cinco leva 15%, não 25% | esta semana | | rejeitado: o R5 diz que vale o maior desconto |
| NOVO: a caixa de saída mostra o e-mail de todos os clientes | esta semana | | rejeitado: a caixa de saída só existe no build de teste |

Três decisões dela merecem leitura atenta, porque cada uma é um argumento que alguém podia ter
perdido.

**O reembolso depois do início do espetáculo é maior e mesmo assim P1.** É outra regra, diferente
do reembolso de pedido usado (o R6 diz *antes de o espetáculo começar*), e o gerente o pôs ao lado
do vizinho porque o Rui vai estar nas mesmas poucas linhas de código para os dois. A prioridade
pode seguir o custo da correção além do custo do defeito, e essa é a contribuição do desenvolvedor
para a reunião.

**O traceback ficou em P2**, e a Ana defendeu P1: o ponto da aula 14 de que uma página de erro que
mostra código entrega informação a um estranho. O gerente pesou isso contra três defeitos que tiram
dinheiro de clientes e manteve a ordem, com uma nota no relato de que ele sai na 1.2 aconteça o que
acontecer com o resto. O argumento da Ana está registrado, que era o que ela precisava: se a decisão
se mostrar errada, o relato mostra que o risco foi levantado, e por quem.

**As mensagens com erro de grafia foram adiadas, não fechadas.** São reais, são triviais, e a única
linha que as corrige está no código que o Rui vai mexer por causa dos reembolsos, então podem acabar
corrigidas por acaso. Adiar as mantém na lista até alguém conferir.

## O que a reunião registra

Cada decisão vai para o próprio relato, não para a ata da reunião: o novo estado, a prioridade, o
nome e uma linha de motivo para tudo o que foi rejeitado, adiado ou discutido. Quem ler o relato
daqui a seis meses não estava na sala, e é o mesmo leitor para quem a aula 15 escreveu o relato.
