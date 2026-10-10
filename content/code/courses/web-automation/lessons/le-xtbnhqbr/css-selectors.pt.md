---
title: Seletores CSS, contados na loja
version: 1
---

**Um seletor CSS é a linguagem que uma folha de estilos usa para dizer a que elementos uma regra
se aplica**, e a mesma linguagem acha elementos para um teste. Você provavelmente já escreveu
alguns: `.card` numa folha de estilos quer dizer todo elemento cuja lista de classes inclui `card`.
Um teste lê o mesmo seletor do mesmo jeito. A diferença está no que você quer dele. Uma regra de
estilo fica feliz em bater com quarenta elementos; um teste que quer clicar num botão precisa de um
seletor que bata com **um**.

## As peças

| seletor | encontra |
|---|---|
| `li` | todo elemento com essa tag |
| `.card` | todo elemento cuja `class` inclui `card` |
| `#products` | o elemento cujo `id` é `products` |
| `[data-testid]` | todo elemento que tem o atributo, com qualquer valor |
| `[data-testid="product-mango"]` | o atributo com exatamente esse valor |
| `[data-testid^="product-"]` | um valor que começa com `product-` (`$=` termina, `*=` contém) |
| `A B` | um `B` em qualquer lugar dentro de um `A`, a qualquer profundidade: o combinador de **descendente** |
| `A > B` | um `B` diretamente dentro de um `A`: o combinador de **filho** |
| `A:nth-child(2)` | um `A` que é o segundo filho do seu pai |
| `A:has(B)` | um `A` com um `B` em algum lugar dentro dele |

Peças juntas, sem espaço, querem dizer *tudo isso ao mesmo tempo*: `li.card[data-testid]` é um
`li` que tem a classe e o atributo. Um espaço entre elas quer dizer *dentro de*, e esse é o
deslize mais comum da linguagem inteira.

## Contando, na página de verdade

O `count.mjs` aceita quantos seletores você quiser. Primeiro as tags e as classes:

```
%%CAP count-css%%
```

Três coisas nessa lista merecem um segundo olhar:

- **`button` acha 9, e a página mostra oito botões.** O nono é o botão **Menu** do cabeçalho, que
  a folha de estilos esconde em qualquer janela com mais de 600 pixels de largura. Ele está no DOM
  mesmo assim, e um seletor não se importa se você consegue ver o que ele acha. `:visible` não é
  CSS; é um dos poucos acréscimos que o `page.locator` do Playwright aceita além do padrão, e ele
  traz a contagem de volta para 8;
- **`.card small` acha 8 e `.card > small` acha 0.** O `small` está dentro do `p`, então é neto do
  cartão, nunca filho. O combinador de descendente perdoa um nível de aninhamento, e o de filho
  não;
- **`.card` e `.card button` acham 8 cada**, o que está certo se você queria todos os cartões e
  errado se queria a banana. Uma contagem é o teste mais barato de um localizador, e dá para
  rodá-la antes de escrever o teste.

Agora atributos, posições e `:has`:

```
%%CAP count-attr%%
```

`[data-testid]` acha 9 porque o contador da cesta, no cabeçalho, também tem um;
`[data-testid^="product-"]` fica só com os oito cartões. Os dois seletores que acham Mango por
caminhos diferentes imprimem o mesmo título: um pelo test id do cartão, o outro pela **posição**,
o segundo filho da lista. `li:nth-child(9)` não acha nada, já que são oito. O aviso,
`[role="status"]`, está lá e vazio: ele só ganha texto depois de um clique.

## O que o CSS não consegue dizer

`.card:has(small)` acha os oito cartões. O `:has` deixa um seletor escolher um elemento pelo que
está dentro dele, que é o mais perto que o CSS chega de olhar para baixo e escolher o pai. Aqui não
ajuda, porque todo cartão tem os mesmos elementos dentro. **O que faz do cartão Mango o cartão Mango
é a palavra *Mango***, e um seletor CSS não testa texto nenhum: não existe seletor para *o cartão
cujo título diz Mango*. Um teste que precisa de um tem duas saídas. O XPath, na próxima seção, lê
texto. Os localizadores do próprio Playwright filtram por ele, duas seções depois dessa.

## Específico não é o mesmo que estável

As folhas de estilos ensinam um hábito que trabalha contra os testes. Quando duas regras CSS
discordam, vence aquela cujo seletor tem mais ids e classes, o que se chama **especificidade**, e
quem escreve folhas de estilos aprende a acrescentar peças até a sua regra vencer. Um seletor de
teste não ganha nada com isso:

```
%%CAP count-long%%
```

Os dois acham o mesmo título. O primeiro ainda precisa que a lista seja um `ul` diretamente dentro
de `main`, que mantenha o seu `id`, que o cartão mantenha a classe e o lugar na lista, e que cada
passo continue exatamente um nível abaixo do anterior. **Cada peça de um seletor é uma promessa que
a página precisa cumprir**, e o seletor mais curto que acha exatamente um elemento é o que tem menos
promessas.
