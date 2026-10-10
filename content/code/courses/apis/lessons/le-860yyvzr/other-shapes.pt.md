---
title: As outras formas que a integração legada assume
version: 1
---

**O SOAP é o caso amigável.** Ele tem um contrato que um programa consegue ler, responde perguntas
quando elas são feitas e diz quando algo deu errado. Muito sistema antigo oferece menos, e uma
integração assume a forma que o outro lado consegue dar. Cinco delas são comuns o bastante para você
encontrar cada uma:

| forma | como funciona | o que você ganha | o que custa |
|---|---|---|---|
| **arquivo depositado** | o parceiro grava um arquivo, CSV ou colunas de largura fixa, num diretório que os dois alcançam, muitas vezes por SFTP, e você o recolhe | a coisa mais simples que um sistema muito antigo sabe fazer | horas de atraso, e toda questão de formato de arquivo: codificação, vírgula decimal, linha de cabeçalho ou não |
| **lote noturno** | um job exporta ou importa tudo uma vez por dia, num horário combinado | um momento por dia em que os dois sistemas concordam | dados com até um dia de atraso, e uma noite que falha faz dois dias de mudanças chegarem juntos |
| **consulta periódica** | você pergunta "algo novo desde este ponto?" a cada poucos minutos | mudanças em minutos, de um sistema que não consegue avisar você | a maioria das perguntas volta vazia, e o "desde este ponto" tem de ser um cursor que nunca pula uma mudança |
| **fila de mensagens** | o sistema publica uma mensagem para cada mudança numa fila, IBM MQ ou um broker JMS nas empresas mais antigas, e você as consome | mudanças na hora em que acontecem, e nenhum lado espera o outro | as mensagens chegam pelo menos uma vez, então a mesma mudança pode chegar duas, e o consumidor tem de estar pronto para isso |
| **banco de dados compartilhado** | você lê, ou pior, escreve, as tabelas do sistema antigo diretamente | o começo mais rápido de todos | tudo o que vem abaixo |

Cada linha tem a sua falha que parece sucesso. Um arquivo depositado lido enquanto o parceiro ainda o
escreve é um arquivo de 40 MB processado como 12 MB, com a última linha cortada ao meio, e nenhum
erro em lugar nenhum. A defesa usual é o parceiro gravar com um nome temporário e renomear o arquivo
quando estiver completo, porque renomear no mesmo disco é instantâneo. Uma consulta que pede as
linhas mais novas que o último timestamp que viu perde uma linha gravada naquele mesmo segundo,
depois que ela olhou. Um consumidor de fila que não é idempotente lança o mesmo pagamento duas vezes
na primeira vez que o broker reentrega.

## Por que o banco compartilhado é o pior

Ele parece o mais barato: nenhum serviço, nenhum arquivo, uma consulta. O que ele faz é
tornar **o schema interno do outro sistema o seu contrato, sem que os donos dele saibam que
assinaram um.** A próxima versão deles renomeia uma coluna, divide uma tabela ou muda o que uma letra
de status significa, e a sua integração quebra numa terça-feira sem ninguém do lado deles saber que
ela existia. Escrever é pior que ler: as suas linhas pulam todas as regras que a aplicação deles
impõe, e o banco acaba guardando estados que o próprio código deles nunca produz e não sabe tratar.

A mesma regra vale dentro de um código só. Um módulo que lê as tabelas de outro módulo fez o mesmo
contrato sem assinatura, e quebra do mesmo jeito.

**Seja qual for a forma, o adaptador da seção anterior continua valendo.** Um arquivo depositado
ganha um módulo que lê o arquivo e entrega à loja linhas nos termos dela; uma fila ganha um
consumidor que traduz cada mensagem. Só esse módulo sabe que a forma existe, então trocar um arquivo
noturno por um serviço SOAP, ou um serviço SOAP por uma API REST, muda um módulo e nada mais.
