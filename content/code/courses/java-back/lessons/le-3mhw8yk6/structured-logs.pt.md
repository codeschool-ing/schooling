---
title: Logs estruturados, e o que nunca vai neles
version: 1
---

As linhas até aqui foram escritas para uma pessoa num terminal, e uma pessoa as lê bem. O log de um
servidor, porém, é lido sobretudo por um programa: algo recolhe toda linha de toda cópia da aplicação,
guarda, e responde perguntas como "todo `ERROR` do `OrderService` hoje de manhã" ou "toda linha com o
id de requisição `checkout-42`". Para responder isso a partir de texto, ele precisa cortar cada linha
em campos com um padrão. O padrão quebra na primeira vez que uma mensagem traz o caractere em que ele
corta, ou ocupa várias linhas, como o relatório do Hibernate sobre o banco faz em toda partida.

Um **log estruturado** escreve cada evento como dado: um objeto JSON por linha, com o nível, o logger, a
thread e cada entrada do MDC como campos próprios. O Spring Boot faz isso com uma propriedade, então a
livraria mantém o formato legível por padrão e liga o JSON com um perfil. Crie
`src/main/resources/application-json.properties`:

@@FENCE 0@@

`ecs` é o **Elastic Common Schema**, os nomes de campo que a pilha da Elastic lê. Rode `mvn -q package`
de novo, e reinicie o segundo terminal com o perfil:

@@FENCE 1@@

O token da seção anterior ainda vale: ele dura quinze minutos, e a aplicação reiniciada o confere com
o mesmo segredo. (Se tiver expirado, pegue outro do mesmo jeito.)

@@FENCE 2@@

O mesmo evento, e nada mais precisa ser deduzido pela posição. O nome do logger e o da thread vêm
inteiros, sem corte. A hora está em UTC com o fuso escrito como `Z`, então linhas de máquinas em fusos
diferentes se ordenam juntas. E **`requestId` é um campo próprio**, porque o Boot copia toda entrada
do MDC para o objeto. Uma plataforma de logs agora pode filtrar por
`requestId` exatamente, em vez de buscar no texto uma string que também poderia aparecer numa
mensagem. E uma mensagem que ocupa várias linhas, como o relatório do Hibernate sobre o banco,
continua um objeto só: as quebras de linha dela são escritas como `\n` dentro da string, então nada
numa mensagem consegue começar uma linha própria. O formato de texto as imprime como quebras de
verdade.

Mais uma coisa que o JSON mostra e o texto não mostrava. As classes do próprio Spring registram pelo
`commons-logging`, e as linhas delas trazem uma tag dizendo isso:

@@FENCE 3@@

## Três formatos, um evento

O ECS é um de três formatos que o Boot escreve; `logstash` e `gelf` (o do Graylog) são os outros. Qual
é o certo é decidido por quem recolhe o log, não pela aplicação. Uma propriedade na linha de comando
vence o arquivo do perfil, então o mesmo evento com os nomes do Logstash está a um reinício de
distância:

@@FENCE 4@@

@@FENCE 5@@

`logger_name` em vez de `log.logger`, um `level_value` numérico ao lado do nível, a hora com a
diferença de São Paulo em vez de UTC, e o mesmo `requestId`. O código que escreveu a linha não mudou, e
o MDC também não.

## O que nunca vai num log

Um log é uma cópia do que a aplicação viu, e vai mais longe que o banco de dados. É mandado para outro
sistema, guardado por meses, lido por todo mundo que depura qualquer coisa, e anexado a chamados, e
apagar um cliente do banco não apaga nada dele no log. Então algumas coisas nunca entram, em nível
nenhum:

- **Senhas**, inclusive as erradas: um login que falhou com uma senha a um caractere da certa é a
  senha.
- **Credenciais de qualquer tipo**: o cabeçalho `Authorization`, um JWT, o segredo do JWT, um id de
  sessão, uma chave de API. Quem lê um token num log pode usá-lo até ele expirar.
- **Dados pessoais de que a linha não precisa**: um e-mail, um nome, um endereço, um número de
  documento. A linha de pedido da livraria escreve o subject do token, `ana`, que é um nome de conta e
  portanto identifica uma pessoa; uma loja com clientes de verdade escreveria um id de conta opaco e só
  buscaria a pessoa quando tivesse um motivo.

O logging de requisições do próprio Spring foi feito pensando na segunda regra. O perfil `dev` da aula
4 sobe `org.springframework.web` para `debug`; mande a ele uma requisição com um token que ele vai
recusar:

@@FENCE 6@@

@@FENCE 7@@

O token não aparece em lugar nenhum, e o Spring diz por que já na primeira requisição. A chave que
desliga o mascaramento, `spring.mvc.log-request-details`, existe para a máquina de quem desenvolve. O
mesmo vale para o logger `org.hibernate.orm.jdbc.bind` do Hibernate, que em `trace` escreve o valor de
cada parâmetro SQL: os dados de cada cliente, uma linha por vez.
