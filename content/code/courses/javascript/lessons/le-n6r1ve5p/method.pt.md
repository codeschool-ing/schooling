---
title: Um método para um bug
version: 1
---

**Depurar fica mais rápido quando é uma busca em vez de uma série de palpites.** Cada ferramenta
desta aula responde uma pergunta. Um método decide qual pergunta fazer em seguida.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Cinco passos em linha, o último apontando de volta para o primeiro: reproduzir o bug de propósito, ler o que o erro diz, achar a linha com um ponto de parada, explicar a causa numa frase, depois corrigir e guardar um teste que o teria pegado. Quando a explicação se mostra errada, volte a achar a linha.\"><defs><marker id=\"method-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><defs><marker id=\"method-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><defs><marker id=\"method-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"50\" width=\"120\" height=\"56\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"80.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">reproduzir</text><text x=\"80.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">de propósito</text><path d=\"M140 78 L156 78\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#method-ah-phosphor)\"></path><rect x=\"160\" y=\"50\" width=\"120\" height=\"56\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"220.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">ler</text><text x=\"220.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o erro inteiro</text><path d=\"M280 78 L296 78\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#method-ah-phosphor)\"></path><rect x=\"300\" y=\"50\" width=\"120\" height=\"56\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">localizar</text><text x=\"360.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">com um breakpoint</text><path d=\"M420 78 L436 78\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#method-ah-phosphor)\"></path><rect x=\"440\" y=\"50\" width=\"120\" height=\"56\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"500.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">explicar</text><text x=\"500.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">numa frase</text><path d=\"M560 78 L576 78\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#method-ah-phosphor)\"></path><rect x=\"580\" y=\"50\" width=\"120\" height=\"56\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"640.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">corrigir</text><text x=\"640.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">e guardar um teste</text><path d=\"M640 106 L640 160 L80 160 L80 110\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 3\" marker-end=\"url(#method-ah-amber)\"></path><text x=\"360\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">o bug de novo, ou outro: recomece</text><path d=\"M500 106 L500 130 L360 130 L360 110\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"5 3\" marker-end=\"url(#method-ah-paper-dim)\"></path><text x=\"430\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">explicação errada</text></svg>", "caption": "Um método em vez de um palpite: cada passo estreita onde o bug pode estar."}
```

1. **Reproduza de propósito.** Ache os passos que fazem o bug acontecer toda vez. Um bug que você
   não consegue fazer acontecer é um que você não tem como saber que corrigiu. Se ele só acontece
   às vezes, isso é informação: tempo, um cache, dados que mudam entre execuções;
2. **Leia o erro inteiro.** O tipo, a mensagem, o arquivo e a linha, e a pilha embaixo. `Cannot
   read properties of undefined (reading 'title')` já dizia que algo que devia ser um livro não
   era;
3. **Localize com um breakpoint**, não com mais linhas de `log`. Pause onde o valor está errado e
   leia a pilha para achar de onde ele veio. Depois pause mais cedo, até chegar à primeira linha em
   que um valor não é o que você esperava;
4. **Explique numa frase**: "o laço pede o índice 3 de um array de três itens". Se você não
   consegue escrever essa frase, achou onde o bug aparece, não onde ele mora, e uma correção agora
   seria um palpite;
5. **Corrija, e guarde um teste que o teria pegado.** O teste é o que impede o mesmo bug de voltar
   daqui a seis meses, quando alguém arrumar o laço. O `front-quality`, na aula 2, escreve esses
   testes.

## Quando o código não é seu para ler

Uma página em produção costuma rodar código **minificado**: uma linha longa, nomes curtos, sem
comentários. Um **source map** é um arquivo que o build escreve ao lado e que mapeia cada posição de
volta para o código original, e o DevTools o usa para mostrar os seus próprios arquivos, com
breakpoints nas suas próprias linhas. Guarde os source maps onde a sua equipe alcança e decida de
propósito se o público alcança. Nenhum passo de build roda neste curso, então não havia nada para
mapear aqui.

Um erro que um aluno nunca relata é um que você nunca vê. O `front-delivery`, na aula 11, envia
erros dos navegadores dos usuários para um lugar que a equipe lê, e é onde este método costuma
começar num produto de verdade.
