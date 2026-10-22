---
title: Log4j2, TinyLog e a lição do Log4Shell
version: 1
---

O Logback é o padrão do Spring Boot, não a única escolha, e quem desenvolve em Java encontra os outros
dois backends do título desta aula em projetos reais. O `~/logging-look` tem um perfil para cada um, e
o `Hello.java` é o mesmo arquivo da primeira seção.

## Log4j2

O **Log4j2** é o backend do projeto Apache Logging, uma reescrita do Log4j original, cuja linha 1.x
chegou ao fim da vida em 2015. A fama dele é a vazão: **loggers assíncronos** que entregam a linha a
uma thread em segundo plano para quem chama não esperar o disco, e um modo sem lixo que evita criar
objetos por linha. Ele também tem uma API própria, `log4j-api`, e é por isso que a livraria carrega o
`log4j-to-slf4j`: uma biblioteca escrita contra essa API ainda acaba no Logback.

@@FENCE 0@@

**Uma linha de quatro.** Sem arquivo de configuração, o Log4j2 escreve `ERROR` e nada abaixo, com a
hora em UTC. O Logback sem arquivo escreveu tudo de `DEBUG` para cima. Nenhum dos dois padrões é feito
para produção, e a diferença lembra que um backend sem configuração é a opinião do backend, não a sua.
Numa aplicação Spring Boot a troca é uma mudança de dependência: excluir o
`spring-boot-starter-logging` e acrescentar o `spring-boot-starter-log4j2`. O Boot então configura o
Log4j2 com o mesmo padrão e lê as mesmas propriedades `logging.level.*`, então as linhas da livraria
ficariam como estão. Este curso não faz essa troca.

## TinyLog

O **TinyLog** é um backend pequeno de uma equipe pequena, e o tamanho é o ponto. Ele tem uma API
estática própria, `org.tinylog.Logger.info(...)`, sem campo de logger para declarar, e um provider
para o SLF4J, que é o que o perfil acrescenta:

@@FENCE 1@@

Todo nível, duas linhas por evento, e o método que registrou, `Hello.main()`, que nenhum dos outros
imprime por padrão. O tamanho fica mais fácil de ver no disco, cada total incluindo o `slf4j-api`:

@@FENCE 2@@

É por isso que o TinyLog aparece em ferramentas de linha de comando pequenas, em apps Android e onde
quer que o tamanho de um jar conte. Ele não é um backend que o Spring Boot configura: o suporte de
logging do Boot cobre Logback, Log4j2 e `java.util.logging`. Uma aplicação Boot no TinyLog exclui o
starter de logging e perde o que esta aula usou do Boot, as propriedades `logging.level.*`, o padrão
de correlação e os formatos estruturados, e configura tudo no `tinylog.properties` do próprio TinyLog.

| | sem configuração | os jars acima | no Spring Boot |
|---|---|---|---|
| Logback | todo nível a partir de `DEBUG`, uma linha cada | 984K | o padrão |
| Log4j2 | só `ERROR`, hora em UTC | 2.4M | `spring-boot-starter-log4j2` |
| TinyLog | todo nível, duas linhas cada | 288K | sem suporte |

Para um serviço Spring Boot o padrão sensato é o que já está lá. O Log4j2 justifica a troca quando
alguém mediu que o logging é o que deixa o serviço lento.

## Log4Shell, e o que a fachada não podia fazer

Em dezembro de 2021 uma vulnerabilidade no Log4j2, a CVE-2021-44228, logo chamada de **Log4Shell**,
recebeu nota 10 de 10 em gravidade, e boa parte do mundo Java passou as semanas seguintes nela. As
versões de 2.0-beta9 a 2.14.1 do `log4j-core` procuravam **lookups** dentro de toda mensagem,
expressões escritas `${...}` que ele trocava por um valor, e um tipo de lookup, o JNDI, podia buscar
uma classe Java num servidor da internet e executá-la. Então qualquer um que conseguisse pôr uma string
numa linha de log, por um cabeçalho, uma caixa de busca ou um nome de usuário, podia fazer o servidor
rodar o código dele. Registrar o `User-Agent` de uma requisição bastava.

A fachada não protegeu ninguém. Uma aplicação que registrava pelo
SLF4J com o Log4j2 atrás entregava a string do atacante, intacta, ao mesmo `log4j-core` que fazia a
lookup: **o código vulnerável estava no backend, e uma fachada repassa a mensagem ao backend**, que é o
trabalho dela. O que a fachada comprou foi a cura. Um projeto cujo código falava só SLF4J podia passar
para um Log4j2 corrigido, ou para o Logback, editando as dependências sem tocar em classe nenhuma.

As aplicações Spring Boot no starter padrão não ficaram expostas, e a árvore da primeira seção mostra
por quê: `log4j-api` e `log4j-to-slf4j` estão lá, e `log4j-core` não. Uma chamada à API do Log4j nessa
árvore vai para o Logback, que não tem lookups em mensagens. O comando mais comum daquela semana foi
uma árvore de dependências, rodada em todo projeto, atrás de um `log4j-core` chegando por alguma
biblioteca que ninguém lembrava de ter acrescentado.

A correção era atualizar, e levou várias versões: a 2.15.0 desligou as lookups por padrão, a 2.16.0
removeu de vez as lookups em mensagens, e a 2.17.0 e a 2.17.1 fecharam dois buracos menores achados
enquanto todo mundo olhava. A 2.25.5 que o `~/logging-look` usou está muito além de todas elas. A ideia
por baixo é a que o `RequestIdFilter` segue em escala menor: **texto que veio de fora é dado, e nada no
caminho até o log deveria tratá-lo como instrução.**
