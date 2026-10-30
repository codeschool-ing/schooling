---
title: O perfil de requisições, lido antes da tabela de preços
version: 1
---

O jeito comum de escolher computação é pela fama: o Cloud Run é barato, o Kubernetes é flexível,
máquina virtual é coisa antiga. **Cada uma dessas frases é verdade para um formato de tráfego e
mentira para outro**, e a tabela de preços da lição 1 já diz por quê. Uma máquina do Compute Engine
e um pod do Autopilot são cobrados por cada hora em que existem. O Cloud Run cobra de dois jeitos:
pela vida inteira de uma instância, ou só enquanto há uma requisição dentro dela. Então a primeira
coisa a saber sobre um serviço não é a linguagem nem o framework. É quando as requisições chegam.

## Um perfil são 24 números

Anote o tráfego como requisições por segundo em cada hora de um dia comum. Isso é um **perfil de
requisições**, e basta para a aritmética desta lição. Cinco servem de exemplo, cada um um tipo
diferente de serviço:

- **steady**, 30 requisições por segundo o dia todo: uma API que outros sistemas chamam dia e noite;
- **office**, 60 por segundo das 09:00 às 18:00 e nada fora disso: uma ferramenta interna;
- **nightly**, 14 por segundo durante duas horas a partir das 02:00, e silêncio no resto do dia: um
  serviço que recebe os arquivos de um parceiro uma vez por noite;
- **busy**, 400 por segundo o dia todo: o serviço steady, treze vezes maior;
- **sparse**, uma requisição por segundo o dia todo: um webhook, uma página de status, uma tela de
  administração.

## Quatro números para ler num perfil

**O volume** é a soma do perfil ao longo de um mês. A 30 por segundo são 30 × 3.600 × 24 =
2.592.000 requisições por dia, e no mês médio de 730 horas, 30,42 dias, são 78,84 milhões:

```
ana@laptop:~/gcp$ python3 -c "print(30 * 3600 * 24, 30 * 3600 * 24 * 730 / 24)"
2592000 78840000.0
```

A taxa por requisição do Cloud Run é proporcional a esse número e a nada mais do perfil.

**O pico** é a hora mais movimentada. Máquinas e pods precisam ser dimensionados para ele, ou
escalados até ele a tempo (lição 5), e entre os picos eles esperam por sua conta. O perfil office
tem pico de 60 contra 30 do steady, então no seu momento mais cheio precisa do dobro de capacidade,
embora carregue menos requisições no mês.

**As horas ociosas** são as que não têm requisição nenhuma: nenhuma no steady, 15 por dia no
office, 22 no nightly. Uma hora ociosa é onde os modelos se separam. O Cloud Run escala até zero e
não paga nada por ela; uma máquina ou um pod pagam inteira, a não ser que algo os pare.

**A duração** é quanto tempo uma requisição roda, e junto com a taxa ela decide quão ocupada fica
uma instância. A uma requisição por segundo e 100 ms cada, a instância tem uma requisição dentro
dela mais ou menos um décimo do tempo; a 30 por segundo ela quase nunca fica vazia. Essa fração é o
número em que os dois modos de cobrança do Cloud Run se dividem, como a próxima seção mostra. A
duração também decide quais serviços conseguem carregar a requisição, que é o assunto da seção 04.

| perfil | requisições por dia | por mês | pico por segundo | horas ociosas por dia |
| --- | --- | --- | --- | --- |
| steady | 2.592.000 | 78,84 M | 30 | 0 |
| office | 1.944.000 | 59,13 M | 60 | 15 |
| nightly | 100.800 | 3,07 M | 14 | 22 |
| busy | 34.560.000 | 1.051,20 M | 400 | 0 |
| sparse | 86.400 | 2,63 M | 1 | 0 |

## De onde vêm os números

Para um serviço que já roda, o perfil está nos logs ou nas métricas: requisições por hora, na média
de algumas semanas comuns, com os dias mais calmos e os mais cheios separados para olhar à parte. O
`gcp-operations` é o curso em que o Cloud Monitoring e o Cloud Logging dão esses números. Para um
serviço que ainda não existe, o perfil é uma estimativa, e deve ser anotado como estimativa, com o
raciocínio ao lado, porque é a hipótese sobre a qual todo outro número desta lição se apoia.
