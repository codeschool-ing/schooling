---
title: Escolhendo entre eles
version: 1
---

**A pergunta que decide raramente é velocidade. É quem vai rodar a coisa às três da manhã, e o que
ela precisa ler e escrever.** Os três contam corretamente as vendas da Ponto Final por janela; você
já viu cada um fazer isso. O que muda é o que cada um pede do time que o mantém vivo.

| | Spark Structured Streaming | Flink | Kafka Streams |
|---|---|---|---|
| latência | um intervalo de batch: um segundo ou mais, na prática | milissegundos | milissegundos |
| estado | no diretório de checkpoint, em armazenamento compartilhado | num state backend, com snapshots em armazenamento compartilhado | em stores locais, com cópia em tópicos do Kafka |
| tempo do evento e watermarks | sim, um watermark por consulta | sim, o mais completo: por partição, ociosidade, saídas para dados atrasados | sim, por períodos de tolerância nas janelas |
| fontes e sinks | arquivos, tabelas, Kafka e muitos mais | Kafka, arquivos, bancos de dados e muitos mais | só Kafka |
| o que você implanta | um cluster Spark, ou uma sessão dentro do seu job | um cluster Flink | a sua própria aplicação, em quantas cópias precisar |
| linguagens | Python, SQL, Scala, Java | SQL, Java, Python | Java e outras linguagens da JVM |
| quem roda | quem já roda Spark para batch | um time que roda Flink como plataforma | o time dono da aplicação |

Leia a tabela pela última linha primeiro. **Um time que já roda Spark para os jobs noturnos paga
quase nada para acrescentar um stream**: o mesmo cluster, os mesmos DataFrames, as mesmas pessoas,
e o mesmo código pode rodar como batch com `availableNow`. Esse costuma ser o argumento decisivo, e
é um bom argumento sempre que um segundo de latência é aceitável.

**O Flink é o escolhido quando o stream é o produto**: quando os resultados são necessários em
milissegundos, quando o estado é grande, quando há muitas fontes e as regras de tempo do evento são
exigentes. Ele também é um cluster com o seu próprio jeito de ser operado, atualizado e recuperado,
e alguém precisa conhecê-lo bem.

**O Kafka Streams serve a um serviço que já lê do Kafka** e precisa de uma contagem, um join ou uma
deduplicação lá dentro. Nada novo a instalar nem a operar; a escala é a do próprio serviço. O preço
é que tudo o que entra e sai é tópico do Kafka, é Java, e os tópicos internos se multiplicam: duas
contagens na seção 03 já fizeram quatro.

## Para a Ponto Final

As necessidades da rede, desde a lição 1, são o estoque no site, alertas quando uma loja esgota um
livro, o warehouse carregado a partir dos mesmos eventos, e um time de duas ou três pessoas. Uma
leitura razoável:

- A **carga do warehouse** é um batch, e o Spark com `availableNow` sobre o mesmo tópico faz isso
  com código que o time consegue ler.
- O **estoque por livro** é estado por chave, atualizado por cada venda, dentro do serviço que
  responde ao site. Essa é a forma do Kafka Streams: uma tabela mantida pela aplicação, sem motor
  para rodar ao lado.
- **Nada aqui precisa do Flink ainda.** Ele conquista o seu lugar quando um atraso de um segundo
  custa dinheiro, ou quando o estado fica maior do que uma aplicação consegue segurar. Escolhê-lo no
  primeiro dia é operar um cluster para um problema que duas ferramentas já resolvem.

Isso é uma leitura, não uma regra; um time com experiência em Flink e nenhuma em Java pesaria
diferente. O que não muda é o método: começar por quem opera e pelo que a coisa toca, e olhar a
latência por último.
