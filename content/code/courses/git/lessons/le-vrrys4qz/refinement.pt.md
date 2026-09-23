---
title: Refinamento: deixando tickets prontos
version: 1
---

Tickets prontos não aparecem sozinhos. Eles são feitos no **refinamento** (*backlog refinement* ou, em
equipes mais antigas, *grooming*): uma sessão regular, muitas vezes de uma hora por semana, em que a equipe
lê os tickets perto do topo do backlog **antes** de alguém estar para começá-los.

## O que acontece nele

Para cada ticket, a equipe faz as perguntas que a Ana fez tarde demais:

- O problema está claro? Quem o tem?
- Quais são os critérios de aceite? Alguém escreve, ali mesmo.
- O que a gente não sabe? Quem consegue descobrir até a semana que vem?
- Está grande demais?

O product owner traz o *o quê* e o *por quê*; quem desenvolve e quem testa trazem o *como* e o *o que pode
dar errado*. Algumas equipes chamam uma versão pequena disso de **three amigos** (os três amigos): uma
pessoa de produto, uma de desenvolvimento e uma de testes olham um ticket juntas por dez minutos antes de
ele ficar pronto. Cada uma vê problemas que as outras não veem: o Diego teria perguntado do estorno no
primeiro minuto, porque testar o caminho que dá errado é o trabalho dele.

## Dividindo um ticket grande

*Pagar online* é grande demais para ser um ticket só, mesmo depois de as perguntas terem resposta. A
pergunta é **como** dividir, e há dois jeitos:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Dois jeitos de dividir o ticket 35, pagar online. À esquerda, dividido por camada em três tickets: uma tabela de pagamentos no banco, uma rota de pagamento no servidor e um botão de pagar na página de pedidos; nada que um cliente use até as três ficarem prontas. À direita, dividido por fatia em três tickets: pagar com Pix, pagar com cartão, estornar um pagamento; cada uma atravessa página, servidor e banco, e cada uma é usável sozinha, nesta ordem.\"><defs><marker id=\"sl-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">dividido por camada</text><rect x=\"20\" y=\"50\" width=\"300\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">tabela de pagamentos no banco</text><rect x=\"20\" y=\"98\" width=\"300\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">rota de pagamento no servidor</text><rect x=\"20\" y=\"146\" width=\"300\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"164\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">botão de pagar na página</text><text x=\"20\" y=\"212\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">nada que um cliente use até as três ficarem prontas</text><path d=\"M355 20 L355 262\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"390\" y=\"22\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">dividido por fatia</text><text x=\"452\" y=\"68\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">página</text><path d=\"M460 68 L700 68\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"2 4\"></path><text x=\"452\" y=\"116\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">servidor</text><path d=\"M460 116 L700 116\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"2 4\"></path><text x=\"452\" y=\"164\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">banco</text><path d=\"M460 164 L700 164\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"2 4\"></path><rect x=\"470\" y=\"44\" width=\"66\" height=\"150\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"503\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">pagar com</text><text x=\"503\" y=\"221\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">Pix</text><rect x=\"548\" y=\"44\" width=\"66\" height=\"150\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"581\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">pagar com</text><text x=\"581\" y=\"221\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">cartão</text><rect x=\"626\" y=\"44\" width=\"66\" height=\"150\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"659\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">estornar um</text><text x=\"659\" y=\"221\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">pagamento</text><text x=\"390\" y=\"252\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">cada uma usável sozinha, nesta ordem</text></svg>", "caption": "Uma fatia passa por todas as camadas, então a primeira pode ser lançada, e ensinar alguma coisa, enquanto a segunda é construída.", "same": ["Pix"]}
```

**Dividir por camada** (banco, servidor, página) parece natural para quem desenvolve, e produz três tickets,
nenhum dos quais faz algo que um cliente veja. Nada pode ser lançado até os três terminarem, então o
primeiro retorno de verdade chega semanas depois.

**Dividir por fatia** atravessa todas as camadas para uma coisa pequena e completa. *Pagar com Pix* precisa
de um pouco do banco, um pouco do servidor e um pouco da página, e no fim um cliente consegue pagar com
Pix. Pode ser lançado sozinho e ensinar alguma coisa à equipe enquanto *pagar com cartão* é construído. É
essa a divisão de que os branches curtos da aula 9 dependem: uma fatia cabe num branch que vive um ou dois
dias.

Um ticket que é uma fatia tem um título que um cliente entenderia. Se o título só faz sentido para quem
desenvolve (*criar tabela de pagamentos*), provavelmente é uma camada.
