---
title: A outra árvore, e a tela em branco
version: 1
---

A marcação diz o que as coisas são. Os estilos dizem com o que elas se parecem. Os dois precisam ser
entendidos antes de qualquer coisa ser desenhada, e o segundo é a razão de uma página ficar em branco
enquanto o navegador está demonstravelmente trabalhando.

## Estilos também viram uma árvore

Uma folha de estilo é lida para dentro da própria estrutura, o **CSSOM**, e a razão de ser uma árvore
em vez de uma lista é a herança: uma cor definida no body alcança um parágrafo dentro de uma seção
dentro de um artigo, a menos que algo a interrompa.

Então o navegador não consegue saber o estilo final de um elemento olhando uma regra. Ele tem que
combinar cada regra que casa, na ordem certa, e deixar os valores herdados descerem pela estrutura.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Três regras casando com o mesmo elemento, com a mais específica vencendo, a mais tardia entre duas iguais vencendo, e um valor herdado usado onde nada casou.\"> <rect x=\"20\" y=\"34\" width=\"680\" height=\"38\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"180\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">#price { color: green }</text> <text x=\"470\" y=\"53\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">vence: mais específica</text> <rect x=\"20\" y=\"82\" width=\"680\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"180\" y=\"101\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">.sale { color: red }</text> <text x=\"470\" y=\"101\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">uma classe perde para um id</text> <rect x=\"20\" y=\"130\" width=\"680\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"180\" y=\"149\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">p { color: black }</text> <text x=\"470\" y=\"149\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">um nome de elemento perde para os dois</text> <text x=\"360\" y=\"200\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">especificidade primeiro, depois ordem, e herança para o que não casou</text> <text x=\"360\" y=\"228\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">e é por isso que o estilo final de um elemento não se lê numa regra só</text> </svg>", "caption": "Três mecanismos, aplicados numa ordem. Ler uma regra sozinha quase nada diz sobre o resultado."}
```

Três coisas decidem o que vence, e são aplicadas nesta ordem.

**Especificidade.** Um seletor mais específico vence um menos específico — um id vence uma classe
vence um nome de elemento — independentemente de onde apareça.

**Ordem.** Entre regras de especificidade igual, a última vence.

**Herança**, que não é uma competição: é o que um elemento ganha quando nada casou com ele.

## Por que a tela fica em branco

Aqui está a parte que explica um sintoma que você já viu.

O navegador não vai pintar antes de ter os estilos. Não porque não consiga — ele poderia desenhar o
texto na hora — mas porque desenhá-lo sem estilo e desenhar de novo produziria um lampejo de conteúdo
sem estilo em cada carregamento, e a segunda versão não se pareceria nada com a primeira.

Então o CSS **bloqueia a renderização**: enquanto uma folha de estilo estiver pendente, a página fica
em branco.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Uma linha do tempo em que o HTML chega rápido e a tela fica em branco até a folha de estilo mais lenta chegar, porque o navegador se recusa a pintar conteúdo sem estilo.\"> <text x=\"20\" y=\"26\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">o servidor respondeu em 40 ms, e o visitante esperou dois segundos</text> <rect x=\"20\" y=\"38\" width=\"120\" height=\"34\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"80\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">o HTML</text> <rect x=\"146\" y=\"38\" width=\"420\" height=\"34\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".24\" stroke=\"var(--amber)\"></rect> <text x=\"356\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">esperando a folha de estilo mais lenta</text> <rect x=\"572\" y=\"38\" width=\"128\" height=\"34\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"636\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">primeira pintura</text> <rect x=\"20\" y=\"92\" width=\"546\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-dasharray=\"4 3\"></rect> <text x=\"293\" y=\"109\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">a tela, totalmente em branco, enquanto o navegador trabalha</text> <text x=\"360\" y=\"170\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\">a folha de estilo mais lenta define o primeiro momento em que algo pode aparecer</text> <text x=\"360\" y=\"200\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">e uma folha que importa outra acrescenta uma ida e volta na frente disso</text> <text x=\"360\" y=\"228\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">uma tela em branco não é prova de servidor lento</text> </svg>", "caption": "O navegador poderia pintar na hora. Ele se recusa, porque pintar duas vezes ficaria pior do que esperar uma."}
```

Isso tem uma consequência que vale enunciar como regra. **A folha de estilo mais lenta da página
define o primeiro momento possível em que algo aparece.** Uma folha num host de terceiros lento, uma
folha que importa outra folha que importa uma terceira — cada uma dessas é uma ida e volta na frente
do primeiro pixel.

E é por isso que uma tela em branco não é prova de servidor lento. A aula três separou os números;
este é um caso em que o servidor respondeu em quarenta milissegundos e o visitante esperou dois
segundos.

## O que não bloqueia

Nem tudo bloqueia, e as distinções são úteis.

Uma folha com uma **condição de mídia que não casa** é buscada em prioridade baixa e não bloqueia:
uma folha de impressão não atrasa a tela.

Estilos **dentro da página**, num bloco `<style>`, chegaram com o HTML e não custaram requisição
nenhuma. É essa a razão da técnica de pôr o punhado de regras necessárias para o topo da página
direto no documento e carregar o resto depois — a página consegue pintar com o que já tem.

**Importações dentro de uma folha** são o caso oposto e valem ser evitadas: o navegador não consegue
descobrir o segundo arquivo antes de ter lido o primeiro, então duas idas e voltas acontecem uma
depois da outra onde poderiam ter acontecido juntas.

## A cascata tem mais camadas do que as pessoas esperam

Vale uma seção curta, porque a ordem completa explica discussões que de outro modo terminam com
alguém acrescentando um ponto de exclamação.

O navegador tem uma folha de estilo própria — é por isso que um título sem estilo é grande e negrito e
um link é azul e sublinhado. Suas regras ficam em cima dela. E as configurações do próprio visitante
ficam em cima disso nos casos em que têm permissão.

Dentro das suas regras, há mais um nível de que ninguém gosta: o `!important`, que ergue uma
declaração acima da especificidade comum. Ele existe para casos genuínos — sobrepor algo numa folha
que você não pode editar — e na prática costuma ser uma pessoa vencendo uma discussão com a folha de
outra pessoa, e depois disso o único jeito de vencer a próxima é outro `!important`.

O instinto que vale construir: quando uma regra não se aplica, a pergunta é qual desses níveis a
venceu, e as ferramentas do navegador mostram a lista inteira com os perdedores riscados. Essa
exibição é a cascata tornada visível, e resolve num segundo o que ler uma folha de estilo resolve em
vinte minutos.

## O custo dos próprios estilos

Uma nota prática, porque é mensurável e fácil de errar.

Cada regra numa folha é uma regra que o navegador confere contra elementos. Um arquivo de vinte mil
regras, das quais uma página usa quarenta, custa o download, a leitura, e uma passagem de comparação
contra cada elemento.

A maior parte disso é rápida — navegadores são extremamente bons nisso — mas numa página grande num
celular modesto é um número real, e é a razão de um build que remove regras não usadas aparecer nas
medições em vez de apenas no tamanho do arquivo.

O instinto: uma folha de estilo não é um custo que você paga uma vez. É um custo que você paga de novo
a cada layout, e as próximas leituras são sobre com que frequência eles acontecem.
