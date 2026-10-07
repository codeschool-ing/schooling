---
title: Economia: cortar o que não carrega nada
version: 1
---

**Cada palavra custa ao leitor um pouco de atenção, então uma palavra que não carrega nada é um
pequeno imposto sobre as que carregam.** Economia não é brevidade por si só: a frase precisa da
seção anterior muitas vezes era mais longa que a vaga. É tirar o que não trabalha.

## Cinco tipos de palavra que não trabalham

1. **Pigarro.** "Gostaria de entrar em contato para passar uma atualização rápida a respeito de…",
   "Como alguns de vocês talvez saibam…". O leitor sabe que você está escrevendo para ele; comece
   pelo assunto.
2. **Ressalvas empilhadas.** "Parece que possivelmente poderia ser o caso de…". Uma ressalva honesta
   carrega a incerteza; três delas fazem quem escreve parecer inseguro de tudo, inclusive do que tem
   certeza.
3. **Substantivos feitos de verbos.** "Realizar uma análise de", "efetuar a implementação de",
   "tomar uma decisão sobre". O verbo está escondido dentro de um substantivo: analisar,
   implementar, decidir.
4. **Voz passiva que esconde quem agiu.** "O deploy foi aprovado" convida a pergunta "por quem?",
   que em geral é o ponto da frase. "Bruna aprovou o deploy" responde. A passiva vai bem quando quem
   agiu de fato não importa: "a tabela é copiada toda noite".
5. **Repetição do que o leitor acabou de ler.** "Como mencionado acima", um resumo do parágrafo
   anterior, ou uma linha final que diz a mesma coisa de novo num tom mais firme.

## Um parágrafo, cortado

Este é um parágrafo do primeiro rascunho da proposta de Lívia, com 86 palavras no original:

> Gostaria de passar uma atualização rápida a respeito da situação do sistema de checkout. Como
> alguns de vocês talvez saibam, temos enfrentado alguns problemas nas noites de sexta. Depois de
> realizar uma análise minuciosa do problema, parece que possivelmente poderia estar relacionado ao
> fato de o planejador de rotas compartilhar o banco de dados com o checkout. Acreditamos que talvez
> seja uma boa ideia tomar uma decisão sobre separar os dois num futuro próximo, já que isso
> potencialmente resolveria o problema.

E a versão que ela manteve, com 40:

> O checkout falha para cerca de 180 clientes toda sexta à noite. A causa é que o planejador de rotas
> e o checkout dividem um banco de dados e disputam as conexões dele no pico. Proponho separar os
> dois, e preciso de uma decisão até 19 de março.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Duas barras medindo palavras. O primeiro rascunho tem 86 palavras e não diz tamanho, data nem pedido claro. A versão final tem 40 palavras e diz o tamanho, 180 clientes por semana, a causa, a proposta e a data, 19 de março.\"><defs><marker id=\"cut-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"30\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">primeiro rascunho</text><rect x=\"150\" y=\"28\" width=\"516\" height=\"24\" rx=\"3\" fill=\"var(--wire)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"676\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">86</text><text x=\"150\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">sem tamanho, sem data, sem pedido claro</text><text x=\"30\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">versão final</text><rect x=\"150\" y=\"108\" width=\"240\" height=\"24\" rx=\"3\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"400\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">40</text><text x=\"150\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o tamanho: 180 clientes por semana</text><text x=\"150\" y=\"168\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a causa, a proposta, a data: 19 de março</text><text x=\"690\" y=\"190\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">palavras</text></svg>", "caption": "Menos da metade das palavras, e mais informação: o enchimento estava no lugar onde os fatos deveriam estar."}
```

Nada verdadeiro se perdeu, e duas coisas foram ganhas: o tamanho do problema e a data da decisão,
que a versão longa nunca dizia. **Cortar abriu espaço para os fatos que o enchimento estava
ocupando.** É o resultado de costume. O enchimento raramente é um acréscimo a um parágrafo
completo; é o que quem escreve produz quando a frase precisa ainda não está clara para ele.

## O que não cortar

A economia dá errado quando tira as palavras de que o leitor precisa:

- **O motivo.** "Use a réplica" é mais curto que "use a réplica, porque o primário é o gargalo no
  pico", e a versão curta vai ser desfeita pela primeira pessoa que não souber por quê.
- **O contexto que falta a quem chegou agora.** Uma sigla definida uma vez custa cinco palavras e
  salva todo leitor que não a conhecia.
- **A cortesia que está fazendo um trabalho.** "Obrigada pela revisão rápida" não é enchimento numa
  mensagem para alguém que abriu mão da tarde. É informação sobre como o esforço dessa pessoa foi
  recebido.

O teste para qualquer palavra é o mesmo: **se ela fosse apagada, o leitor perderia alguma coisa?**
Se não, ela sai. Se sim, ela fica, por mais longa que a frase fique.
