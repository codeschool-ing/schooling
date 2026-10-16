---
title: Esperar uma requisição pelo nome, ou responder você mesmo
version: 1
---

**`cy.intercept` é o recurso mais forte do Cypress, e vem direto do servidor que fica no caminho da
rede.** Um teste declara uma rota: um método e um endereço. A partir daí, toda requisição da
aplicação que combina com ela fica retida no servidor do Cypress, onde o teste pode vê-la passar e
esperar a resposta, ou respondê-la sem que o servidor de verdade fique sabendo.

O primeiro hábito que ela substitui é o errado. Um teste que precisa esperar os produtos é tentado a
dormir: `cy.wait(2000)`, dois segundos, e torcer. Funciona num notebook e falha num servidor de build
ocupado, e nos dias em que passa desperdiçou a maior parte desses dois segundos. A aula 3 mede quanto
custa esse palpite. `cy.wait` com um número continua na API, e a documentação desaconselha
justamente isso; o mesmo comando, dado o **nome** de uma rota, espera aquela requisição, leve o tempo
que levar.

Salve-o como `cypress/e2e/network.cy.js`:

```javascript
describe('the products request', () => {
  it('waits for the answer, not for a number of seconds', () => {
    cy.intercept('GET', '/api/products').as('products');
    cy.visit('/');
    cy.wait('@products').its('response.statusCode').should('eq', 200);
    cy.get('#products').should('have.attr', 'aria-busy', 'false');
    cy.get('#products li').should('have.length', 8);
  });

  it('draws whatever the server answers, however late', () => {
    cy.intercept('GET', '/api/products', {
      delay: 1500,
      body: [{ id: 'banana', name: 'Banana', price: 590, unit: 'dozen' }],
    }).as('products');
    cy.visit('/');
    cy.get('#products').should('have.attr', 'aria-busy', 'true');
    cy.wait('@products');
    cy.get('#products li').should('have.length', 1);
  });
});
```

Como todo spec desta aula, ele foi conferido com as definições de tipos do pacote e não foi
executado.

## Observar: o primeiro teste

`cy.intercept('GET', '/api/products')` sem resposta anexada só observa, e `.as('products')` dá um
nome à rota. **A rota é declarada antes do `cy.visit`.** A página pede os produtos assim que o script
dela roda, e uma rota declarada depois que essa requisição saiu não observa nada.

`cy.wait('@products')` então espera a resposta a essa requisição, e entrega o que o Cypress viu
dela: a requisição e a resposta. `.its('response.statusCode')` tira um campo disso e
`should('eq', 200)` o verifica. As duas linhas `should` seguintes leem a página que a resposta
produziu: a lista não está mais ocupada e tem oito itens.

É a forma de que a aula 3 precisa. Um teste que espera, pelo nome, a resposta de que depende é tão
rápido quanto o servidor num dia bom e continua certo num dia ruim.

## Responder: o segundo teste

Com um terceiro argumento, `cy.intercept` **responde a requisição ele mesmo**. Aqui a resposta é um
produto só, e `delay: 1500` a segura por um segundo e meio. O `/api/products` de verdade nunca é
consultado; o `/api/basket` não combina com a rota, então continua chegando à loja.

Para quem testa, isso compra duas coisas difíceis de obter de um servidor real:

- **Um estado sob encomenda.** A página com a lista ainda ocupada é um momento que dura alguns
  milissegundos num notebook. Segurado por 1500 ms, dura o bastante para conferir que a página diz
  que está carregando, em toda execução, do mesmo jeito.
- **Uma resposta que o servidor não daria.** Uma loja com um produto, uma loja vazia, um `500`: cada
  um é um objeto no teste, e não uma mudança na aplicação. A aula 15 trata dos dados de que um teste
  precisa, e este é um jeito de tê-los sem mexer nos de ninguém.

A ideia não é só do Cypress: o `page.route` do Playwright retém requisições do mesmo jeito, de fora
do navegador. O Cypress fez disso o jeito comum de escrever um teste, e a forma dele é a que a maioria
das pessoas conhece primeiro.

## O que um stub não consegue dizer

**Uma resposta simulada testa a página e não diz nada sobre o servidor.** O corpo do segundo teste é
uma cópia do que `/api/products` devolve hoje. Se amanhã a loja trocasse `price` por `cents`, este
teste continuaria passando, contra uma resposta que o servidor real não dá mais, enquanto a loja
mostraria todos os preços em branco. Uma suíte que simula tudo não enxerga esse tipo de quebra. O
arranjo comum é ter alguns testes que simulam, para os estados difíceis de alcançar, e outros que
não; verificar as respostas do servidor por conta própria é teste de API, assunto do próximo curso,
`api-mobile-automation`.

Mais uma coisa que as falhas da loja deixam à vista. Responda `/api/products` com um `500` e um
corpo que não é JSON, e o `app.js` lança um erro ao tentar lê-lo, como fez na seção do Console da
aula 1. **O Cypress reprova o teste quando a aplicação lança um erro que não trata**, seja lá o que o
teste estivesse verificando, que é a posição mais forte que aquela seção descreveu. A documentação
mostra como desligar isso para um erro conhecido, com `Cypress.on('uncaught:exception', ...)`; um
teste que desliga para todo erro abriu mão da evidência.
