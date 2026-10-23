---
title: O que medir, e o que cada número esconde
version: 1
---

O primeiro número que qualquer um reporta sobre um programa de segurança é a contagem de achados:
"os scanners acharam 509 problemas este ano". É o número mais fácil de produzir e o mais difícil de
ler. **Uma contagem de achados mede quantos scanners estão apontados para quanto código, e o quanto
eles são ruidosos.** Ela sobe quando um time acrescenta um scanner, o que é boa notícia, e cai quando
um time para de rodar um, o que é a pior notícia que existe. Um número que se move no mesmo sentido
por motivos opostos não consegue dizer a ninguém como as coisas vão.

O pipeline que você montou ao longo de dezenove aulas produz achados. Esta aula trata do que fazer
com eles quando são centenas, espalhados por times, ao longo de um ano: quais números respondem a uma
pergunta de verdade, e como cada um pode mentir.

### Quatro perguntas, e o número de cada uma

Toda métrica de segurança útil responde a uma de quatro perguntas. Escreva a pergunta antes do
número, porque é a pergunta que diz se o número é o certo.

| pergunta | o número | o que ele esconde |
|---|---|---|
| Com que rapidez corrigimos o que achamos? | tempo até remediar, por severidade: a mediana e o percentil 90 | os achados ainda abertos, que ainda não têm tempo até remediar |
| Cumprimos o que prometemos? | a fração corrigida dentro do SLA, por severidade, e os achados abertos que já passaram dele | se o próprio SLA faz sentido |
| O que está esperando? | dívida de segurança: os achados abertos, por severidade e por idade | os alvos que ninguém varre, que não têm achados esperando |
| Onde estamos cegos? | cobertura de varredura: os alvos em que cada scanner roda, dentre os alvos que existem | se alguém lê o que o scanner reporta |

Leia a coluna da direita como parte da definição. Cada número é cego numa direção específica, e o
número seguinte da tabela costuma ser o que olha para lá. O tempo até remediar não vê achados
abertos; a dívida vê. A dívida não vê um repositório sem varredura; a cobertura vê. **Por isso um
número sozinho nunca é o relatório**: qualquer um deles pode parecer bom se o problema for empurrado
para a coluna que ele não enxerga.

Uma quinta visão atravessa as outras quatro: a **tendência**. Achados abertos e fechados por mês ou
trimestre, e quantos estavam abertos no fim de cada um. Uma dívida de sessenta é outra situação se
no trimestre passado era noventa ou trinta.

### Decida o que é um achado antes de contar um

Dois scanners e dois dias podem descrever o mesmo problema como quatro achados ou como um. A aula 8
viu o scanner de imagens reportar um CVE uma vez para cada pacote que o carrega, quatro linhas para
uma correção. A aula 11 rodou duas ferramentas sobre a mesma imagem e elas contaram diferente. Antes
de um número sair do time, acerte três coisas:

- **A unidade.** Um achado é um problema, num alvo, que uma mudança corrige. Duplicatas entre pacotes
  da mesma origem, ou entre duas ferramentas, são juntadas antes da contagem.
- **A data de abertura.** O dia em que uma checagem o levantou pela primeira vez, que os logs do
  pipeline registram. Não o dia em que alguém fez a triagem, que esconderia o tempo em que ficou sem
  ser lido.
- **A data de fechamento, e a forma como fechou.** A aula 1 desenhou três saídas da triagem:
  corrigido e verificado pela mesma checagem passando, em exceção até uma data, ou falso positivo. Um
  registro que guarda só "fechado" jogou fora a diferença entre uma correção e a decisão de não
  corrigir, e a seção sobre a lei de Goodhart mostra quanto isso custa.

### De onde vêm os dados

Tudo o que está na tabela pode ser calculado a partir de duas listas. **Os achados**, uma linha por
achado, com o alvo, a ferramenta, a severidade, as duas datas e a resolução. E **o inventário**: cada
repositório e cada imagem que existe, com os scanners que rodam em cada um. Os achados saem do
pipeline, e a saída JSON de um scanner mais a data da execução bastam para montá-los. O inventário é
mais difícil, e é o que a maioria dos programas não tem, porque nada o produz sozinho: alguém precisa
listar o que existe, inclusive o que nunca passou por um pipeline.

O resto desta aula monta as duas listas para uma empresa inventada de quatro times, com um programa
curto o bastante para ser lido, e as mede com um segundo programa. Você pode rodar os dois e obter os
mesmos números citados aqui.

### Para quem são os números

Leitores diferentes precisam de recortes diferentes dos mesmos dados. O time precisa da lista de
abertos, ordenada por idade e SLA, porque é o trabalho dele. A liderança de engenharia precisa do
tempo até remediar e da dívida por time, para ver onde falta ajuda. Quem responde pelo risco ao
negócio precisa da cobertura e da dívida fora do SLA, porque esses dizem quanto é desconhecido e
quanto foi prometido e não feito. A última seção desta aula volta a isso, quando os números já
existirem.
