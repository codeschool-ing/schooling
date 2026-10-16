---
title: De onde veio o ofício
version: 1
---

**O título é novo e o trabalho é antigo.** As empresas movem dado de onde ele é feito para onde é lido
desde que têm mais de um sistema. O que mudou, três vezes, foi quanto dado havia e quem fazia a mudança
— e cada mudança deixou uma palavra para trás, que você vai encontrar em vagas e nos cursos depois
deste.

## Três épocas, e a palavra que cada uma deixou

**O data warehouse e o ETL, a partir dos anos 1990.** Os sistemas operacionais de uma empresa —
vendas, estoque, folha — eram copiados toda noite para um **data warehouse**, um banco desenhado para
ler e somar em vez de receber pedidos. A cópia se chamava **ETL**: *extrair* da fonte, *transformar*
no formato do warehouse, *carregar*. Quem fazia isso eram desenvolvedores de ETL e administradores de
banco, em ferramentas que desenhavam o fluxo como caixas e setas. O warehouse ainda é o centro da
maioria das plataformas de dados; `warehouse-modeling` é como se projeta um.

**Big data, a partir do fim dos anos 2000.** Empresas da web tinham mais dado do que uma máquina
conseguia guardar — cada clique, cada busca — e quase nada disso era tabela. O Google publicou como
espalhava armazenamento e processamento por milhares de máquinas baratas, e o Hadoop copiou a ideia em
código aberto. O dado passou a morar em arquivos espalhados por um cluster, e processá-lo passou a
significar escrever programas, não desenhar caixas. Foi aí que **"engenheiro de dados"** virou um título
comum: o trabalho tinha virado engenharia de software. A aula 9 é o que envolve espalhar dado por
muitas máquinas, e por que isso é difícil.

**A nuvem, a partir de meados dos anos 2010.** Warehouses que crescem sob demanda, armazenamento que
custa centavos por gigabyte por mês, e filas e processadores de fluxo como serviço. Duas coisas
vieram daí. Carregar o dado bruto primeiro e transformá-lo dentro do warehouse ficou mais barato do que
transformá-lo no caminho — **ELT** em vez de ETL, que a aula 3 compara. E a parte difícil passou de
*conseguimos guardar* para *conseguimos confiar, pagar e encontrar*, que são as aulas 2 e 7.

## O que ficou

Cada época acrescentou ferramentas e manteve o problema. Um job noturno em 1998 e um processador de
fluxo em 2025 têm de responder às mesmas perguntas: chegou tudo, alguma coisa chegou duas vezes, é o que
a fonte quis dizer, e chegou a tempo. **As ferramentas de uma vaga mudam a cada poucos anos; essas
quatro perguntas não mudam há trinta**, e é por isso que este curso gasta as suas horas com elas.

É também por isso que se espera de um engenheiro de dados os hábitos de um engenheiro de software —
controle de versão, testes, revisão de código, automação — e não só os de uma pessoa de banco de dados.
`git`, que a trilha `data` põe antes deste curso, é o primeiro desses hábitos; `pipelines-etl` põe
testes em volta de um pipeline.
