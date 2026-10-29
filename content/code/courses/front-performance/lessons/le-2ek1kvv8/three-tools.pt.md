---
title: Três ferramentas, três perguntas
version: 1
---

**A aula 5 deu três números a uma página. Esta é sobre as ferramentas que dizem por que um número é o
que é.** Cada uma das três responde a uma pergunta diferente, e um problema de desempenho costuma
precisar das três, uma depois da outra:

| ferramenta | o que ela faz | a pergunta que responde |
|---|---|---|
| **Lighthouse** | carrega a página uma vez, em condições que ela escolhe, e dá nota ao que aconteceu | o que está errado nesta página, por alto, e onde devo olhar primeiro? |
| **o painel de desempenho** | grava tudo o que a thread principal do navegador fez enquanto você usava a página | o que exatamente o navegador estava fazendo naqueles 800 milissegundos lentos? |
| **WebPageTest** | carrega a página num navegador real em outro lugar, numa rede que você escolhe, várias vezes | como é uma primeira visita de longe, numa conexão lenta? |

As três produzem **dados de laboratório**, no sentido da seção "Dados de campo: o número do visitante"
da aula 5: um navegador, condições que alguém escolheu, uma medida que dá para repetir. Nenhuma delas
sabe como a página se comporta para os visitantes reais. O Lighthouse e o painel rodam no seu
computador; o WebPageTest roda no de outra pessoa, que é a graça dele e também o motivo de ele precisar
da página num endereço público.

## Onde você já as encontrou

**O Lighthouse está nas ferramentas de desenvolvedor do Chrome**, numa aba própria, e na linha de
comando, que é como esta aula o roda, porque um comando pode ser repetido e a saída dele lida por um
programa. O **PageSpeed Insights**, a página do Google em pagespeed.web.dev, é o Lighthouse rodado dos
servidores do Google com os dados de campo do CrUX mostrados acima, para uma página na internet: o
laboratório e o campo numa tela só, que é o jeito mais claro de ver que eles discordam.

**O painel de desempenho é a aba Performance** das mesmas ferramentas de desenvolvedor, no Chrome e em
todo navegador feito sobre o Chromium, como o Edge. O Firefox e o Safari têm profilers próprios que
respondem à mesma pergunta com outro formato de arquivo; esta aula grava o do Chromium, porque é o
navegador que ela já controla.

## O que esta aula mede

O planner, no seu computador, com as mesmas ferramentas de antes. Primeiro o Lighthouse, na página de
curso e depois numa página inicial de cinco mil cursos, onde ele acha algo que vale corrigir. Depois um
trace da thread principal, lido por um programa curto e aberto no painel. Depois uma **cascata**, o
gráfico que as três ferramentas desenham das requisições da página ao longo do tempo. O WebPageTest por
último, descrito em vez de rodado, porque precisa de um endereço na internet e este curso mantém tudo
na sua própria máquina.
