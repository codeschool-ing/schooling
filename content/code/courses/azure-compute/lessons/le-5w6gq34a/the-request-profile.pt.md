---
title: O perfil de requisições, lido antes da tabela de preços
version: 1
---

O jeito comum de escolher computação é pela reputação: Functions é barato, AKS é o que equipes
sérias usam, máquina virtual é coisa antiga. **Cada uma dessas frases é verdade para um formato de
tráfego e mentira para outro**, e os modelos de cobrança das lições anteriores já dizem por quê. Uma
máquina virtual, uma instância de plano do App Service e um nó do AKS são cobrados por toda hora em
que existem (lições 1, 18 e 11). Uma réplica do Container Apps é cobrada por segundo, a uma tarifa
reduzida enquanto está ociosa e a nada em zero (lição 8). Uma função no Flex Consumption é cobrada
pelos segundos em que executa e pelas próprias execuções (lição 16). Então a primeira coisa a saber
sobre uma carga não é a linguagem nem o framework. É quando as requisições chegam.

## Um perfil são 24 números

Anote o tráfego como requisições por segundo em cada hora de um dia comum. Isso é um *perfil de
requisições*, e basta para a conta desta lição. Cinco deles servem de exemplo, cada um um tipo
diferente de serviço:

- **steady**, 30 requisições por segundo o dia e a noite inteiros: uma API que outros sistemas
  chamam o tempo todo;
- **office**, 60 por segundo das 09:00 às 18:00 e nada fora disso: uma ferramenta interna;
- **nightly**, 14 por segundo durante duas horas a partir das 02:00, e silêncio no resto do dia: um
  serviço que recebe os arquivos de um parceiro uma vez por noite;
- **webhook**, 0,05 por segundo o dia todo, uma chamada a cada vinte segundos: o sistema de um
  parceiro avisando que algo mudou;
