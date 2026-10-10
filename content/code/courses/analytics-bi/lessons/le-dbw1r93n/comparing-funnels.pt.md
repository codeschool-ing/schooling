---
title: Comparar um funil ao longo do tempo
version: 1
---

Em janeiro de 2026 a Lantern mudou a página de checkout. Funcionou? A última etapa do funil é a que a
mudança toca — sessões que chegaram ao checkout e então pagaram —, e ela pode ser comparada antes e
depois, por aparelho:

```
lantern=# SELECT extract(year FROM started_at)::int AS year, device,
lantern-#        count(*) FILTER (WHERE steps >= 4) AS checkouts,
lantern-#        round(100.0 * count(*) FILTER (WHERE steps >= 5)
lantern(#              / count(*) FILTER (WHERE steps >= 4), 1) AS checkout_to_purchase
lantern-# FROM shop.web_sessions
lantern-# GROUP BY 1, 2 ORDER BY 1, 2;
 year | device  | checkouts | checkout_to_purchase 
------+---------+-----------+----------------------
 2025 | desktop |      1905 |                 77.1
 2025 | mobile  |       974 |                 62.6
 2026 | desktop |      1526 |                 80.0
 2026 | mobile  |      1451 |                 64.2
(4 rows)
```

Nos dois aparelhos a etapa de checkout melhorou: desktop de 77,1% para 80,0%, celular de 62,6% para 64,2%.
Se isso é a página nova ou acaso depende de em quantos checkouts cada taxa se apoia. O erro padrão de uma
taxa é a raiz quadrada de *p*(1 − *p*)/*n*, e para a diferença de duas taxas os dois quadrados se somam:
no desktop, cerca de 1,4 ponto, então a subida de 2,9 pontos são uns dois erros padrão — provavelmente
real, não certa. No celular, com 974 checkouts em 2025, ele é de 2,0 pontos, e a subida de 1,6 ponto fica
dentro dele. Duas subidas na mesma direção convencem mais que cada uma sozinha, mas o resumo honesto é *o
desktop provavelmente melhorou, o celular ainda não dá para dizer*.

Esse é o jeito certo de julgar uma mudança numa etapa: **comparar essa etapa, dentro de cada tipo de
sessão, antes e depois.** Isso isola a mudança de tudo o mais que se mexeu em 2026, e o tráfego da Lantern
em 2026 não é o de 2025: muito mais dele chega por redes sociais e pelo celular, o que a próxima aula mede.

Essa mudança importa assim que alguém compara a conversão do *site inteiro* entre os dois anos, porque a
mistura de sessões por trás do número de cada ano é diferente. O que acontece então é o assunto da próxima
aula, e é um dos jeitos mais confiáveis que existem de chegar à conclusão errada a partir de números
certos. Por ora, a regra: **quando a mistura do que você está contando muda, compare dentro das partes
antes de comparar o total.**
