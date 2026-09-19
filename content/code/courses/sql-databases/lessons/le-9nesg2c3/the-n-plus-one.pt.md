---
title: N+1, o erro que parece código comum
version: 1
---

Aqui está uma página que lista cinquenta clientes com seus pedidos, escrita do jeito que todo
tutorial escreve:

```
customers = Customer.order('id').limit(50)
for customer in customers:
    for order in customer.orders:
        print(customer.name, order.total)
```

Quatro linhas, e nada nelas parece um problema de banco. A primeira linha roda uma consulta.
`customer.orders` na terceira linha roda uma consulta **por cliente**, porque os pedidos não foram
carregados junto com os clientes — o ORM os busca na primeira vez em que são pedidos, que é dentro
do laço. Cinquenta clientes, cinquenta consultas, mais a que buscou os clientes: **N+1**.

A seção anterior capturou isso do lado do servidor:

```
shop=# SELECT calls, left(query, 60) AS query FROM pg_stat_statements WHERE query LIKE 'SELECT id,%' ORDER BY calls DESC;
 calls |                            query                             
-------+--------------------------------------------------------------
    50 | SELECT id, placed_at, total FROM orders WHERE customer_id = 
     1 | SELECT id, name FROM customers ORDER BY id LIMIT $1
(2 rows)
```

Uma instrução rodou cinquenta vezes. A aula 7 encontrou essa forma como subconsulta correlacionada
e disse que as duas são o mesmo erro em altitudes diferentes. Esta é a mais alta, e é pior, porque
cada uma dessas cinquenta é uma ida e volta pela rede em vez de uma busca dentro do banco.

## Por que é invisível

Três razões, e cada uma é uma razão de a revisão de código não pegar.

