---
title: A lei de Goodhart, e o que reportar a quem
version: 1
---

O economista Charles Goodhart observou em 1975 que uma regularidade estatística desmorona quando
passa a ser usada para controle. A antropóloga Marilyn Strathern depois a pôs na forma que todo mundo
cita: **quando uma medida vira meta, ela deixa de ser uma boa medida.** Métricas de segurança são um
caso limpo disso, porque todo número desta aula pode melhorar de duas maneiras, fazendo o trabalho ou
mudando o que é contado, e a segunda é sempre mais barata.

### Um time que parece o melhor

```
ana@vm:~/metrics$ python3 measure.py teams
team      closed fixed wont_fix median
links        129   108       4%     26
payments     135    71      41%      7
platform      95    80       6%     33
web           91    79       4%     22
```

Julgado pela mediana de dias até fechar um achado, `payments` é de longe o melhor time da empresa: 7
dias, contra 22 a 33 dos outros três. Julgado pela segunda coluna, fechou 135 achados, mais que
qualquer um.

A terceira coluna diz como. **41% dos achados que o `payments` fechou foram fechados como "não vou
corrigir"**, contra 4 a 6% dos outros. Dos 135 achados fechados, 71 foram corrigidos. O gerador
plantou isso, então aqui a causa é conhecida: a linha de `outcome()` que fecha quase metade dos
achados médios e baixos do time em até cinco dias. Em dados reais a causa teria de ser achada do
mesmo jeito, pondo um segundo número ao lado do primeiro.

Nada nesse padrão exige má-fé. Um time que ouve que a mediana dele é revisada todo mês, com um
acúmulo de achados médios em bibliotecas que ele não controla, vai descobrir que "não vou corrigir,
risco aceito" é uma resolução legítima, e vai usá-la. Cada decisão pode ser defendida. A soma é uma
mediana que diz que o time é rápido, sobre um trabalho que ele não fez.

### O mesmo relatório, contado do outro jeito

O tempo até remediar desta aula conta só `fixed`. Contar todo caminho para fora da lista é a mudança
que fica a uma palavra de distância, e o `ttr-any` a faz:

```
ana@vm:~/metrics$ python3 measure.py ttr-any
severity  closed  mean median  p90 in SLA
critical      25   7.8      4   11    72%
high         116  20.9     15   46    78%
medium       195  34.9     22   86    90%
low          114  54.6     43  126    96%
```

