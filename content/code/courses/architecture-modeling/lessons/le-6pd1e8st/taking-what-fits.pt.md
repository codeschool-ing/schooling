---
title: Quanto TOGAF uma empresa de quarenta engenheiros precisa
version: 1
---

**O TOGAF é muito criticado por ser pesado, e a crítica é justa com o TOGAF aplicado inteiro.
Aplicado como o próprio padrão pede, adaptado, ele é um conjunto de boas perguntas com nome.** A
habilidade útil é saber quais partes se pagam em qual tamanho de empresa.

## A crítica, dita com justiça

- **Entregáveis demais.** O framework de conteúdo lista dezenas de artefatos. Um time que produz
  todos passa o tempo documentando em vez de decidindo.
- **Lento demais para o jeito como se faz software.** Um ciclo fase a fase fica desajeitado ao lado
  de times que publicam todo dia.
- **Abstrato demais.** Ele diz o que produzir e bem menos sobre como tomar uma boa decisão de
  arquitetura, que é a parte difícil.

Cada crítica é verdadeira para um certo jeito de usar o framework, e os Guias da Série da 10ª edição
sobre prática ágil e digital existem porque The Open Group as ouviu.

## O que a Carcará manteve

| mantido | por quê |
| --- | --- |
| **os quatro domínios** | tornaram visível a camada de negócio: os reembolsos em dinheiro e o relatório de caixa |
| **a declaração de trabalho da fase A** | duas páginas que fizeram a diretoria concordar com escopo e sucesso antes de gastar dinheiro |
| **linha de base, alvo e análise de lacunas** | achou as capacidades que o alvo esqueceu |
| **arquiteturas de transição** | 26 rodoviárias não conseguiam virar num dia só, e os estados do meio eram os mais difíceis |
| **princípios com implicações** | deixaram os times prever as respostas do conselho |
| **dispensas com data de fim** | as exceções continuaram exceções |

## O que a Carcará pulou

O metamodelo de conteúdo completo, a maior parte do catálogo de artefatos, uma ferramenta formal de
repositório e os graus mais finos de conformidade. **Não se perdeu nada de que alguém sentisse
falta**, e a decisão de pular essas partes está ela mesma escrita na adaptação da fase Preliminar,
para que o próximo arquiteto possa revê-la.

## A regra prática

Um framework é uma lista de perguntas que alguém aprendeu do jeito difícil. **Use as perguntas;
produza só os documentos que alguém vai ler.** Para cada entregável do TOGAF, pergunte: *quem lê
isto, e o que essa pessoa faz de diferente por causa disso?* Se não houver resposta, pule e anote
que pulou. As aulas 9 e 10 aplicam a mesma regra aos vizinhos do TOGAF, o IAF e o Zachman.
