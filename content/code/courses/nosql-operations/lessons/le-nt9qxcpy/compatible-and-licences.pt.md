---
title: Compatível não é o mesmo motor, e a licença faz parte do produto
version: 1
---

Dois fatos sobre uma oferta gerenciada passam fácil despercebidos na página de preços.
**"Compatível com MongoDB" ou "compatível com Cassandra" descreve um protocolo, não um banco**, e a
licença do software por baixo decide quem pode vendê-lo como serviço. O histórico de licença de dois
dos três produtos deste curso mudou na última década exatamente por isso.

## Um protocolo na frente de outro motor

O Amazon DocumentDB aceita drivers do MongoDB e responde a comandos do MongoDB. O Azure Cosmos DB
oferece uma API para MongoDB e uma para Apache Cassandra. O Amazon Keyspaces aceita drivers do
Cassandra e CQL. **Nenhum dos três roda o software que este curso rodou.** Cada um é o motor de
armazenamento do próprio provedor com uma camada de tradução na frente, feita para parecer o
original do lado do cliente.

É um projeto legítimo, e tem uma consequência para a qual você se planeja: a tradução cobre a maior
parte da linguagem, e não toda. Cada um desses serviços publica uma página de **operadores, comandos
e recursos suportados e não suportados**, e essa página é a documentação a ler antes de qualquer
outra. Um estágio de agregação que a tradução não tem, um tipo de índice que ela não constrói, um
nível de consistência que ela não oferece, uma configuração de servidor sem equivalente: cada um é
encontrado ou nessa lista antes da migração, ou em produção depois dela. O comportamento sob carga
também difere, porque o motor por baixo é outro; o que as aulas 16 a 19 disseram sobre compactação e
tombstones descreve o Cassandra, e um serviço compatível com Cassandra pode não ter nenhum dos dois
na mesma forma.

Os serviços operados por quem faz cada produto, MongoDB Atlas, Redis Cloud e DataStax Astra DB, são
construídos sobre o próprio produto, e esse é o argumento mais forte a favor deles quando a
compatibilidade importa.

## As licenças, como fatos

| produto | histórico de licença |
|---|---|
| MongoDB | passou da AGPLv3 para uma licença própria, a **Server Side Public License (SSPL)**, em outubro de 2018. A SSPL exige que quem oferece o software como serviço publique o código-fonte do serviço inteiro em volta dele; a Open Source Initiative não a aprova como licença de código aberto |
| Redis | licença BSD até 2024. Com o **Redis 7.4**, em 2024, passou a uma licença dupla: a Redis Source Available License v2 (RSALv2) ou a SSPLv1. Com o **Redis 8**, em 2025, a AGPLv3 foi acrescentada como terceira opção |
| Valkey | um **fork do Redis 7.2.4**, a última versão sob BSD, iniciado em 2024 sob a Linux Foundation e ainda sob a licença BSD. Vários serviços de Redis de provedores de nuvem agora oferecem o Valkey |
| Cassandra | a **Apache License 2.0**, como projeto da Apache Software Foundation, sem mudança |

As imagens que este curso roda trazem parte disso consigo. O pacote do MongoDB diz isso no arquivo
de copyright, e o Cassandra traz o texto da licença ao lado dos binários:

```
ana@vm:~$ docker run --rm mongo:8.0 mongod --version | head -1
db version v8.0.32
ana@vm:~$ docker run --rm mongo:8.0 grep -A2 "^License" /usr/share/doc/mongodb-org-server/copyright
License:

    SSPL
ana@vm:~$ docker run --rm cassandra:5.0 head -3 /opt/cassandra/LICENSE.txt

                                 Apache License
                           Version 2.0, January 2004
```

O Redis é o que o laboratório não consegue confirmar:

```
ana@vm:~$ docker run --rm redis:7.4 redis-server --version
Redis server v=7.4.11 sha=00000000:0 malloc=jemalloc-5.3.0 bits=64 build=f20da322597b16d7
ana@vm:~$ docker run --rm redis:7.4 find / -xdev \( -iname "*licen*" -o -iname "copying*" \) -not -path "/usr/share/*"
```

A busca não encontrou **arquivo de licença nenhum** na imagem `redis:7.4` fora os do próprio sistema
operacional. A versão é a 7.4.11, que pelo anúncio do próprio Redis cai na licença dupla
RSALv2/SSPLv1; essa afirmação se apoia no anúncio, não em nada que a imagem traga.

## O que isso significa para você

**Rodar qualquer um deles para a sua própria aplicação é permitido por todas as licenças acima.** A
SSPL e a RSALv2 restringem oferecer o próprio banco como serviço a terceiros; uma loja que guarda
seus pedidos no MongoDB ou suas sessões no Redis não está fazendo isso. Onde isso pesa é na escolha
do provedor e do futuro: um provedor de nuvem que não pode vender o Redis mais novo vende o Valkey,
ou um Redis mais antigo, ou um motor compatível, e o recurso que você quer no ano que vem pode existir
só de um lado dessa linha. Qual versão, sob qual licença, de quem, é uma linha do registro de decisão
da aula 22, e só é parecer jurídico quando um advogado o escreve.
