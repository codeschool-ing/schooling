---
title: Lista e detalhe, em um painel ou dois
version: 1
---

**O planner tem duas telas que andam juntas, a lista de cursos e o detalhe de um curso, e uma
janela larga as mostra lado a lado em vez de uma depois da outra.** Num celular em retrato o aluno
toca num curso, o detalhe substitui a lista, e *voltar* retorna à lista. Num tablet em paisagem a
lista fica à esquerda e o detalhe ocupa a direita; tocar em outro curso muda o lado direito e mais
nada. A documentação do Android chama isso de layout canônico, *list-detail*, e o padrão é o mesmo
no iOS, onde uma split view faz o serviço.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l08-panes\" aria-label=\"Dois jeitos de mostrar o planner. À esquerda, um painel: a lista de cursos ocupa a janela, tocar num curso a troca pelo detalhe dele, e voltar retorna à lista. À direita, dois painéis numa janela larga: a lista fica à esquerda com o curso escolhido destacado, e o detalhe ocupa a direita.\"><defs><marker id=\"l08-panes-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">um painel: a lista, depois o detalhe</text><text x=\"380\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">dois painéis: lista e detalhe lado a lado</text><rect x=\"20\" y=\"36\" width=\"130\" height=\"190\" rx=\"8\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"30\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Cursos</text><rect x=\"28\" y=\"66\" width=\"114\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"38\" y=\"78.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">sql</text><rect x=\"28\" y=\"96\" width=\"114\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"38\" y=\"108.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">mobile</text><rect x=\"28\" y=\"126\" width=\"114\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"38\" y=\"138.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">kotlin</text><rect x=\"200\" y=\"36\" width=\"130\" height=\"190\" rx=\"8\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"210\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">sql</text><rect x=\"208\" y=\"66\" width=\"114\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"218\" y=\"78.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">2026-10-19  50 min</text><rect x=\"208\" y=\"96\" width=\"114\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"218\" y=\"108.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">2026-10-23  60 min</text><path d=\"M150 80 L200 80\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-panes-ah-paper-dim)\"></path><text x=\"175\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">toque</text><path d=\"M200 190 L150 190\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l08-panes-ah-paper-dim)\"></path><text x=\"175\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">voltar</text><rect x=\"380\" y=\"36\" width=\"320\" height=\"190\" rx=\"8\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"388\" y=\"44\" width=\"120\" height=\"174\" rx=\"8\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"398\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Cursos</text><rect x=\"396\" y=\"74\" width=\"104\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"406\" y=\"86.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">sql</text><rect x=\"396\" y=\"104\" width=\"104\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"406\" y=\"116.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">mobile</text><rect x=\"396\" y=\"134\" width=\"104\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"406\" y=\"146.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">kotlin</text><rect x=\"516\" y=\"44\" width=\"176\" height=\"174\" rx=\"8\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"526\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">sql</text><rect x=\"524\" y=\"74\" width=\"160\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"534\" y=\"86.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">2026-10-19  50 min</text><rect x=\"524\" y=\"104\" width=\"160\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"534\" y=\"116.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">2026-10-23  60 min</text></svg>", "caption": "As mesmas duas telas, arrumadas pela janela. Num painel o detalhe substitui a lista e voltar a traz de volta; em dois painéis a lista nunca sai, então não há para onde voltar."}
```

## A troca é uma decisão de classe de tamanho

**A regra que o planner usa é uma regra de classe de tamanho, escrita uma vez**: dois painéis quando
a janela é pelo menos expanded de largura, 840 dp, e não é compact de altura. Abaixo disso, um
painel. A condição de altura está ali pelo caso que a documentação do Android cita: um celular em
paisagem pode ter largura suficiente, e altura de menos para dois painéis mostrarem algo útil.

Duas consequências saem de uma regra assim, e as duas passam despercebidas com facilidade:

- **O mesmo app passa de uma para a outra enquanto roda.** Um dobrável aberto com o detalhe na tela
  vai de um painel para dois, e fechado de novo volta. O curso escolhido precisa sobreviver à
  mudança, porque ele é estado, não layout: em dois painéis ele é a linha destacada, em um painel
  ele é a tela de cima.
- **Voltar quer dizer coisas diferentes em cada um.** Em um painel, voltar do detalhe retorna à
  lista. Em dois painéis não há para onde voltar, porque a lista nunca saiu. A aula 10 trata da
  pilha de voltar, e este é o primeiro lugar em que ela muda com a janela.

## Dobráveis: uma dobradiça e uma postura

Um dobrável acrescenta dois fatos que uma tela plana não tem. A documentação do Android sobre apps
atentos à dobra lista o que o sistema informa sobre uma dobra ou dobradiça: se o aparelho está
*plano* ou *meio aberto*, se a dobra corre na horizontal ou na vertical, se a dobradiça esconde
parte da tela, e se ela divide a janela em duas áreas lógicas. Ela cita duas posturas para as quais
um app pode projetar: *tabletop*, meio aberto com a dobra horizontal, como um notebook pequeno, e
*book*, meio aberto com a dobra vertical.

**Para o planner, o fato útil é a dobra vertical que separa a janela.** Se uma dobradiça divide a
janela ao meio, os dois painéis devem se encontrar na dobradiça, para que nada seja desenhado em
cima dela, e a lista e o detalhe fiquem cada um com uma metade. A mesma documentação observa que o
sistema não informa o ângulo da dobradiça, então um app reage à postura e não a um número de graus.

## A tela dividida é a mesma pergunta, menor

**Metade de um tablet em tela dividida pode ser uma janela medium, e aí o planner mostra um painel
ali**, exatamente como num celular grande, mesmo o aparelho sendo um tablet. Esse é o sentido de
perguntar pela janela: o tablet não mudou, o espaço mudou. A multitarefa do próprio iPad faz o
mesmo, e as diretrizes da Apple citam o estado de multitarefa, como um app em Slide Over, entre o
que define as classes de tamanho de um app.

A seção seguinte roda a regra sobre nove janelas de exemplo, incluindo o mesmo dobrável fechado e
aberto, e o mesmo tablet inteiro e pela metade.
