---
title: O que o teorema CAP diz de fato
version: 1
---

O teorema CAP costuma ser citado como "consistência, disponibilidade, tolerância a partição:
escolha duas". **Essa versão está errada de um jeito que importa**, porque sugere que um sistema
pode decidir abrir mão da tolerância a partição, como se falhas de rede fossem opcionais. Não são.
Uma rede entre duas máquinas vai, em algum momento, perder pacotes, derrubar uma conexão ou pôr
entre elas um switch que para de encaminhar, e nenhuma escolha de desenho impede isso.

O que o teorema diz, como Eric Brewer o enunciou em 2000 e Seth Gilbert e Nancy Lynch o provaram em
2002, é mais estreito e mais útil:

> **Quando a rede entre as cópias de um dado se parte, um sistema precisa escolher, para cada
> pedido, entre dar uma resposta que pode estar desatualizada e não dar resposta nenhuma.**

Três palavras carregam o peso, e cada uma tem um sentido preciso:

- **Consistência**, no CAP, quer dizer **linearizabilidade**: toda leitura vê a escrita concluída
  mais recente, como se houvesse uma única cópia do dado. É uma promessa muito mais forte que o C do
  ACID, que trata de uma transação manter as regras de um banco.
- **Disponibilidade** quer dizer que todo pedido a uma cópia que está rodando recebe uma resposta
  que não é erro, em algum momento. Não uma resposta rápida; só uma resposta que não seja "não posso
  te dizer".
- **Partição** quer dizer que algumas cópias não conseguem falar com outras, enquanto os dois lados
  ainda são alcançáveis por alguns clientes.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Uma partição. Duas cópias dos dados, A à esquerda e B à direita, com a ligação entre elas cortada. Um cliente à esquerda escreve em A; um cliente à direita lê de B. B tem duas escolhas: responder com a própria cópia, que pode não ter a escrita feita em A, e continuar disponível; ou recusar até alcançar A, e continuar consistente.\"><rect x=\"60\" y=\"90\" width=\"140\" height=\"60\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"130\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">cópia A</text><text x=\"130\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">sold = 1</text><rect x=\"520\" y=\"90\" width=\"140\" height=\"60\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"590\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">cópia B</text><text x=\"590\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">sold = 0</text><path d=\"M200 120 L330 120\" stroke=\"var(--wire)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M390 120 L520 120\" stroke=\"var(--wire)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M345 100 L375 140\" stroke=\"var(--amber)\" stroke-width=\"2.5\" fill=\"none\"></path><path d=\"M375 100 L345 140\" stroke=\"var(--amber)\" stroke-width=\"2.5\" fill=\"none\"></path><text x=\"360\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">partição</text><rect x=\"70\" y=\"200\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"130\" y=\"217\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">cliente: vende</text><path d=\"M130 200 L130 152\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M130 152 L133.0 158.3 L127.0 158.3 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><rect x=\"530\" y=\"200\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"590\" y=\"217\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">cliente: lê</text><path d=\"M590 200 L590 152\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M590 152 L593.0 158.3 L587.0 158.3 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><text x=\"590\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">B responde sold = 0: disponível</text><text x=\"590\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">B recusa: consistente</text></svg>", "caption": "Durante uma partição, uma cópia que não alcança as outras responde com o que tem, ou não responde."}
```

Durante uma partição, uma cópia que recebe um pedido tem duas opções. Pode **responder com o que
tem**, o que pode deixar de fora escritas feitas do outro lado: disponível, não consistente. Ou pode
**recusar até ouvir o outro lado**: consistente, não disponível. Não há terceira opção, porque a
informação de que ela precisaria para ser as duas coisas está do outro lado da partição.

## O que ele não diz

- **Ele não diz nada sobre uma rede saudável.** Sem partição, um sistema pode ser consistente e
  disponível ao mesmo tempo, e na maior parte do tempo é. A seção 05 trata do custo que sobra mesmo
  assim.
- **Ele não é uma propriedade de um banco.** É uma escolha por operação. A bilheteria pode se recusar
  a vender durante uma partição e continuar mostrando as páginas a partir de uma réplica, e é
  exatamente isso que as duas próximas seções fazem.
- **"Escolher disponibilidade" não quer dizer respostas erradas.** Quer dizer respostas que podem
  estar desatualizadas, e um plano para o que acontece quando os dois lados se reencontram. As
  seções 07 a 09 são esse plano.

A aula 8 de `architecture` situou o CAP entre os padrões. Aqui você vai causar uma partição de
propósito, na replicação que montou na aula 2, e ver cada escolha acontecer.