Ponha ao lado da tabela só de corrigidos, de antes nesta aula. A mediana de severidade média cai de
34,5 dias para 22, e a de baixa de 57 para 43; a fração dentro do SLA sobe nas duas. **Nada foi
corrigido mais rápido.** A única diferença é que 61 achados médios que saíram da lista sem correção
agora contam como remediações. Um relatório que não diz quais resoluções conta é um relatório que
qualquer um move trocando um filtro.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"sp-l20-goodhart\" aria-label=\"Cada time como um ponto: na horizontal, a fração dos achados fechados como não vou corrigir; na vertical, a mediana de dias até fechar um achado por qualquer caminho. links 4% e 26 dias, web 4% e 22, platform 6% e 33, payments 41% e 7. payments tem a melhor mediana e, de longe, a maior fração de não vou corrigir.\"><defs><marker id=\"sp-l20-goodhart-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><line x1=\"80\" y1=\"240.0\" x2=\"660\" y2=\"240.0\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></line><text x=\"72\" y=\"240.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><line x1=\"80\" y1=\"192.5\" x2=\"660\" y2=\"192.5\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></line><text x=\"72\" y=\"192.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10</text><line x1=\"80\" y1=\"145.0\" x2=\"660\" y2=\"145.0\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></line><text x=\"72\" y=\"145.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">20</text><line x1=\"80\" y1=\"97.5\" x2=\"660\" y2=\"97.5\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></line><text x=\"72\" y=\"97.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">30</text><line x1=\"80\" y1=\"50.0\" x2=\"660\" y2=\"50.0\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></line><text x=\"72\" y=\"50.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">40</text><text x=\"80.0\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0%</text><text x=\"196.0\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10%</text><text x=\"312.0\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">20%</text><text x=\"428.0\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">30%</text><text x=\"544.0\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">40%</text><text x=\"660.0\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">50%</text><text x=\"370.0\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">fechados como “não vou corrigir”, fração dos achados fechados do time</text><text x=\"20\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">mediana de dias até fechar</text><circle cx=\"126.4\" cy=\"116.5\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"134.4\" y=\"106.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">links 4% · 26</text><circle cx=\"555.5999999999999\" cy=\"206.75\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"545.5999999999999\" y=\"192.75\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">payments 41% · 7</text><circle cx=\"149.6\" cy=\"83.25\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"157.6\" y=\"79.25\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">platform 6% · 33</text><circle cx=\"126.4\" cy=\"135.5\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"134.4\" y=\"147.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">web 4% · 22</text><path d=\"M650 120 L650 200\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l20-goodhart-ah-paper-dim)\"></path><text x=\"642\" y=\"160\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">uma mediana melhor</text></svg>", "caption": "O time com a melhor mediana é o que menos corrige do que fecha. Cada número sozinho o poria em primeiro ou em último; o par diz por quê."}
```

### Como um número de segurança é manipulado

Cada uma destas melhora um número sem reduzir o risco, e cada uma é uma decisão que dá para defender
um achado de cada vez:

- **Fechar como "não vou corrigir" ou "aceito"**, como acima. Move o tempo até remediar e a dívida
  ao mesmo tempo.
- **Dividir achados.** Um problema reportado como vários achados, cada um fechado rápido, melhora a
  contagem de fechados e a mediana. Juntar duplicatas antes de contar (a unidade, na primeira seção
  desta aula) é a defesa.
- **Baixar a severidade.** Um achado alto reclassificado como médio ganha 90 dias em vez de 30, e o
  SLA é cumprido sem mudar o código.
- **Varrer menos.** Desligar um scanner ruidoso, ou deixar um alvo fora do inventário, baixa toda
  contagem de achados e de dívida. Só a cobertura percebe.
- **Fechar e reabrir.** Onde a ferramenta de acompanhamento data um achado pela abertura mais
  recente, um achado fechado na véspera do relatório e levantado de novo no dia seguinte começa com
  idade zero, e a faixa `181+` se esvazia.

### Defesas que funcionam

**Reporte números em pares que puxam um contra o outro.** A mediana do tempo até remediar com a
fração de "não vou corrigir"; a dívida com a cobertura; os achados fechados com os reabertos.
Manipular um número do par move o outro, e isso fica visível na mesma página.

**Faça de uma não correção uma decisão com nome.** As exceções da aula 7 têm dono, motivo e data de
validade. Um "não vou corrigir" registrado do mesmo jeito não é um atalho em volta da métrica: é um
risco que alguém aceitou e precisa revisitar, e ele fica na dívida até a data passar.

**Não transforme uma medida em meta pessoal.** Os números de um time são para o time ver onde está o
trabalho dele. Ranquear times pela mediana, ou amarrar um bônus a ela, é exatamente o arranjo em que
os números deixam de significar qualquer coisa.

### O que reportar a quem

| leitor | do que precisa | os números |
|---|---|---|
| o time | no que trabalhar em seguida | a lista de abertos, ordenada por SLA e idade; o próprio tempo até remediar |
| a liderança de engenharia | onde falta ajuda | tempo até remediar e dívida por time, com a fração de "não vou corrigir" ao lado de cada um |
| quem responde pelo risco | o que é desconhecido, e o que foi prometido e não feito | cobertura por scanner, dívida fora do SLA por severidade, a tendência |

A terceira linha é a que mais se reporta errado, como uma contagem única de achados encontrados no
trimestre. Essa contagem diz o quanto os scanners estiveram ocupados. A cobertura e a dívida fora do
SLA dizem quanto é desconhecido e quanto está atrasado, que são as duas coisas sobre as quais alguém
responsável pelo risco pode agir.
