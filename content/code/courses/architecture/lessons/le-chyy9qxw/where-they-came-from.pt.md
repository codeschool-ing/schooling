---
title: De onde vieram os doze fatores
version: 1
---

O Heroku foi uma das primeiras plataformas em que quem programava mandava o código e a plataforma o
construía, rodava e mantinha rodando, em máquinas que essa pessoa nunca via. Em 2011 os engenheiros de
lá tinham visto um número muito grande de aplicações passar por isso, e alguns padrões separavam
sempre as aplicações que mudavam de máquina sem problema das que quebravam toda vez que eram tocadas.
Adam Wiggins, um dos fundadores do Heroku, anotou os padrões como **a Aplicação de Doze Fatores** (*the
Twelve-Factor App*), publicada em `12factor.net`.

A leitura comum é que são regras para o Heroku, ou para contêineres, ou para microsserviços. **São
regras para qualquer programa que uma plataforma vai iniciar, parar, copiar e mover sem perguntar a
ele**, e isso descreve o monólito da aula 1 tanto quanto uma função da aula 3. Kubernetes, Cloud Run e
Docker Compose pressupõem todos eles, diga ou não a documentação.

## A lista

| | fator | numa linha | nesta aula |
| --- | --- | --- | --- |
| I | base de código | uma base de código em controle de versão, muitas implantações dela | o diretório do catálogo |
| II | dependências | declaradas explicitamente e isoladas, nunca supostas na máquina | `requirements.txt` |
| III | configuração | o que difere entre implantações mora no ambiente | iniciar sem `DATABASE_URL` |
| IV | serviços de apoio | bancos, filas e caches são recursos conectados por uma URL | trocar o banco |
| V | build, release, execução | três estágios separados, e uma release nunca muda depois de feita | dar tag a uma imagem |
| VI | processos | sem estado, sem compartilhar nada; o que precisa persistir mora num serviço de apoio | `/hits` em três cópias |
| VII | vínculo de porta | a aplicação serve HTTP ela mesma, numa porta que recebe | `PORT` |
| VIII | concorrência | escalar rodando mais processos | `--scale catalogue=3` |
| IX | descartabilidade | rápida para iniciar, elegante para parar | dez segundos contra um |
| X | paridade entre desenvolvimento e produção | os mesmos serviços de apoio e versões no desenvolvimento e na produção | `postgres:17` nos dois |
| XI | logs | um fluxo de eventos na saída padrão; guardar é trabalho da plataforma | `docker compose logs` |
| XII | processos administrativos | tarefas avulsas rodam como processos da mesma release | `catalogue.py migrate` |

O resto da aula percorre os fatores nessa ordem, agrupados onde dois são uma ideia só, numa versão do
catálogo da Quitanda escrita para seguir os doze.
