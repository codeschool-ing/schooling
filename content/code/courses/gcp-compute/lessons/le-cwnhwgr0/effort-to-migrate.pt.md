---
title: O esforço de migrar, que nenhuma tabela de preços mostra
version: 1
---

A tabela da seção anterior dá preço a um serviço que já cabe em cada opção. **A maioria dos
serviços não cabe nas quatro no dia em que alguém pergunta**, e o trabalho de fazê-los caber é um
custo que não aparece em fatura nenhuma e é pago uma vez, nas semanas de alguém. Então a segunda
pergunta depois de "quanto custa rodar?" é "quanto custa chegar lá?", e quem responde são os hábitos
do próprio serviço.

## O que cada opção pede do código

Toda opção deste curso roda um programa. Elas diferem no que supõem sobre ele:

| a opção | o que o código precisa ser |
|---|---|
| uma máquina do Compute Engine | qualquer coisa que rode em Linux; nada muda |
| um grupo gerenciado de instâncias | iniciado por um script de inicialização ou embutido numa imagem, e substituível: nenhum estado no disco de boot (lições 4 e 7) |
| Cloud Run | um contêiner que escuta em `$PORT`, não guarda estado entre requisições e termina cada requisição em até 60 minutos (lição 8) |
| um job do Cloud Run | um contêiner que faz o trabalho e sai, até 7 dias por tarefa (lição 10) |
| funções do Cloud Run | uma função por ponto de entrada, escrita para o Functions Framework (lição 17) |
| GKE | um contêiner, mais os objetos do Kubernetes em volta e um cluster de que alguém cuida (lição 13) |

**O hábito mais caro de desfazer é estado em disco local**: uploads gravados em `/tmp`, sessões
guardadas na memória, um arquivo SQLite ao lado do programa. Uma máquina os mantém por acaso; todas
as outras linhas da tabela os perdem, num reinício, numa redução de escala ou numa revisão nova.
Levar esse estado para o Cloud Storage, um banco ou um cache costuma ser a maior parte do trabalho
de uma migração, e é o mesmo trabalho qualquer que seja o destino escolhido.

## Limites que decidem sozinhos

Alguns números fazem a escolha antes de qualquer preço. Uma requisição que leva 40 minutos cabe nos
60 do Cloud Run e não cabe nos 9 de uma função acionada por evento; um relatório que roda três horas
cabe num job do Cloud Run e em serviço nenhum. Um programa que precisa de GPU roda no Compute
Engine, no GKE ou no Cloud Run com GPU, e o preço é a aritmética da lição 2, não a desta. Um
protocolo que não é HTTP, um servidor de jogo em UDP por exemplo, exclui tudo que é construído em
volta de uma requisição: sobra uma máquina ou um pod.

**Anote os limites antes de comparar preços**, porque uma opção mais barata que não carrega o
trabalho não é opção. A verificação leva dez minutos e economiza a reunião em que alguém descobre o
problema com a migração já começada.

## O custo de operar, depois

O esforço não termina no dia da mudança. **A operação é a metade recorrente do custo de migrar**, e
é a coluna que ordena as opções na ordem inversa da do preço:

- uma máquina precisa de atualizações do sistema operacional, de alguém olhando o disco e de alguém
  que perceba quando ela cai;
- um grupo gerenciado de instâncias assume as falhas e a substituição, e deixa a imagem com você;
- o GKE assume muito mais, e acrescenta um cluster com atualizações, node pools e permissões
  próprias, que as lições 13 a 16 mostram ser um assunto à parte;
- o Cloud Run deixa com você o contêiner e a configuração dele, e muito pouco além disso.

Uma equipe de duas pessoas que economiza 40 dólares por mês rodando máquinas em vez do Cloud Run
está pagando a diferença em tardes. Às vezes essa é a troca certa; de graça ela nunca é.
