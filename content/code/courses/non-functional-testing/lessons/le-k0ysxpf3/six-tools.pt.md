---
title: Seis ferramentas lado a lado
version: 1
---

As aulas 4 a 7 mediram uma bilheteria com seis geradores de carga. **Elas se sobrepõem mais do que
os sites delas sugerem**: todas mandam requisições HTTP, cronometram as respostas e informam
percentis. O que as separa é como um teste é escrito, qual modelo de carga sai fácil e como uma
execução diz *reprovou*.

| | o teste é | roda em | modelo de carga que escreve mais fácil | aprovado ou reprovado |
|---|---|---|---|---|
| JMeter (aula 4) | um plano em XML, montado numa janela | Java | fechado: threads em laço | asserções por resposta; um veredito sobre percentil vem por cima |
| k6 (aula 5) | JavaScript | um programa Go | os dois: `constant-vus` ou uma taxa de chegada | `thresholds`, código de saída 99 |
| Gatling (aula 6) | Java, Kotlin, Scala ou JavaScript | Java, pelo Maven | aberto: usuários por segundo, com uma forma fechada | `assertions`, o build reprova com código de saída 1 |
| Locust (aula 6) | Python | Python | fechado: usuários em laço com uma espera | escrito num hook que define o código de saída |
| Artillery | YAML, com JavaScript para lógica | Node.js | aberto: chegadas por segundo | `ensure`, código de saída 1 |
| Vegeta | uma linha por requisição, e opções | um programa Go | aberto, e nada mais | nada embutido; o relatório é lido, ou interpretado |

## Lendo a tabela

**Escolha por quem escreve e revisa o teste.** JavaScript, Java, Python e YAML têm cada um o seu
público num time, e um teste de carga que o time não consegue ler é um teste de carga que para de
ser mantido. A janela do JMeter ajuda quem não programa, ao preço de um arquivo que ninguém consegue
revisar.

**Escolha pelo modelo que o requisito nomeia.** Um requisito em requisições por segundo quer um
modelo aberto; as taxas de chegada do k6, o Gatling, o Artillery e o Vegeta escrevem isso direto. Um
requisito em pessoas com a página aberta quer um fechado; o Locust, o JMeter e os usuários em laço do
k6 escrevem esse.

**Escolha pelo que o pipeline precisa.** Três das seis, k6, Gatling e Artillery, transformam um limite num código de saída
sem código extra nenhum. O Locust precisa de algumas linhas, como a aula 6 mostrou. O Vegeta precisa
de um script em volta, por exemplo `vegeta report -type=json` lido pelo `jq`, e esse é um preço justo
pela única ferramenta aqui que ninguém convence a largar a sua taxa.

**E fique com duas, não com seis.** Um time com uma ferramenta baseada em código para as jornadas e o
Vegeta para a pergunta única "este endpoint aguenta esta taxa" cobre quase tudo o que esta parte do
curso pergunta. A aula 8 pega os números que essas ferramentas imprimem e pergunta em quais
acreditar.
