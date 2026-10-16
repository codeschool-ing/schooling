---
title: Quando um page object atrapalha
version: 1
---

Um page object é uma abstração, e uma abstração se paga: todo leitor de um teste precisa confiar
no método que ele chama, ou abri-lo. **Ela compensa quando esconde algo com que o teste não deveria
se importar, e custa quando esconde algo de que o teste trata.** Quatro jeitos de errar nisso
aparecem em quase toda suíte que adotou o padrão com entusiasmo.

## Embrulhos com o nome do widget

```javascript
async clickAddButtonOnBananaCard() {
  await this.page.getByTestId('product-banana').getByRole('button').click();
}

getBasketCountSpan() {
  return this.page.getByTestId('basket-count');
}
```

Cada um destes tem uma linha, e o número de linhas não é o problema: o `basketCount()` desta aula
também tem uma. **O problema é o nome.** `clickAddButtonOnBananaCard` descreve o markup, então muda
quando o markup muda, e o teste que o chama continua se lendo como uma lista de widgets. Troque o
nome pelo que o cliente faz, `addToBasket('banana')`, e a mesma linha passa a se pagar. A pergunta a
fazer a qualquer método é se o nome dele sobreviveria a um redesenho da página. Um método que só
renomeia uma chamada do Playwright, `click(locator)` em volta de `locator.click()`, não passa nessa
pergunta; é um segundo vocabulário para a mesma coisa.

## O objeto Deus

Um `AppPage` com métodos para a loja, a busca, a oferta, o cadastro e a SPA, porque todo teste o
importa mesmo. Depois de um ano ele tem duzentos métodos, três deles com um nome parecido com
`addToBasket` e comportamentos um pouco diferentes, e ninguém tem coragem de tirar nenhum. **Um page
object representa uma página, ou um componente representa uma parte dela**; quando uma classe
precisa de sumário, ela é várias classes. A página de busca da aula 3 ganha um `SearchPage`
próprio, com uma caixa e uma lista e nada sobre cestas.

## Esperas escondidas e falhas engolidas

```javascript
async addToBasket(id) {
  await this.product(id).add();
  await this.page.waitForTimeout(2000);   // let the toast go away
}

async isInBasket(id) {
  try {
    await expect(this.basketCount()).not.toHaveText('0', { timeout: 1000 });
    return true;
  } catch {
    return false;
  }
}
```

O primeiro acrescenta dois segundos a cada chamada, e todo teste paga por eles, inclusive os que
nunca olham o aviso. Foi posto ali por causa de um teste, e a aula 3 mostrou quanto vale uma pausa
fixa: um palpite sobre o tempo, longo demais num dia rápido e curto demais num dia lento. O segundo
transforma uma falha num `false` que quem chama talvez nunca confira, com um tempo limite que
ninguém vê a partir do teste. **Um page object pode esperar pelo que a sua própria ação precisa,
como o `click()` já faz; não deveria esperar pelo que algum teste precisou uma vez, e não pode
decidir que uma falha não é falha.** Esperas de propósito são o assunto da aula 13.

## Abstração antes da duplicação

O último erro é de momento. Um page object escrito antes de existirem testes para compartilhá-lo
adivinha quais passos vão se repetir, e adivinha errado: acaba com métodos que ninguém chama e sem
o que todo mundo precisa. Esta aula partiu de três testes que se repetiam e moveu só o que eles
repetiam. **Deixe a duplicação aparecer, depois tire-a**: uma segunda cópia é um sinal, uma terceira
é uma decisão.

## Além dos page objects

Os page objects organizam uma suíte em torno de páginas. Outro padrão a organiza em torno de
**pessoas e dos seus objetivos**: o **padrão Screenplay**, em que um teste se lê como um ator
executando tarefas, e as tarefas são feitas de interações com a página. O Serenity/JS é a
implementação em JavaScript mais conhecida. Ele resolve a mesma duplicação com mais estrutura, e a
troca, como sempre, é mais para aprender e mais para ler. Este curso fica com page objects e
componentes; reconheça o nome quando uma equipe o mencionar.
