---
title: Um produtor, e a resposta dele
version: 1
---

**Chamar `produce` não manda uma mensagem. Põe a mensagem num buffer e retorna na hora**; uma thread
dentro da biblioteca cliente junta as mensagens em lotes, um por partição, e manda os lotes quando
estão cheios ou já esperaram o bastante. Se uma mensagem chegou ao broker só se sabe depois, quando o
cliente chama uma função que você lhe deu, o **relatório de entrega**. Um programa que nunca olha os
relatórios de entrega não sabe se alguma coisa que produziu foi guardada.

Essa é a imagem errada comum: que o retorno do `produce` quer dizer que a mensagem está no Kafka. O
`tills.py` da lição 1 se safou porque chamava `flush` no fim, que espera toda mensagem ser confirmada,
e nada deu errado. Este produtor diz o que aconteceu com cada mensagem. Salve-o como
`~/work/producer.py`:

@@PTEX@@

Crie um tópico `sales` novo e mande as dez vendas do padrão. Se você ainda tem o cluster da lição 3,
rode antes `./cluster.sh stop`, `./cluster.sh new 1` e `./cluster.sh start`, como a lição 3 fez:

@@fence@@

Dez relatórios de entrega, todos sem erro, contados por partição. Com `murmur2_random`, Olinda e João
Pessoa vão para a partição 0, Caruaru e Natal para a 1, o Recife para a 2, como a lição 3 descobriu, e
as dez vendas passam pelas cinco lojas em ciclo: quatro, quatro e duas.

## Lotes, e para que serve o linger.ms

**`linger.ms` é quanto tempo o cliente espera por mais mensagens antes de mandar um lote que não está
cheio.** Com 0 ele manda assim que pode; com 100 segura um lote por até um décimo de segundo, para que
mais mensagens entrem nele. `batch.size` limita um lote a 16 384 bytes. Mande duzentas vendas a
duzentas por segundo, uma vez com cada configuração, para dois tópicos de uma partição:

@@fence@@

Depois conte os lotes no disco com o `kafka-dump-log.sh` da lição 3, que imprime uma linha
`baseOffset` por lote:

@@fence@@

As mesmas duzentas mensagens levaram **197 lotes** sem espera e **11** com 100 ms. Chegava uma
mensagem a cada 5 ms, então sem esperar quase toda mensagem viajou sozinha; com um décimo de segundo de
espera, umas dezoito dividiram cada viagem. Essa é a troca: cada mensagem espera até 100 ms a mais, e o
broker atende dezoito vezes menos requisições, cada uma levando mais. Sob carga pesada os lotes enchem
por tamanho antes de a espera acabar, então a configuração pesa mais em taxas moderadas como esta. O
padrão de 5 ms do programa é também o do librdkafka.

## Quando o broker não está lá

Pare o cluster e mande cinco vendas, desistindo de cada uma depois de cinco segundos em vez dos cinco
minutos do padrão (`message.timeout.ms`, 300 000):

@@fence@@

O `produce` aceitou as cinco sem reclamar, porque aceitar no buffer é tudo o que ele faz. Cinco
segundos depois o cliente desistiu de cada uma e **disse isso no relatório de entrega**: `Local:
Message timed out`, em que `Local` quer dizer que o erro foi levantado pelo cliente, não mandado por um
broker. Sem o callback essas cinco vendas teriam sumido, e o programa teria terminado normalmente.
Enquanto espera, o librdkafka também escreve no stderr uma linha para cada tentativa de conexão que
falha; o `2>/dev/null` joga essas linhas fora, e é por isso que o comando o tem.

O timeout é uma decisão. Cinco minutos aguentam um broker reiniciando; cinco segundos transformam uma
queda curta em vendas perdidas. Seja como for, o relatório de entrega é onde o programa fica sabendo,
e o que ele faz então, se grava a venda num arquivo, tenta de novo depois ou para o caixa, é escolha do
programa. A lição 7 volta ao que acontece quando a mensagem chegou e só a resposta se perdeu.
