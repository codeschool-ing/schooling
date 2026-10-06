---
title: O que o coletor mantém
version: 1
---

**O coletor mantém todo objeto alcançável a partir de uma raiz, e nada mais.** As raízes são o que o
programa sempre consegue alcançar: o objeto global, e as variáveis locais das funções rodando neste
momento. Dali ele segue toda referência, toda propriedade, todo item de array, toda variável que uma
closure capturou, e **o que ele não alcança é lixo**:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"O coletor de lixo parte das raízes, o objeto global e as variáveis das funções rodando agora, e segue toda referência. O cache e as configurações que ele alcança ficam vivos. O autor e o livro apontam um para o outro, mas nada alcançável aponta para nenhum dos dois, então os dois são coletados, ciclo e tudo.\"><defs><marker id=\"reach-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><defs><marker id=\"reach-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"90\" width=\"130\" height=\"60\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"85.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">raízes</text><text x=\"85.0\" y=\"129.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">globais, a pilha</text><rect x=\"220\" y=\"40\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"295.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">cache</text><rect x=\"220\" y=\"160\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"295.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">settings</text><rect x=\"420\" y=\"40\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"480.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">entries</text><path d=\"M150 110 L216 64\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#reach-ah-phosphor)\"></path><path d=\"M150 130 L216 176\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#reach-ah-phosphor)\"></path><path d=\"M370 60 L416 60\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#reach-ah-phosphor)\"></path><rect x=\"420\" y=\"120\" width=\"280\" height=\"100\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><rect x=\"440\" y=\"150\" width=\"100\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"490.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">author</text><rect x=\"580\" y=\"150\" width=\"100\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">book</text><path d=\"M540 160 L576 160\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#reach-ah-amber)\"></path><path d=\"M576 178 L540 178\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#reach-ah-amber)\"></path><text x=\"560\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">inalcançável: coletado</text><text x=\"560\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um ciclo, e ainda lixo</text></svg>", "caption": "Vivo quer dizer alcançável a partir de uma raiz. Apontar um para o outro não conta."}
```

Uma ideia antiga de gerenciamento de memória conta referências, e libera um objeto quando a contagem
chega a zero. Esse esquema não consegue liberar dois objetos que apontam um para o outro. **O coletor
do JavaScript não conta; ele rastreia a partir das raízes**, então um ciclo para o qual nada alcançável
aponta é lixo como qualquer outro:

```javascript
let author = { name: "Machado de Assis" };
let book = { title: "Dom Casmurro", author };
author.books = [book];

const ref = new WeakRef(author);
author = null;
book = null;

setTimeout(() => {
  globalThis.gc();
  console.log("the pair after collection:", ref.deref());
}, 0);
```

```
ana@dev:~/js$ node --expose-gc cycle.js
the pair after collection: undefined
```

O `books` do autor apontava para o livro, e o `author` do livro apontava de volta. Quando as duas
variáveis viraram `null`, nada alcançável apontava para nenhum dos dois, e **o par foi coletado junto**:
o `WeakRef`, que a aula 5 apresentou como um jeito de perguntar sem segurar, não achou nada.

## O que isso significa para vazamentos

**Um vazamento é sempre um caminho a partir de uma raiz que você não quis manter.** Um cache guardado
numa variável de nível de cima de um módulo é alcançável enquanto o programa rodar, e tudo o que está
nele também. Um listener acrescentado a um objeto de vida longa é alcançável por esse objeto, e tudo o
que a closure dele capturou também. Achar um vazamento é achar esse caminho, e consertá-lo é cortá-lo.
As duas próximas seções são os três caminhos que causam a maioria dos vazamentos na prática.
