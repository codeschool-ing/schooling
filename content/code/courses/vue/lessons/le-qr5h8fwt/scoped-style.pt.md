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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 235\" role=\"img\" aria-label=\"As duas metades de um estilo scoped, lado a lado. À esquerda, o HTML do footer como a página o tem: o elemento footer carrega data-v-6704560a, o atributo do próprio AppFooter, e um segundo, data-v-7a7a37b1, que é o do App.vue, porque o elemento raiz de um filho também recebe o atributo do pai; o parágrafo de dentro carrega só data-v-6704560a. À direita, o bloco de estilo como o Vite o envia: a regra escrita para p virou p[data-v-6704560a], com cor #666 e tamanho de fonte 0.875rem. Embaixo, o navegador aplica a regra só onde os dois casam.\"><text x=\"180\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o HTML: um atributo em cada elemento</text><rect x=\"30\" y=\"36\" width=\"300\" height=\"124\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"46.0\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">&lt;footer data-v-6704560a</text><text x=\"96.4\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">data-v-7a7a37b1&gt;</text><text x=\"58.6\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">&lt;p data-v-6704560a&gt;</text><text x=\"46.0\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">&lt;/footer&gt;</text><text x=\"180\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o segundo é o do App.vue, na raiz do filho</text><text x=\"540\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a folha de estilo: um seletor reescrito</text><rect x=\"390\" y=\"36\" width=\"300\" height=\"124\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"406\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">p {</text><text x=\"674\" y=\"56\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">como foi escrito</text><text x=\"406\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">p[data-v-6704560a] {</text><text x=\"674\" y=\"80\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">como o Vite envia</text><text x=\"419\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">color: #666;</text><text x=\"419\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">font-size: 0.875rem;</text><text x=\"406\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">}</text><line x1=\"180\" y1=\"162\" x2=\"290\" y2=\"188\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"290.0,188.0 282.1,189.3 283.5,183.3\" fill=\"var(--phosphor)\"></polygon><line x1=\"540\" y1=\"162\" x2=\"430\" y2=\"188\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"430.0,188.0 436.5,183.3 437.9,189.3\" fill=\"var(--phosphor)\"></polygon><rect x=\"200\" y=\"190\" width=\"320\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">o navegador aplica a regra onde os dois casam</text></svg>", "caption": "O compilador marca os elementos e reescreve o seletor; o navegador roda CSS comum."}
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
