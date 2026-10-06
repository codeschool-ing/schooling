---
title: Mantendo os ambientes parecidos
version: 1
---

**Paridade** é o grau em que os ambientes se parecem onde não deveriam diferir. Cada lacuna de
paridade é um lugar onde um release pode passar num ambiente e falhar no seguinte, e este curso já
encontrou três delas:

- **O fuso horário.** O rascunho de despacho da aula 5 passou num notebook em São Paulo e falhou em
  toda máquina em UTC. O notebook de quem desenvolve e um servidor raramente dividem um fuso, a menos
  que alguém faça isso acontecer.
- **O motor de banco.** A aula 1 seção 06 avisou contra testar com SQLite e implantar em PostgreSQL:
  os dois discordam em tipos e em SQL.
- **A versão do interpretador.** A matriz da aula 5 rodou três Pythons porque a produção poderia rodar
  qualquer um deles.

## As três lacunas

O *The Twelve-Factor App* dá nome às lacunas entre desenvolvimento e produção pelas causas:

| lacuna | o que é | como se fecha |
|---|---|---|
| **tempo** | o código escrito hoje chega à produção semanas depois | mudanças pequenas, implantadas sempre |
| **pessoas** | quem desenvolve escreve, outra pessoa implanta | o mesmo pipeline implanta em todo lugar |
| **ferramentas** | uma pilha mais leve no desenvolvimento que na produção | o mesmo motor, as mesmas versões, em contêineres se preciso |

A terceira lacuna é a que as equipes abrem de propósito, por conveniência: SQLite em vez de
PostgreSQL, uma fila em memória em vez do broker real, o Python mais novo no notebook e um mais velho
no servidor. Cada uma deixa o desenvolvimento mais rápido e cada uma é uma classe de defeito que só a
produção vai achar. **Uma imagem de contêiner é o remédio usual**: a mesma imagem, com o mesmo
interpretador e as mesmas bibliotecas, roda no notebook, na CI e na produção, e a única coisa que sobra
para diferir é a configuração. Na trilha `devops`, a aula 25 de `docker` roda uma suíte de testes
dentro do mesmo contêiner que o pipeline usa, por esse motivo.

## O que a paridade não dá

Paridade de software se alcança. **Paridade de dados e de carga não**, não por completo, e esse é o
assunto da próxima seção: uma homologação pode rodar o mesmo artefato, o mesmo motor e a mesma forma de
configuração, e ainda ser uma cópia pequena e quieta de um sistema grande e ocupado. Saber quais
lacunas você fechou e quais não é a parte útil, porque diz o que uma execução verde na homologação de
fato prova.
