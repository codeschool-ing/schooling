---
title: Rodar por conta própria, ou alugar
version: 1
---

**Um serviço gerenciado de Kafka vende o mesmo broker, operado por outra pessoa, e cobra por algo
que dá para medir.** O que ele mede é a parte importante, porque o mesmo pipeline pode sair barato
num modelo de preço e caro em outro. Esta seção não cita preços: eles mudam todo ano, variam por
região, e um número impresso num curso estaria errado antes de você ler. O que dura é a forma.

## Pelo que os serviços cobram

As ofertas diferem nos detalhes, e quase todas são montadas a partir de poucas unidades:

| unidade | o que a faz crescer | quem ela favorece |
|---|---|---|
| horas de broker ou de cluster | o tamanho e o número de máquinas, o dia todo | tráfego estável e previsível |
| vazão: dados de entrada e de saída | mensagens vezes bytes, vezes leitores na saída | clusters pequenos com pouco tráfego |
| horas de partição | toda partição que existe, ocupada ou ociosa | poucos tópicos grandes |
| armazenamento, por gigabyte-mês | retenção vezes cópias, às vezes cobrado uma vez por todas as cópias | retenção curta |
| rede | tráfego entre zonas e para fora do provedor | clientes numa zona só, consumidores próximos |

Uma oferta serverless cobra sobretudo por vazão e partições, sem máquinas para escolher; uma
provisionada cobra por hora de máquina e deixa você enchê-las. **A aritmética de retenção desta lição
é a entrada de todas elas.** Mensagens por dia e bytes por mensagem dão a vazão, os dias e as cópias
dão o armazenamento, e o número de grupos de consumidores multiplica o tráfego de saída.

## O que custa rodar por conta própria

As máquinas, os discos e a rede entre elas, que é a mesma aritmética. E a parte que não aparece numa
fatura:

- **Alguém de plantão**, porque um broker falha de noite tão fácil quanto de dia (a lista da lição 16
  é o que acorda essa pessoa).
- **Atualizações**, feitas um broker por vez sem parar o stream; só o Kafka 4 removeu o ZooKeeper e
  mudou o protocolo dos consumidores.
- **Capacidade**, acrescentada antes de ser necessária, e partições movidas para os brokers novos
  quando ela chega.

Uma equipe pequena rodando um cluster com tráfego estável muitas vezes acha o serviço gerenciado mais
barato depois de contar essas horas. Uma plataforma grande, com uma equipe que opera Kafka de
qualquer jeito, muitas vezes acha o contrário. Nenhum dos dois é regra, e a comparação tem de ser
feita com a sua própria vazão.

## Perguntas que mudam a resposta

- **Quantos leitores?** A vazão de saída é cobrada por byte lido, e todo grupo de consumidores lê o
  tópico inteiro. Cinco grupos num tópico são cinco vezes a saída.
- **Qual a retenção?** Um mês de retenção num serviço que cobra armazenamento por cópia é três vezes
  a linha de uma cópia da aritmética.
- **Onde rodam os consumidores?** Um consumidor em outra região ou outra nuvem paga para trazer cada
  byte até ele.
- **Quantas partições?** Um modelo que cobra por hora de partição transforma cem partições criadas
  "para depois" numa conta hoje; o conselho da lição 3 de escolher partições com cuidado tem preço.
