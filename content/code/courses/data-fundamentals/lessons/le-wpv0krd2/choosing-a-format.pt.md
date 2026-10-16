---
title: Escolhendo um formato
version: 1
---

**Não existe o melhor formato, só um formato que serve a quem grava o dado, a quem o lê, e ao jeito
como lidam com ele: um registro por vez ou uma coluna por muitos.** A pergunta "qual formato é o
melhor?" tem a mesma resposta que "qual veículo é o melhor?", e ela não é uma resposta.

Ponha lado a lado o que esta aula mediu:

| | CSV | JSON Lines | Avro | Parquet | ORC |
|---|---|---|---|---|---|
| arranjo | linhas | linhas | linhas | colunas | colunas |
| tipos | nenhum | seis | ricos, com tipos lógicos | ricos | ricos |
| onde mora o esquema | em lugar nenhum, ou num documento | em lugar nenhum | no cabeçalho do arquivo | no rodapé do arquivo | no rodapé do arquivo |
| uma pessoa consegue ler | sim | sim | não | não | não |
| acrescentar um registro | barato | barato | barato | regravar um grupo de linhas | regravar uma faixa |
| ler uma coluna | ler tudo | ler tudo | ler tudo | ler aquela coluna | ler aquela coluna |
| dividir entre muitos trabalhadores | se não estiver em gzip | se não estiver em gzip | sim, nos marcadores | sim, nos grupos de linhas | sim, nas faixas |
| este mês de viagens, sem compressão | 2.858.966 bytes | 8.208.898 bytes | 1.552.466 bytes | 1.287.381 bytes | 1.061.077 bytes |

## Quatro perguntas, em ordem

1. **Quem mais precisa abrir o arquivo?** Um parceiro, uma planilha, um órgão regulador ou um
   sistema que alguém escreveu em 2003 decidem a questão: CSV, em UTF-8, com cabeçalho, e o
   delimitador e o formato de data escritos num documento. Ser legível em toda parte vale mais ali do
   que qualquer coisa do resto da lista.
2. **Ele é gravado um registro por vez?** Eventos de um aplicativo, leituras de um sensor de doca e
   mensagens entre serviços nascem com forma de linha. JSON Lines quando pessoas precisam lê-los e o
   volume é modesto; Avro quando programas os leem, o volume é grande, ou o esquema vai mudar por
   baixo de leitores que você não controla.
3. **Ele é lido por coluna, muitas linhas por vez?** É o caso de toda tabela guardada para análise, e
   a resposta é colunar, com um codec rápido. Parquet, a menos que a plataforma em volta seja
   construída sobre o Hive; nesse caso, ORC.
4. **O esquema vai mudar?** Vai. Prefira um formato que carregue o seu esquema, e uma regra para
   acrescentar um campo com valor padrão. Onde não der para evitar o CSV, leia pelo nome do
   cabeçalho, nunca pela posição.

## O que a Roda Livre faz

Na Roda Livre as respostas saem diferentes para cada fonte, o que é normal:

| dado | chega como | guardado como | por quê |
|---|---|---|---|
| a exportação diária de viagens do aplicativo | CSV | Parquet, depois de pousar | a ferramenta do time do aplicativo exporta CSV; as perguntas de Marta leem colunas |
| eventos dos sensores das docas | uma mensagem pequena por leitura | Avro no fluxo, Parquet uma vez por dia | gravados um a um; analisados por mês |
| a planilha dos mecânicos | CSV com ponto e vírgula | Parquet | escrita por pessoas, lida por programas |
| o relatório mensal para a prefeitura | feito aqui, a partir do Parquet | CSV, UTF-8 | lido pela planilha de outra pessoa |

O arquivo bruto é guardado exatamente como chegou, como a aula 3 faz com toda fonte, e a cópia
convertida é o que tudo adiante lê. Um formato é escolhido em cada etapa, para quem lê aquela etapa,
e converter entre eles são umas poucas linhas do tipo que esta aula vem escrevendo.
