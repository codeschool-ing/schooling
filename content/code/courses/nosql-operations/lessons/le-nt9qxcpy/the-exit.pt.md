---
title: A saída, com preço antes de você precisar dela
version: 1
---

Ninguém planeja sair de um provedor no dia em que entra nele, e é por isso que **a saída é mais
barata de planejar nesse dia**. Preços mudam, uma licença muda, uma região de que você precisa não é
oferecida, uma empresa é comprada. A pergunta não é se você vai sair, mas quanto custaria se
precisasse, e quatro custos compõem a resposta.

## Egress

Provedores de nuvem cobram pouco ou nada pelos dados que entram e cobram pelos dados que saem da
rede deles, por gigabyte. Tirar um banco de lá é a maior transferência única que a maioria das
aplicações faz na vida, e ela é cobrada nesse preço. A tabela de preços do seu provedor dá o valor;
multiplique pelo tamanho dos dados e dos backups, e o primeiro número do plano de saída existe.

## A janela

**Copiar não é instantâneo, e as escritas não param para esperar.** O caminho mais simples é o que
a aula 11 usou: um dump de um lado, um restore do outro, com a aplicação parada no meio para que nada
seja escrito no lado antigo depois do dump. A aritmética é o plano. Um dump que lê a 50 MB/s leva
cerca de 5,6 horas para um terabyte, antes do restore e da construção dos índices. Uma loja que pode
fechar por uma noite consegue isso. Uma que não pode precisa do outro caminho, replicar
continuamente para o lugar novo e trocar em minutos, que é um projeto por si só. Meça a sua própria
taxa de dump e restore num teste, em vez de confiar nos 50 deste parágrafo.

## Recursos que o outro lado não tem

Este é o custo que se esconde. Todo serviço cria recursos além do banco que roda: um índice de busca
embutido, gatilhos que chamam uma função quando um documento muda, uma tabela global replicada pelo
provedor, um editor de consultas no console com que todo mundo se acostumou. Cada um é conveniente, e
cada um é um pedaço da aplicação que mora no provedor. **Liste-os à medida que os adota**, uma linha
por recurso com o que o substitui do lado de fora, e a lista vai ser curta o bastante para ser útil no
dia em que importar. Um motor compatível funciona nos dois sentidos: código escrito contra as
peculiaridades de uma tradução precisa ser testado de novo contra o produto real na saída.

## O restore no seu próprio laboratório

O único teste de saída que você pode fazer sem sair é o backup. A maioria dos serviços deixa
exportar um para um armazenamento que você controla: um dump, um arquivo RDB para o Redis, um
snapshot dos arquivos de dados. Pegue o backup do provedor, restaure em contêineres como os que este
curso subiu e rode as leituras da aplicação contra ele. **Isso não foi rodado para este curso**, por
falta de provedor; com um, é trabalho de uma tarde, e prova três coisas de uma vez:

1. o backup está completo e é legível por software que você mesmo roda;
2. o formato de exportação e suas ferramentas são ferramentas que você sabe usar sob pressão;
3. o tempo que levou é o piso da janela acima.

Um banco que você consegue restaurar no seu próprio laboratório é um banco do qual você consegue
sair. Um que você não consegue é um sobre o qual a tabela de preços do provedor decide por você.
