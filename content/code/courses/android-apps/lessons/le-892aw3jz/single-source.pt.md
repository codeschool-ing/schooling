---
title: Uma fonte única da verdade, e por que ela é o banco
version: 1
---

**Uma tela que lê de dois lugares mostra duas respostas.** Imagine a tela da semana do planner
pedindo as sessões ao servidor, e ao banco as que foram acrescentadas offline, e juntando as duas.
Toda pergunta sobre essa tela passa a ter duas metades: qual lista é mais nova, o que acontece
quando uma requisição falha no meio, por que o total cai por um instante enquanto a rede responde. A
cura de costume é uma regra que cabe numa frase, e as aulas 14 e 15 montaram as duas peças de que
ela precisa.

> **A tela lê só o banco. A rede só escreve no banco.**

Essa regra é a **fonte única da verdade**. O Room é a fonte, porque é o único lugar que está sempre
ali: offline, num trem lento, um segundo depois de o app abrir. O servidor é de onde a verdade
*vem*, e ela chega à tela por um caminho só, uma escrita no Room, que a seção 06 da aula 15 mostrou
fazer todo `Flow` que lê aquela tabela responder de novo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Três caixas. À esquerda, o servidor. No meio, o repositório, com refresh e add. À direita, o Room, a fonte única da verdade. Abaixo do Room, a tela da semana. Setas: as sessões do servidor passam pelo refresh e entram no Room. Uma sessão nova passa pelo add e entra primeiro no Room, e de lá vai para o servidor. A tela da semana lê só do Room, por um Flow, e nunca do servidor.\"><rect x=\"0\" y=\"0\" width=\"720\" height=\"250\" fill=\"var(--ink)\"></rect><rect x=\"20\" y=\"40\" width=\"150\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"95\" y=\"70\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">o servidor</text><text x=\"95\" y=\"92\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">de onde vem a verdade</text><rect x=\"260\" y=\"30\" width=\"190\" height=\"90\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"355\" y=\"56\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--amber)\">SessionRepository</text><text x=\"355\" y=\"80\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">refresh()</text><text x=\"355\" y=\"100\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">add()</text><rect x=\"540\" y=\"40\" width=\"160\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"620\" y=\"70\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">Room</text><text x=\"620\" y=\"92\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a fonte única da verdade</text><rect x=\"540\" y=\"170\" width=\"160\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"620\" y=\"203\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">a tela da semana</text><line x1=\"172\" y1=\"60\" x2=\"256\" y2=\"60\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><text x=\"214\" y=\"52\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sessões</text><line x1=\"452\" y1=\"75\" x2=\"536\" y2=\"75\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><text x=\"494\" y=\"67\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">escreve</text><line x1=\"620\" y1=\"112\" x2=\"620\" y2=\"166\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><text x=\"628\" y=\"143\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">Flow</text><line x1=\"172\" y1=\"90\" x2=\"256\" y2=\"90\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></line><text x=\"214\" y=\"106\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sessões novas</text><text x=\"300\" y=\"205\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">nenhuma seta do servidor para a tela</text></svg>", "caption": "O servidor escreve no Room através do repositório, e a tela lê só o Room.", "same": ["Room"]}
```

**O repositório é a classe que guarda a regra.** É o único código que conhece o DAO e a API ao mesmo
tempo, e tudo acima dele lhe pede um `Flow` de sessões e chama `refresh()` ou `add()`. Nada num
ViewModel decide se o dado vem da rede: a aula 10 manteve o ViewModel livre disso, e esta aula dá a
ele algo para chamar. O Hilt da aula 12 é como o repositório chega ao ViewModel num app de verdade;
aqui os testes o montam à mão, o que deixa cada peça à vista.

## O que esta aula não faz

O desenho offline-first completo, com uma fila de operações pendentes, novas tentativas com espera
crescente e conflitos entre dois aparelhos, é o curso `mobile-offline`, que vem depois deste: a aula
7 dele é escrever primeiro no local e a aula 8 é a outbox. A seção 06 daqui dá o primeiro passo
disso e diz onde para.
