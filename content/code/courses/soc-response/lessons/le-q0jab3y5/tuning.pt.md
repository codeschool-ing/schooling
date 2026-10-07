---
title: Ajustar um limiar, com números
version: 1
---

A regra diz `gte: 10`. Por que dez? Um limiar é uma decisão com um custo de cada lado: mais baixo, e ele
aponta estranhos que tentaram dois nomes; mais alto, e um adivinhador cuidadoso que tenta nove fica por
baixo. **O jeito de escolher é contar**, contra um período que você conhece. Salve isto como `sweep.sh`:

```bash
#!/bin/bash
# sweep.sh: how many addresses would the rule flag at each threshold?
for n in 2 3 4 10; do
  sed "s/gte: 10/gte: $n/" spray.yml > try.yml
  ~/sigma/bin/sigma convert -t sqlite try.yml -o try.sql 2>/dev/null
  printf 'gte %-3s %s addresses\n' "$n" "$(bash grouped.sh try.sql | tail -n +3 | wc -l)"
done
```

```
ana@soc:~/week$ bash sweep.sh
gte 2   30 addresses
gte 3   14 addresses
gte 4   1 addresses
gte 10  1 addresses
```

| limiar | endereços apontados | o que são |
|---|---|---|
| 2 contas em uma hora | 30 | quase todos os estranhos da semana, cada um tentando dois ou três nomes |
| 3 | 14 | ainda o ruído de fundo da internet |
| 4 | 1 | o endereço de quinta |
| 10 | 1 | o mesmo |

Entre 3 e 4 a contagem cai de 14 para 1, e esse degrau é a informação. Nesta semana, **qualquer limiar de 4 a
19 pega a quinta e nada mais**, então 10 fica com folga dentro da faixa segura. Se o degrau estivesse em 9,
um limiar de 10 estaria a um adivinhador cuidadoso de deixá-la passar.

Repare no que o segundo quadro do painel mostrou: `203.0.113.174` tentou 6 contas na **semana**. A janela
da regra é de uma **hora**, e em qualquer hora esse endereço tentou no máximo três. **A janela faz parte do
limiar**: "6 numa semana" e "6 numa hora" são regras diferentes.

Duas outras ferramentas ao lado do limiar. Uma **lista de permissão** com dono e data de validade (um
scanner contratado pela empresa, até o fim do contrato) tira uma fonte conhecida sem cegar a regra. E a
**supressão depois da ação**: uma vez bloqueado um endereço, novos alertas sobre ele não acrescentam nada
até o bloqueio sair.
