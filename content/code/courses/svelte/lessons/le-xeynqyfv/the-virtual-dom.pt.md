---
title: O que é um DOM virtual, e por que o Svelte não tem um
version: 1
---

**Um DOM virtual é uma cópia da página guardada em JavaScript, refeita depois de cada mudança e
comparada com a cópia anterior.** O React monta um, e o Vue também. Quando algo muda, o framework
chama a sua função de componente de novo, recebe uma descrição nova de como a página deveria
ficar, compara com a descrição anterior e aplica na página real só as diferenças. Essa comparação se
chama **diffing**, e o passo que aplica o resultado se chama **patching**.

É um bom projeto, e vale entender o motivo dele antes de ver o que o Svelte faz no lugar. Mudar o DOM
real é lento comparado a mudar um objeto JavaScript, e escrever à mão código que muda exatamente os
nós certos é difícil. O DOM virtual deixa você escrever a página como se a refizesse inteira a cada
mudança, e torna isso barato mexendo na página real só onde as duas descrições diferem.

## O mesmo contador, escrito para o React

Este é o `Counter` da aula 1 como componente React. Ele está aqui para ser lido, não rodado; a aula
20 constrói o equivalente do planner nos outros três frameworks.

```jsx
// Counter.jsx, in React: not part of the planner.
import { useState } from "react";

export default function Counter() {
  const [minutes, setMinutes] = useState(0);
  return (
    <>
      <button onClick={() => setMinutes(minutes + 30)}>Add 30 minutes</button>
      <p>{minutes} minutes this week</p>
    </>
  );
}
```

Leia como o React lê. `Counter` é uma função que **devolve uma descrição** de um botão e de um
parágrafo. Quando o botão é apertado, `setMinutes` pede ao React para **chamar `Counter` de novo**. A
nova chamada devolve uma descrição nova, com `30` onde estava `0`. O React compara as duas, acha um
pedaço de texto diferente e muda esse texto na página.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Dois caminhos pelos quais um clique no botão chega à página. Em cima, o React: setMinutes pede ao React para chamar Counter de novo, que devolve uma descrição nova do botão e do parágrafo; o React a compara com a descrição anterior, acha um texto diferente e aplica essa mudança na página. Embaixo, o Svelte: o clique define o signal minutes, o signal avisa o único efeito que o leu, e o efeito define o texto do parágrafo. Os dois terminam com um nó de texto mudado; só o React montou e comparou duas descrições para chegar lá.\"><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">React</text><rect x=\"20\" y=\"36\" width=\"124\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"82\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">setMinutes(30)</text><line x1=\"144\" y1=\"58\" x2=\"160\" y2=\"58\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"160.0,58.0 152.6,61.1 152.6,54.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"160\" y=\"36\" width=\"124\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"222\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Counter() de novo</text><line x1=\"284\" y1=\"58\" x2=\"300\" y2=\"58\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"300.0,58.0 292.6,61.1 292.6,54.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"300\" y=\"36\" width=\"124\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"362\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">descrição nova</text><line x1=\"424\" y1=\"58\" x2=\"440\" y2=\"58\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"440.0,58.0 432.6,61.1 432.6,54.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"440\" y=\"36\" width=\"124\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"502\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">diff com a antiga</text><line x1=\"564\" y1=\"58\" x2=\"580\" y2=\"58\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"580.0,58.0 572.6,61.1 572.6,54.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"580\" y=\"36\" width=\"124\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"642\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">aplica 1 texto</text><rect x=\"160\" y=\"92\" width=\"404\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"362\" y=\"107\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">trabalho feito no navegador para achar a mudança</text><text x=\"20\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Svelte</text><rect x=\"20\" y=\"176\" width=\"124\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"82\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">minutes += 30</text><line x1=\"144\" y1=\"198\" x2=\"160\" y2=\"198\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"160.0,198.0 152.6,201.1 152.6,194.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"160\" y=\"176\" width=\"124\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"222\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">signal minutes</text><line x1=\"284\" y1=\"198\" x2=\"300\" y2=\"198\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"300.0,198.0 292.6,201.1 292.6,194.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"300\" y=\"176\" width=\"124\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"362\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o seu único leitor</text><line x1=\"424\" y1=\"198\" x2=\"440\" y2=\"198\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"440.0,198.0 432.6,201.1 432.6,194.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"440\" y=\"176\" width=\"124\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"502\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">define 1 texto</text><rect x=\"580\" y=\"176\" width=\"124\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"642\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">&lt;p&gt;30 …&lt;/p&gt;</text><line x1=\"564\" y1=\"198\" x2=\"578\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"578.0,198.0 570.6,201.1 570.6,194.9\" fill=\"var(--phosphor)\"></polygon><line x1=\"642\" y1=\"80\" x2=\"642\" y2=\"174\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line><text x=\"362\" y=\"252\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">descoberto uma vez, pelo compilador, antes de qualquer visita</text></svg>", "caption": "Os dois chegam à mesma mudança única. O React compara duas descrições para achá-la; o efeito do Svelte já sabia.", "same": ["React", "Svelte"]}
```

## O que o Svelte faz no lugar

O `Counter` compilado da aula 1 não tinha nenhum desses passos. Não havia segunda chamada ao
componente nem descrição para comparar. Havia **um efeito que define um nó de texto**, e ele roda
quando `minutes` muda, porque leu `minutes` na última vez que rodou.

**O trabalho que um DOM virtual faz em tempo de execução, o compilador do Svelte faz uma vez, na hora
do build.** Ele lê a marcação, vê que `{minutes}` está dentro do `<p>`, e escreve código que atualiza
esse nó e mais nada. A pergunta "o que esta mudança pode afetar?" é respondida pelo compilador, a
partir do código-fonte, em vez de por um diff, a cada mudança, no navegador do visitante.

Isso tem um custo, e é honesto nomeá-lo. Os componentes do Svelte só funcionam porque um compilador
os reescreveu, então a sintaxe do Svelte não é JavaScript e as ferramentas precisam entendê-la.
Componentes React são funções comuns que qualquer ferramenta de JavaScript lê. A aula 20 volta ao
que cada escolha custa ao longo da vida de um projeto.

## A palavra "reatividade"

Todo framework a usa, e ela quer dizer algo mais estreito do que parece: **quando um valor muda,
tudo o que depende dele se atualiza sozinho.** Os frameworks diferem em como descobrem o que depende
do quê. O React roda o componente de novo e compara a saída. O Svelte rastreia com **signals**:
valores que registram quem os leu, para que uma mudança vá direto aos leitores. Vue, Angular e Solid
também usam signals, e o Vue ainda faz o diff de um DOM virtual para os componentes que os seus
signals marcam como mudados, o que a aula 20 põe ao lado da abordagem do Svelte.