**Cada consulta é rápida.** Cinquenta buscas por índice a uma fração de milissegundo cada parecem
bem no `pg_stat_statements` ordenado pela média, e no log são cinquenta linhas sem nada de
especial. O custo é a contagem, e a aula 10 disse qual coluna mostra a contagem.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Dois painéis, cada um com uma faixa de aplicação em cima e uma de banco embaixo. À esquerda, intitulado uma consulta dentro do laço, sete pares de setas atravessam entre as faixas — um comando descendo e suas linhas voltando — seguidos de uma nota dizendo e mais quarenta e quatro, totalizando uma mais cinquenta idas e voltas. À direita, intitulado a relação carregada de uma vez, dois pares de setas e nada mais: duas idas e voltas.\"><text x=\"14\" y=\"18\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">A mesma página, os mesmos cinquenta clientes e seus pedidos. O que muda é quantas vezes a rede é atravessada.</text><rect x=\"14\" y=\"38\" width=\"400\" height=\"130\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"214.0\" y=\"56\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--amber)\">uma consulta dentro do laço</text><text x=\"26\" y=\"78\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">app</text><text x=\"26\" y=\"142\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">database</text><path d=\"M26 86 L402 86\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M26 134 L402 134\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M40 86 L40 134\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></path><path d=\"M40 134 L37 127 L43 127 Z\" fill=\"var(--amber)\"></path><path d=\"M46 134 L46 86\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></path><path d=\"M46 86 L43 93 L49 93 Z\" fill=\"var(--amber)\"></path><path d=\"M70 86 L70 134\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></path><path d=\"M70 134 L67 127 L73 127 Z\" fill=\"var(--amber)\"></path><path d=\"M76 134 L76 86\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></path><path d=\"M76 86 L73 93 L79 93 Z\" fill=\"var(--amber)\"></path><path d=\"M100 86 L100 134\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></path><path d=\"M100 134 L97 127 L103 127 Z\" fill=\"var(--amber)\"></path><path d=\"M106 134 L106 86\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></path><path d=\"M106 86 L103 93 L109 93 Z\" fill=\"var(--amber)\"></path><path d=\"M130 86 L130 134\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></path><path d=\"M130 134 L127 127 L133 127 Z\" fill=\"var(--amber)\"></path><path d=\"M136 134 L136 86\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></path><path d=\"M136 86 L133 93 L139 93 Z\" fill=\"var(--amber)\"></path><path d=\"M160 86 L160 134\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></path><path d=\"M160 134 L157 127 L163 127 Z\" fill=\"var(--amber)\"></path><path d=\"M166 134 L166 86\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></path><path d=\"M166 86 L163 93 L169 93 Z\" fill=\"var(--amber)\"></path><path d=\"M190 86 L190 134\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></path><path d=\"M190 134 L187 127 L193 127 Z\" fill=\"var(--amber)\"></path><path d=\"M196 134 L196 86\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></path><path d=\"M196 86 L193 93 L199 93 Z\" fill=\"var(--amber)\"></path><path d=\"M220 86 L220 134\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></path><path d=\"M220 134 L217 127 L223 127 Z\" fill=\"var(--amber)\"></path><path d=\"M226 134 L226 86\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></path><path d=\"M226 86 L223 93 L229 93 Z\" fill=\"var(--amber)\"></path><text x=\"250\" y=\"110\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">… e mais quarenta e quatro</text><text x=\"214.0\" y=\"158\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">1 + 50 idas e voltas</text><rect x=\"444\" y=\"38\" width=\"262\" height=\"130\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"575.0\" y=\"56\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--phosphor)\">a relação carregada de uma vez</text><text x=\"456\" y=\"78\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">app</text><text x=\"456\" y=\"142\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">database</text><path d=\"M456 86 L694 86\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M456 134 L694 134\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M500 86 L500 134\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><path d=\"M500 134 L497 127 L503 127 Z\" fill=\"var(--phosphor)\"></path><path d=\"M506 134 L506 86\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></path><path d=\"M506 86 L503 93 L509 93 Z\" fill=\"var(--phosphor)\"></path><path d=\"M540 86 L540 134\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><path d=\"M540 134 L537 127 L543 127 Z\" fill=\"var(--phosphor)\"></path><path d=\"M546 134 L546 86\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></path><path d=\"M546 86 L543 93 L549 93 Z\" fill=\"var(--phosphor)\"></path><text x=\"575.0\" y=\"158\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">2 idas e voltas</text><text x=\"14\" y=\"190\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Cada seta para baixo é um comando e cada seta tracejada para cima são as linhas dele. O motor faz mais ou menos o mesmo trabalho nos dois.</text><text x=\"14\" y=\"208\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">O que o laço custa é a travessia, e é por isso que ele é pior que o mesmo erro escrito como subconsulta correlacionada.</text></svg>", "caption": "Nada nas quatro linhas de código diz cinquenta. A contagem é propriedade de onde a segunda consulta está, e é por isso que isso se lê como código comum até a página ficar lenta."}
```

**Ele escala com o dado, não com o código.** Cinquenta clientes na máquina de quem desenvolve são
cinquenta e uma consultas e uma página que aparece num instante. Cinco mil em produção são cinco
mil e uma, e as mesmas quatro linhas levam segundos. Nada mudou além de N.

**É o ORM fazendo o que disse que faria.** Carregamento preguiçoso — buscar uma relação quando ela
é tocada pela primeira vez — é o padrão em quase todo mapeador porque é o comportamento certo para
o caso comum de não tocar em nada. O laço é o caso incomum, e o padrão não sabe que está dentro de
um.

## Onde ele se esconde

O laço literal acima é a forma de livro, e é a que as pessoas aprendem a ver. As outras são a
mesma coisa vestida de template ou de serializador:

- **Um template** que escreve `{{ order.customer.name }}` em cada linha de uma lista de pedidos. O
  laço está no motor de templates, e a consulta por linha está no acesso à propriedade.
- **Um serializador** que transforma uma lista de objetos em JSON, e cada objeto tem uma relação
  que o serializador percorre.
- **Um método no modelo** — `customer.total_spent()` — que roda uma consulta, chamado uma vez por
  linha de um relatório.
- **Relações aninhadas**: clientes, cada um com pedidos, cada um com linhas. N+1 dentro de N+1,
  que é N + N·M + 1, e o produto é o que faz uma página estourar o tempo.

Nenhum destes tem um `for` no código que o revisor lê, e é por isso que a contagem no
`pg_stat_statements` os acha e a leitura acha menos.

## A correção tem uma de duas formas

Pedir os pedidos **junto** com os clientes, numa instrução só, ou numa instrução por nível em vez
de por linha. As duas formas vêm embutidas em todo ORM sob um nome próprio, e a próxima seção é as
duas formas, o SQL delas, e quando cada uma é a certa.

O que a correção nunca é: desnormalizar, cachear, ou um servidor maior. A aula 2 disse isso do
outro lado: o N+1 é a causa mais comum de "o banco está lento" e nenhuma dessas coisas o toca. E
a aula 10 disse por que um servidor maior não ajuda um problema cujo custo é ida e volta.