- **busy**, 400 por segundo o dia todo: o serviço steady, treze vezes maior.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Três perfis de requisições desenhados como barras ao longo de um dia de 24 horas, na mesma escala até 60 requisições por segundo. steady: 30 por segundo em todas as horas. office: 60 por segundo das 09:00 às 18:00 e nada fora desse horário. nightly: 14 por segundo das 02:00 às 04:00 e nada no resto do dia.\"><text x=\"20\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">steady</text><text x=\"20\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">30 por segundo, o dia todo</text><path d=\"M200 20 L200 90\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"194\" y=\"26\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">60</text><rect x=\"201.0\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"221.4\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"241.8\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"262.2\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"282.7\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"303.1\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"323.5\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"343.9\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"364.3\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"384.8\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"405.2\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"425.6\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"446.0\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"466.4\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"486.8\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"507.2\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"527.7\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"548.1\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"568.5\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"588.9\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"609.3\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"629.8\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"650.2\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"670.6\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><path d=\"M200 90 L690 90\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"20\" y=\"145\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">office</text><text x=\"20\" y=\"163\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">60 por segundo, das 09:00 às 18:00</text><path d=\"M200 115 L200 185\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"194\" y=\"121\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">60</text><rect x=\"384.8\" y=\"115.0\" width=\"18.4\" height=\"70.0\" fill=\"var(--phosphor)\"></rect><rect x=\"405.2\" y=\"115.0\" width=\"18.4\" height=\"70.0\" fill=\"var(--phosphor)\"></rect><rect x=\"425.6\" y=\"115.0\" width=\"18.4\" height=\"70.0\" fill=\"var(--phosphor)\"></rect><rect x=\"446.0\" y=\"115.0\" width=\"18.4\" height=\"70.0\" fill=\"var(--phosphor)\"></rect><rect x=\"466.4\" y=\"115.0\" width=\"18.4\" height=\"70.0\" fill=\"var(--phosphor)\"></rect><rect x=\"486.8\" y=\"115.0\" width=\"18.4\" height=\"70.0\" fill=\"var(--phosphor)\"></rect><rect x=\"507.2\" y=\"115.0\" width=\"18.4\" height=\"70.0\" fill=\"var(--phosphor)\"></rect><rect x=\"527.7\" y=\"115.0\" width=\"18.4\" height=\"70.0\" fill=\"var(--phosphor)\"></rect><rect x=\"548.1\" y=\"115.0\" width=\"18.4\" height=\"70.0\" fill=\"var(--phosphor)\"></rect><path d=\"M200 185 L690 185\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"20\" y=\"240\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">nightly</text><text x=\"20\" y=\"258\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">14 por segundo, das 02:00 às 04:00</text><path d=\"M200 210 L200 280\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"194\" y=\"216\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">60</text><rect x=\"241.8\" y=\"263.7\" width=\"18.4\" height=\"16.3\" fill=\"var(--phosphor)\"></rect><rect x=\"262.2\" y=\"263.7\" width=\"18.4\" height=\"16.3\" fill=\"var(--phosphor)\"></rect><path d=\"M200 280 L690 280\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"200.0\" y=\"300\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">00:00</text><text x=\"322.5\" y=\"300\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">06:00</text><text x=\"445.0\" y=\"300\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">12:00</text><text x=\"567.5\" y=\"300\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">18:00</text><text x=\"690.0\" y=\"300\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">24:00</text><text x=\"445.0\" y=\"320\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">requisições por segundo, hora a hora, na mesma escala</text></svg>", "caption": "Três serviços com três formatos. O volume, o pico e as horas ociosas lidos em cada um decidem linhas diferentes da conta."}
```

Os outros dois ficam fora do desenho. Nessa escala o webhook seria uma linha fina demais para ver e
o busy, um muro. Os dois estão na comparação da próxima seção, e cada um muda a resposta na sua
própria direção.

## Quatro números para ler num perfil

**O volume** é a soma do perfil ao longo de um mês. A 30 por segundo são 30 × 3.600 × 24 =
2.592.000 requisições por dia, e no mês médio de 730 horas, 30,42 dias, são 78,84 milhões. O perfil
office carrega 1.944.000 por dia, 59,13 milhões por mês; o nightly, 100.800 por dia, 3,07 milhões
por mês; o webhook, 4.320 por dia, 0,13 milhão por mês. A conta de uma função acompanha esse número,
e a cobrança por requisição do Container Apps também, depois que a assinatura gasta os seus dois
milhões grátis.

**O pico** é a hora mais movimentada. Máquinas, instâncias de plano, réplicas e nós têm de ser
dimensionados para ele, ou acrescentados a tempo dele (lição 4 para um scale set, lição 8 para
réplicas), e entre um pico e outro eles esperam por sua conta. O perfil office tem pico de 60
contra os 30 do steady, então no momento mais cheio precisa do dobro da capacidade, embora carregue
menos requisições no mês.

**As horas ociosas** são as que não têm nenhuma requisição: nenhuma no steady e no webhook, 15 por
dia no office, 22 no nightly. Uma hora ociosa é onde os modelos de cobrança se separam. Uma função
não paga nada por ela. Uma réplica do Container Apps mantida no mínimo paga a tarifa ociosa, e uma
revisão em zero não paga nada. Uma máquina virtual, uma instância de plano ou um nó pagam inteiro.

**A duração** é quanto tempo uma requisição leva, e ela faz três trabalhos. Multiplica os
GB-segundos de uma função. Decide quantas requisições estão em andamento ao mesmo tempo, que é a
taxa vezes a duração: a 60 por segundo e 100 ms cada, seis. Isso pesa mais no Functions do que
parece: **um app de funções em Python atende uma requisição HTTP por instância de cada vez, por
padrão.** É o que diz a documentação da Microsoft sobre concorrência HTTP no Flex Consumption, lida
em 30 de outubro de 2026. Seis requisições em andamento são seis instâncias. E a duração
decide quais serviços conseguem carregar a requisição, que é o assunto da seção 04: a requisição
mais longa, não a típica.

| perfil | requisições por dia | por mês | pico por segundo | horas ociosas por dia |
| --- | --- | --- | --- | --- |
| steady | 2.592.000 | 78,84 M | 30 | 0 |
| office | 1.944.000 | 59,13 M | 60 | 15 |
| nightly | 100.800 | 3,07 M | 14 | 22 |
| webhook | 4.320 | 0,13 M | 0,05 | 0 |
| busy | 34.560.000 | 1.051,20 M | 400 | 0 |

O webhook é a linha estranha e merece um segundo olhar. Ele nunca dorme, então não tem hora ociosa,
e carrega quase nada. Uma instância mantida para ele trabalha uma fração de segundo a cada vinte
segundos e é paga por todos eles.

## De onde vem um perfil

**Um serviço que já existe já tem o seu**, nas contagens de requisições por hora: as métricas do
balanceador ou do Application Gateway na frente dele, ou do próprio Container App ou web app, que as
lições 8 a 13 de `azure-operations` ensinam a ler no Azure Monitor. Pegue uma semana, não um dia:
segunda não é domingo, e o fim do mês não é o meio. Pegue a semana mais cheia que encontrar, porque
o pico é o número que quebra as coisas.

Um serviço novo não tem histórico, e o perfil dele é uma estimativa. **Anote a estimativa mesmo
assim**, com a origem de cada número: "a loja vende cerca de 2.000 pedidos por dia, cada página
vista faz oito chamadas à API, a noite é três vezes a manhã". Uma estimativa no papel pode ser
conferida com o primeiro mês de tráfego real. Uma estimativa na cabeça de alguém vira "a gente
sempre soube que ia ser barato" quando a conta chega.

Dois erros se repetem. O primeiro é usar a **média** no lugar do perfil: 59,13 milhões de
requisições por mês dão uma média de 22,5 por segundo, que esconde o pico de 60 e as 15 horas em
silêncio, os dois números que decidem entre as opções. O segundo é esquecer o **fio de tráfego**:
um monitor externo que chama a cada minuto, ou um cliente que consulta a cada poucos segundos,
transforma uma hora ociosa numa hora ativa. Pelas regras de cobrança da Microsoft, uma réplica do
Container Apps só fica ociosa enquanto não atende nenhuma requisição, usa menos de 0,01 de um núcleo
e recebe menos de 1.000 bytes por segundo. Um fio de tráfego a mantém, então, na tarifa ativa. A
seção 05 mostra quanto isso custa à loja.
