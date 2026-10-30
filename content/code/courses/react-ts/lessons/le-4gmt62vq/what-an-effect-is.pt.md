---
title: Um efeito mantém algo fora do React em dia
version: 1
---

**A renderização de um componente não pode mudar nada fora dele. Um efeito é onde você faz isso
mesmo assim, de propósito, depois de a renderização ter chegado à página.** O título da aba do
navegador, uma conexão com um servidor, um listener na janela, um timer: nenhum deles faz parte da
árvore que o React desenha, e um efeito é como um componente mantém um deles em dia com o que ele
renderiza.

A forma é sempre a mesma:

```tsx
useEffect(() => {
  // runs after React has committed this render to the page
  return () => {
    // runs before the effect runs again, and when the component goes away
  }
}, [dependencies])
```

Três partes, e esta aula as pega uma de cada vez: **a função**, que faz o trabalho; **a limpeza**
que ela pode devolver, que o desfaz; e **o array de dependências**, que diz quando o trabalho precisa
ser feito de novo.

```schooling-figure
{"svg": "<svg data-fig=\"timeline\" viewBox=\"0 0 720 225\" role=\"img\" aria-label=\"Uma linha do tempo de duas renderizações. Renderização 1, commit 1, depois o efeito 1 roda. Mais tarde monday muda: renderização 2, commit 2, depois a limpeza 1 roda com os valores da renderização 1, e só então o efeito 2. A página já mudou antes de cada efeito rodar.\"><line x1=\"20\" y1=\"120\" x2=\"700\" y2=\"120\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><rect x=\"20\" y=\"104\" width=\"80\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"60.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">render 1</text><rect x=\"110\" y=\"104\" width=\"80\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"150.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">commit 1</text><rect x=\"200\" y=\"104\" width=\"80\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"240.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">effect 1</text><rect x=\"350\" y=\"104\" width=\"80\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"390.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">render 2</text><rect x=\"440\" y=\"104\" width=\"80\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"480.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">commit 2</text><rect x=\"530\" y=\"104\" width=\"80\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"570.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">cleanup 1</text><rect x=\"620\" y=\"104\" width=\"80\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"660.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">effect 2</text><text x=\"320\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">monday muda</text><line x1=\"320\" y1=\"150\" x2=\"320\" y2=\"124\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"320.0,124.0 323.2,131.5 316.8,131.5\" fill=\"var(--paper-dim)\"></polygon><path d=\"M 240 104 C 300 40 520 40 570 104\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></path><polygon points=\"570.0,104.0 562.7,100.3 567.7,96.2\" fill=\"var(--amber)\"></polygon><text x=\"405\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">desfaz o que o efeito 1 começou</text><text x=\"150\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a página mostra a renderização 1</text><line x1=\"110\" y1=\"198\" x2=\"340\" y2=\"198\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"560\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a página mostra a renderização 2</text><line x1=\"440\" y1=\"198\" x2=\"700\" y2=\"198\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line></svg>", "caption": "Um efeito roda depois do seu commit; a limpeza dele roda antes do próximo."}
```

Duas coisas nessa imagem importam mais que o resto:

- **Um efeito roda depois do commit.** A página já mostra a nova renderização quando o efeito começa,
  então um efeito nunca atrasa o que o usuário vê, e pode ler a página como ela está agora.
- **A limpeza roda antes do próximo efeito**, com os valores da própria renderização. O que um efeito
  começou, a limpeza dele para: o listener que ele adicionou, a requisição que ele espera.

## O que um efeito não é

A palavra sugere "algo que acontece por causa de outra coisa", e esse é o mau uso mais comum: um
efeito que observa um pedaço de estado para definir outro. A aula 4 já deu nome à ferramenta certa
para isso, que é calcular o valor ao renderizar, e a seção "Talvez você não precise de um efeito"
lista os outros casos. **O teste é se há algo fora do React para manter em dia.** Se a resposta for
não, não é um efeito.

O planejador tem três coisas fora do React que precisa manter em dia: os dados no servidor, o título
da aba e o teclado. As três próximas seções as fazem nessa ordem.
