---
title: O perfil de requisições, lido antes da tabela de preços
version: 1
---

O jeito comum de escolher a computação é pela fama: o Lambda é barato, contêineres são flexíveis,
instâncias são coisa antiga. **Cada uma dessas frases é verdade para um formato de tráfego e mentira
para outro**, e as tabelas de preços das aulas 1, 9, 14 e 22 já dizem por quê. Uma instância e um
contêiner são cobrados por cada hora em que existem. Uma função é cobrada por cada requisição que
atende. O App Runner fica entre os dois, cobrando memória enquanto espera e processador enquanto
trabalha. Então a primeira coisa a saber sobre uma carga de trabalho não é a linguagem nem o
framework. É quando as requisições chegam.

## Um perfil são 24 números

Escreva o tráfego como requisições por segundo para cada hora de um dia comum. Isso é um *perfil
de requisições*, e basta para a aritmética desta aula. Quatro deles servem de exemplo, cada um um
tipo diferente de serviço:

- **steady**, 30 requisições por segundo o dia e a noite inteiros: uma API que outros sistemas
  chamam a qualquer hora;
- **office**, 60 por segundo das 09:00 às 18:00 e nada fora disso: uma ferramenta interna;
- **nightly**, 14 por segundo durante duas horas a partir das 02:00, e silêncio no resto do dia: um
  job que recebe os arquivos de um parceiro uma vez por noite;
