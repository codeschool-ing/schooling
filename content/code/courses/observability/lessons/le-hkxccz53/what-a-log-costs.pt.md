---
title: Quanto custa um log
version: 1
---

A loja rodou por dez minutos a cinco requisições por segundo com o Collector mandando ao Loki e ao
Elasticsearch, como na aula 9. O que os quatro serviços escreveram, medido na origem, e o que o
Elasticsearch guarda disso:

```
ana@obs:~/shop$ docker compose logs --no-log-prefix --since 10m storefront orders payments mailer | wc -c
2505605
ana@obs:~/shop$ curl -s 'localhost:9200/_cat/indices/logs-*?h=docs.count,store.size'
10649 2.7mb
```

**2,5 MB escritos, 2,7 MB guardados**, para 10649 linhas. O Elasticsearch guarda mais do que
recebeu: toda linha é guardada inteira, como o JSON original em `body.text`, de novo como campos
interpretados, e mais uma vez no índice que torna cada campo buscável. O Loki comprime os chunks e
não indexa quase nada, e costuma ser várias vezes menor que o texto bruto. Neste laboratório, porém,
os chunks dele ainda estavam em memória e não havia nada em disco para pesar.

A conta que decide um orçamento é curta. **2,5 MB em dez minutos são cerca de 360 MB por dia**,
brutos, para uma loja a cinco requisições por segundo. Multiplique isso pelo tráfego que uma loja
real tem, pelo número de cópias que um armazenamento mantém por segurança, muitas vezes duas ou
três, e pelos dias de guarda. Aí os três números que uma equipe controla ficam claros:

| | o que o move | onde este curso trata dele |
|---|---|---|
| bytes por requisição | quantas linhas, quantos campos, o tamanho da mensagem | aula 8 |
| como é guardado | indexar tudo, ou indexar labels e comprimir | aula 9 |
| por quanto tempo é guardado | retenção | a seção seguinte |

**Um produto de logs hospedado cobra pelo primeiro número**, geralmente por gigabyte ingerido, muitas
vezes com um segundo preço por gigabyte guardado por mês. Nenhum preço é citado aqui porque eles
mudam e variam por contrato, mas a forma é a mesma em todo lugar: o byte mais barato é o que nunca foi
escrito.
