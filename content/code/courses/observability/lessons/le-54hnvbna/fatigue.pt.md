---
title: Ruído, e a equipe que para de ler alertas
version: 2
---

**Fadiga de alertas** é o que acontece com uma equipe acionada com frequência por coisas que não pedem
ação. O mecanismo é humano e confiável: o terceiro page de uma noite que se revelou nada é lido mais
devagar que o primeiro, e em algum ponto depois disso um page real é dispensado junto com os outros.
Todo alerta barulhento gasta a atenção de que o importante vai precisar.

As fontes de ruído são poucas, e cada uma tem uma correção que este curso já construiu:

| ruído | correção |
|---|---|
| alertas sobre causas que muitas vezes se resolvem sozinhas | acionar pelo sintoma; causas viram tickets |
| um pico curto, a qualquer hora | duas janelas: a longa para o tamanho, a curta para o agora |
| uma falha, cem alertas | agrupamento no Alertmanager, e inibição de tickets por pages |
| alertas durante trabalho planejado | silêncios, com um motivo e um fim |
| um limite que ninguém lembra de ter escolhido | uma taxa de queima derivada do objetivo |

E um hábito que nenhuma ferramenta dá: **revisar todo page.** Uma vez por semana, quem esteve de plantão
lê a lista de pages com a equipe e pergunta de cada um: *era real, precisava de uma pessoa, e precisava
dela àquela hora?* Um page que falha no teste é mudado naquela semana: o limite movido, a severidade
rebaixada, ou o alerta apagado. Uma equipe que faz isso mantém os pages raros e verdadeiros; uma que
não faz acaba com um canal de alertas que ninguém lê.

Dois números tornam a revisão honesta. **Pages por turno de plantão** mostra a carga; o livro de SRE do
Google sugere no máximo dois incidentes por turno, para cada um receber a atenção que merece. **Pages
que pediam ação como fração de todos os pages** mostra o ruído; qualquer coisa bem abaixo da metade é um
pager treinando o dono a ignorá-lo. Os dois podem sair dos próprios registros do Alertmanager, e a aula
18 os põe na rotina do plantão.

Antes da próxima aula, tire as regras e o override desta aula:

```sh
rm prometheus/rules/burn.yml compose.override.yaml
curl -s -X POST localhost:9090/-/reload
docker compose up -d alertmanager
```
