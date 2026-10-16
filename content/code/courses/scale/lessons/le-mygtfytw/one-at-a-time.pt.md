---
title: Como esta aula funciona
version: 1
---

A aula 4 desenhou cinco formatos para os dados da bilheteria. Esta aula roda **um banco de verdade
de cada família**, põe nele um pouco dos dados da bilheteria, faz a ele a pergunta em que ele é bom
e depois uma em que é ruim, para que a troca de cada família seja algo que você viu acontecer.

Os cinco, com o que cada um é nesta aula:

| banco | família | a pergunta que recebe |
|---|---|---|
| MongoDB 8.0 | documento | a página de um show, e todo show numa casa |
| DynamoDB (Local) | chave-valor e documento | os ingressos de um comprador para um show |
| Cassandra 5.0 | coluna larga | as últimas leituras na portaria de um show |
| Neo4j 5.26 | grafo | os shows a que os compradores de um show também foram |
| InfluxDB 2.9 | série temporal | ingressos vendidos por hora, por canal |

## Um de cada vez

Cada banco roda num contêiner próprio, iniciado no começo da sua seção e **removido no fim dela**
com `docker rm -f`. Nenhum precisa da bilheteria, e nenhum guarda nada de que você vá precisar
depois. Rodá-los um de cada vez é o que faz o laboratório da aula 1 bastar: Cassandra e Neo4j são
programas Java que dimensionam a memória pela máquina que encontram, então cada comando abaixo lhes
dá um limite com `--memory`, e o Cassandra também recebe o tamanho máximo do heap. Juntos, os cinco
quereriam mais memória do que um laboratório de 8 GB deveria dar; um de cada vez, o maior ocupa
cerca de um gigabyte.

As imagens somam uns 4 GB de disco. Elas ficam depois que os contêineres são removidos, então uma
seção pode ser rodada de novo sem baixar nada; `docker image rm` com o nome da imagem libera o
espaço quando você terminar a aula.

## Os arquivos

Cada banco recebe os dados de um arquivinho que você cria em `~/tickets`, mostrado inteiro na sua
seção e copiado para dentro do contêiner com `docker cp` antes de rodar. Eles são curtos de
propósito: cem shows, cinco ingressos, seis leituras de portaria, dez shows e sessenta compradores,
três horas de vendas. **O ponto é o formato de cada pergunta, não o volume**, e todo número impresso
vem de dados que cabem numa tela.

## Sobre o DynamoDB

O DynamoDB é um serviço que só existe na nuvem da Amazon. O que roda aqui é o **DynamoDB Local**, um
programa que a Amazon publica para desenvolver e testar contra a mesma interface na sua própria
máquina. Ele aceita os mesmos pedidos e devolve as mesmas respostas, e não é o serviço: não tem
partições espalhadas por máquinas, não tem estrangulamento e não tem conta. A seção 06 diz quais
partes do que você vê seriam diferentes no de verdade.
