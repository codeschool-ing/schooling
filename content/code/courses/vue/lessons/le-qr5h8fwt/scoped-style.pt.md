---
title: Estilo com scoped
version: 1
---

**Um bloco `<style scoped>` vale só para o componente em que foi escrito, mesmo que o `App.vue` e o
`AppFooter.vue` tenham os dois uma regra para `p`.** Em CSS puro as duas regras brigariam por cada
parágrafo da página, e a que viesse depois ganharia. Aqui cada uma fica em casa: os parágrafos do
cabeçalho são verdes, e o do rodapé é cinza e menor.

Nada no próprio CSS faz isso. Quem faz é o compilador do Vue, em duas metades, e as duas são
visíveis.

## O atributo no elemento

Peça ao `look` o HTML do rodapé como a página o tem agora:

```
ana@dev:~/vue/planner$ look http://localhost:5173/ --text - --html footer
[vite] connecting...
[vite] connected.
== the HTML of footer
<footer data-v-6704560a="" data-v-7a7a37b1=""><p data-v-6704560a="">Built with Vue 3.5.44</p></footer>
```

**Todo elemento que o `AppFooter` desenhou carrega um atributo a mais**, `data-v-` seguido de oito
caracteres. Os caracteres vêm do caminho do arquivo, então são os mesmos a cada execução e diferentes
para cada componente. O `App.vue` marca os seus próprios elementos com outro.

## O seletor na folha de estilo

A outra metade é a regra. Peça ao servidor de desenvolvimento o estilo do rodapé do jeito que a página
o pediu:

```
ana@dev:~/vue/planner$ look http://localhost:5173/ --text - --network | grep AppFooter
net  GET /src/components/AppFooter.vue  200
net  GET /src/components/AppFooter.vue?vue&type=style&index=0&scoped=6704560a&lang.css  200
```

A última linha é o bloco de estilo. Buscá-lo mostra o que o Vite envia:

```
ana@dev:~/vue/planner$ curl -s 'http://localhost:5173/src/components/AppFooter.vue?vue&type=style&index=0&scoped=6704560a&lang.css' | grep -o 'const __vite__css = .*'
const __vite__css = "\np[data-v-6704560a] {\n  color: #666;\n  font-size: 0.875rem;\n}\n"
```

**`p` virou `p[data-v-6704560a]`**: um parágrafo, e só um que carregue o atributo deste componente.
As duas metades se encontram no navegador, que aplica cada regra só onde as duas batem. Isso é tudo o
que o `scoped` é, e é por isso que uma regra com `scoped` não custa nada em tempo de execução: o
trabalho foi feito pelo compilador, e o navegador roda CSS comum.

## Os dois lugares por onde ele vaza, de propósito

**O elemento raiz de um componente filho recebe também o atributo do pai.** `<footer>` é a raiz do
`AppFooter`, então uma regra com `scoped` para `footer` escrita no `App.vue` o alcançaria. Isso é
proposital: deixa um pai posicionar e espaçar os filhos, que é uma decisão de layout que pertence ao
pai. Tudo *dentro* do filho fica fora do alcance do pai.

Quando um pai precisa mesmo estilizar algo mais fundo, o `:deep()` diz isso em voz alta:

```css
.courses :deep(p) {
  margin: 0;
}
```

O compilador põe o atributo em `.courses` e deixa o `p` livre, então a regra pega qualquer parágrafo
dentro da lista, neste componente ou num filho. **Use isso raramente**, porque amarra o pai ao
interior de um filho, e o filho não consegue mais mudar a própria marcação sem quebrar o estilo de
outra pessoa.

Regras que devem valer em todo lugar, uma fonte ou a cor de todo link, pertencem a uma folha de estilo
comum importada uma vez no `main.js`, ou a um bloco `<style>` sem `scoped`. O planner mantém tudo com
`scoped` até a aula 7 lhe dar uma aparência compartilhada.
