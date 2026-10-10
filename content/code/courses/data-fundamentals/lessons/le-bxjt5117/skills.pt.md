---
title: Seis habilidades, e a que não é técnica
version: 1
---

**As habilidades que duram são poucas, e são mais antigas que qualquer ferramenta de um anúncio de
vaga.** Quem começa olha para a área, vê quarenta nomes de produtos e conclui que o primeiro emprego
exige todos. Ele exige as seis abaixo, em nível de trabalho, e o resto se aprende no emprego, uma
ferramenta de cada vez, porque cada uma delas é construída sobre estas.

| habilidade | para que serve neste trabalho | onde este catálogo a ensina |
|---|---|---|
| **SQL** | fazer uma pergunta a um banco de dados, e remodelar tabelas dentro dele | `sql-databases` |
| **Python** | tudo o que o SQL não alcança: chamar uma API, ler um arquivo, conferir uma entrega | `python`, que este curso supõe |
| **Linux e o shell** | onde os pipelines rodam, onde estão os logs deles, como os arquivos se movem | `linux-terminal` |
| **git** | um pipeline é código, e código precisa de histórico e de revisão | `git` |
| **a nuvem** | onde estão o armazenamento e os serviços gerenciados, e o que eles cobram | `cloud` |
| **modelagem** | dar forma às tabelas para que as perguntas sejam fáceis e os números batam | `warehouse-modeling` |

Repare no que falta. Não há nenhum warehouse em particular, nenhum agendador em particular, nenhum
processador de fluxos em particular. Cada um deles é um produto que faz um dos seis trabalhos acima
do seu jeito, e aprender um depois das seis é questão de semanas. Aprender um *no lugar* delas deixa
alguém que sabe pilotar uma ferramenta e não sabe dizer quando ela está dando uma resposta errada.

## A sétima habilidade: descobrir qual é a pergunta

**Os erros mais caros da engenharia de dados são respostas certas para a pergunta errada.** Eis a
forma de um. Marta pede a Ana "um mapa ao vivo das bicicletas por estação". Ao pé da letra, isso é um
fluxo de leituras das docas processado à medida que chega, que é a coisa mais cara da aula 8.

Ana pergunta o que Marta vai fazer com ele. A resposta: uma van leva bicicletas de uma estação para
outra duas vezes por dia, saindo às 09:30 e às 16:00, e o motorista precisa saber para onde levá-las.
Então o que Marta precisa é de um retrato de cada estação **pouco antes de cada saída da van**, e de
uma previsão de quais vão esvaziar antes da próxima. Isso é um job em lote duas vezes por dia, lendo
dados com no máximo uma ou duas horas. Ninguém precisa ser acordado à noite quando um fluxo para.

Três perguntas fazem a maior parte do trabalho, e nenhuma é técnica:

- **O que você vai fazer de diferente quando tiver a resposta?** Se nada, o pedido é curiosidade, e
  pode esperar.
- **Quando você precisa, e quão antigo o dado pode ser?** "Ao vivo" quer dizer coisas diferentes para
  pessoas diferentes, e a resposta honesta costuma ser uma hora do dia.
- **O que faria você desconfiar dela?** A resposta nomeia as verificações de que o pipeline precisa,
  antes do dia em que alguém desconfiar.

As perguntas mudam a arquitetura antes de qualquer ferramenta ser escolhida, e é por isso que vêm
primeiro nos critérios, duas seções adiante.