- **busy**, 400 por segundo o dia todo: o serviço steady, treze vezes maior.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Três perfis de requisição desenhados como barras ao longo de um dia de 24 horas, numa escala só, até 60 requisições por segundo. steady: 30 por segundo em todas as horas. office: 60 por segundo das 09:00 às 18:00 e nada fora desse horário. nightly: 14 por segundo das 02:00 às 04:00 e nada no resto do dia.\"><text x=\"20\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">steady</text><text x=\"20\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">30 por segundo, o dia todo</text><path d=\"M200 20 L200 90\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"194\" y=\"26\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">60</text><rect x=\"201.0\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"221.4\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"241.8\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"262.2\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"282.7\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"303.1\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"323.5\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"343.9\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"364.3\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"384.8\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"405.2\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"425.6\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"446.0\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"466.4\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"486.8\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"507.2\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"527.7\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"548.1\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"568.5\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"588.9\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"609.3\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"629.8\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"650.2\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"670.6\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><path d=\"M200 90 L690 90\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"20\" y=\"145\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">office</text><text x=\"20\" y=\"163\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">60 por segundo, das 09:00 às 18:00</text><path d=\"M200 115 L200 185\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"194\" y=\"121\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">60</text><rect x=\"384.8\" y=\"115.0\" width=\"18.4\" height=\"70.0\" fill=\"var(--phosphor)\"></rect><rect x=\"405.2\" y=\"115.0\" width=\"18.4\" height=\"70.0\" fill=\"var(--phosphor)\"></rect><rect x=\"425.6\" y=\"115.0\" width=\"18.4\" height=\"70.0\" fill=\"var(--phosphor)\"></rect><rect x=\"446.0\" y=\"115.0\" width=\"18.4\" height=\"70.0\" fill=\"var(--phosphor)\"></rect><rect x=\"466.4\" y=\"115.0\" width=\"18.4\" height=\"70.0\" fill=\"var(--phosphor)\"></rect><rect x=\"486.8\" y=\"115.0\" width=\"18.4\" height=\"70.0\" fill=\"var(--phosphor)\"></rect><rect x=\"507.2\" y=\"115.0\" width=\"18.4\" height=\"70.0\" fill=\"var(--phosphor)\"></rect><rect x=\"527.7\" y=\"115.0\" width=\"18.4\" height=\"70.0\" fill=\"var(--phosphor)\"></rect><rect x=\"548.1\" y=\"115.0\" width=\"18.4\" height=\"70.0\" fill=\"var(--phosphor)\"></rect><path d=\"M200 185 L690 185\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"20\" y=\"240\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">nightly</text><text x=\"20\" y=\"258\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">14 por segundo, das 02:00 às 04:00</text><path d=\"M200 210 L200 280\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"194\" y=\"216\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">60</text><rect x=\"241.8\" y=\"263.7\" width=\"18.4\" height=\"16.3\" fill=\"var(--phosphor)\"></rect><rect x=\"262.2\" y=\"263.7\" width=\"18.4\" height=\"16.3\" fill=\"var(--phosphor)\"></rect><path d=\"M200 280 L690 280\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"200.0\" y=\"300\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">00:00</text><text x=\"322.5\" y=\"300\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">06:00</text><text x=\"445.0\" y=\"300\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">12:00</text><text x=\"567.5\" y=\"300\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">18:00</text><text x=\"690.0\" y=\"300\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">24:00</text><text x=\"445.0\" y=\"320\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">requisições por segundo, hora a hora, numa escala só</text></svg>", "caption": "Três serviços com três formatos. O volume, o pico e as horas ociosas que se leem em cada um decidem colunas diferentes da conta."}
```

O quarto fica fora do desenho porque, na mesma escala, seria uma parede. Ele está na comparação da
próxima seção, e muda a resposta.

## Quatro números para ler num perfil

**O volume** é a soma do perfil ao longo de um mês. A 30 por segundo são 30 × 3.600 × 24 =
2.592.000 requisições por dia, e no mês médio de 730 horas, 30,42 dias, são 78,84 milhões. O perfil
office carrega 1.944.000 por dia, 59,13 milhões por mês; o nightly, 100.800 por dia, 3,07 milhões
por mês. A conta do Lambda é proporcional a esse número e a nada mais no perfil.

**O pico** é a hora mais movimentada. Instâncias e contêineres precisam ser dimensionados para ele,
ou escalar até ele a tempo (aula 5), e entre um pico e outro esperam por sua conta. O perfil office
tem pico de 60 contra 30 constantes do steady, então no momento mais cheio precisa do dobro da
capacidade, mesmo carregando menos requisições no mês.

**As horas ociosas** são as que não têm requisição nenhuma: nenhuma no steady, 15 por dia no office,
22 no nightly. Uma hora ociosa é onde os modelos se separam. O Lambda não paga nada por ela, o App
Runner paga memória, e uma instância ou uma task paga tudo, a menos que algo a pare.

**A duração** é quanto tempo uma requisição roda. Ela multiplica o segundo medidor do Lambda, o
GB-segundo. Também decide a concorrência, que a aula 16 definiu como taxa vezes duração: a 60
requisições por segundo e 100 ms cada, seis requisições estão em andamento ao mesmo tempo. E decide
quais serviços conseguem carregar a requisição, que é o assunto da seção 04.

| perfil | requisições por dia | por mês | pico por segundo | horas ociosas por dia |
| --- | --- | --- | --- | --- |
| steady | 2.592.000 | 78,84 M | 30 | 0 |
| office | 1.944.000 | 59,13 M | 60 | 15 |
| nightly | 100.800 | 3,07 M | 14 | 22 |
| busy | 34.560.000 | 1.051,20 M | 400 | 0 |

## De onde vem um perfil

**Um serviço que já existe já tem um**, nas contagens de requisições do load balancer ou nas
métricas da API, um gráfico do CloudWatch por hora que as aulas 8 a 10 de `aws-operations` ensinam a
ler. Pegue uma semana, não um dia: segunda-feira não é domingo, e o fim do mês não é o meio. Pegue a
semana mais movimentada que encontrar, porque o pico é o número que quebra as coisas.

Um serviço novo não tem histórico, e o perfil dele é uma estimativa. **Escreva a estimativa mesmo
assim**, com a origem de cada número: "a loja vende umas 2.000 encomendas por dia, cada página vista
faz oito chamadas à API, a noite tem o triplo da manhã". Uma estimativa no papel pode ser conferida
com o primeiro mês de tráfego real. Uma estimativa na cabeça de alguém vira "a gente sempre soube
que ia ser barato" quando a conta chega.

Dois erros se repetem. O primeiro é usar a **média** no lugar do perfil: 59,13 milhões de
requisições por mês dão uma média de 22,5 por segundo, que esconde tanto o pico de 60 quanto as 15
horas em silêncio, os dois números que decidem entre as opções. O segundo é esquecer o **fio de
tráfego**: um monitor externo que chama a cada minuto, ou um cliente que consulta a cada poucos
segundos, transforma uma hora ociosa numa hora movimentada para o App Runner, que precisa manter uma
instância ativa para responder. A seção 05 mostra quanto isso custa.
