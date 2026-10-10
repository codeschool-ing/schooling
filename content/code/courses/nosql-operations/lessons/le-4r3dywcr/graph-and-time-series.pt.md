---
title: Grafo e série temporal, descritos em vez de instalados
version: 1
---

Mais duas famílias merecem ser conhecidas pelas perguntas que respondem, e **este curso não instala
nenhuma delas**. O motivo é o assunto do curso, não os produtos. As operações que ele ensina, da
replicação ao reparo, se aprendem nos três servidores que você já tem, e cada servidor a mais
custaria memória ao laboratório sem uma nova lição de operação para mostrar. Nada
abaixo foi executado. Os produtos citados são exemplos, e nada numa aula posterior depende de nenhum
deles.

## Grafo: perguntas que seguem ligações

A pergunta para a qual um armazenamento de grafo é feito tem um **número variável de saltos**. "Quem
comprou o que a Ana comprou também comprou..." está a dois saltos da Ana: até os produtos dela, depois
até os outros clientes desses produtos, depois até o que eles compraram. "Quem está a até três
apresentações da Ana" são três. "Existe alguma cadeia de cartões e endereços em comum entre estas duas
contas" não tem tamanho fixo nenhum, e é a pergunta que as equipes de fraude fazem.

Num banco relacional cada salto é um join, e um número variável de saltos é uma consulta recursiva.
Isso funciona, e até dois ou três saltos sobre tabelas indexadas muitas vezes é rápido o bastante. O
custo é que cada salto é uma busca num índice de uma tabela inteira, então uma travessia profunda faz
trabalho proporcional às tabelas por onde passa. **Um armazenamento de grafo guarda as ligações de
cada nó ao lado do nó**, então seguir uma ligação é um ponteiro e não uma busca, e uma travessia custa
em proporção ao que ela toca. O pedido da figura da primeira seção vira nós, Ana, o pedido 1001, o cabo
e o mouse, e arestas entre eles que carregam dados próprios, como a quantidade.

O Neo4j é o produto mais conhecido, consultado numa linguagem chamada Cypher. O que observar, se um
problema parecer pedir um: **a pergunta é sobre caminhos, não sobre totais.** Somar todos os pedidos
de setembro é uma varredura em qualquer armazenamento, e um de grafo não é o rápido nisso.

## Série temporal: perguntas sobre medições ao longo do tempo

Uma série temporal é uma sequência de medições, cada uma com um horário: o tempo de resposta do
checkout da loja, medido a cada dez segundos, são 8.640 pontos por dia para um servidor. Os dados têm
uma forma que um banco de uso geral não pressupõe:

| | numa série temporal | nos pedidos da loja |
|---|---|---|
| escritas | acrescentadas, quase sempre no horário atual | inseridas, depois atualizadas conforme o pedido anda |
| um ponto depois de gravado | quase nunca muda | muda a cada atualização de status |
| leituras | um intervalo de tempo, agregado: a média por minuto da terça passada | um pedido, ou os pedidos de um cliente |
| dados antigos | **reduzidos** em resolução, depois apagados por uma política de **retenção** | guardados por anos, para a contabilidade |

A última linha é a que decide. Um ano de pontos a cada dez segundos é inútil como pontos e útil como
médias de um minuto, então um armazenamento de série temporal agrega os dados antigos em intervalos
mais grossos e apaga o resto numa agenda. Um banco de uso geral pode ser obrigado a fazer isso, com um
job que alguém precisa escrever e manter rodando.

Três produtos mostram a variedade. **O TimescaleDB é uma extensão do Postgres**: tabelas continuam
tabelas e SQL continua SQL, e o armazenamento particionado por tempo, as agregações e a retenção são
acrescentados por baixo. O InfluxDB é um banco feito só para isso. O Prometheus coleta métricas
pedindo-as a cada serviço num intervalo e as guarda por uma retenção definida, o que o torna tanto
software de monitoramento quanto banco de dados. A aula 20 lê as métricas que os três bancos deste
curso expõem, seja lá o que as colete.

## Escolhendo pela pergunta

| família | a pergunta para a qual é feita | o sinal de que você precisa dela |
|---|---|---|
| documento | "me dê esta coisa inteira" | a aplicação lê e grava um agregado por vez |
| chave-valor | "me dê o valor sob este nome" | todo acesso começa por uma chave conhecida |
| coluna larga | "me dê as linhas desta partição, em ordem" | volume enorme de escrita, e leituras que dá para listar de antemão |
| grafo | "o que está ligado a isto, e por onde" | as consultas difíceis são caminhos de tamanho desconhecido |
| série temporal | "o que aconteceu neste intervalo" | medições com horário, dados antigos valendo menos a cada dia |

A aula 22 volta a esta tabela com a pergunta que todas essas linhas pulam: se o banco relacional que
você já roda responde bem o bastante.
