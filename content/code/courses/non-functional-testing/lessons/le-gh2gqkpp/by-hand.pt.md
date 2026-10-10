---
title: Percentis à mão
version: 1
---

Um percentil fica mais fácil de confiar depois que você calcula um sozinho. Vinte números bastam,
e eles podem ser de verdade. Este script manda vinte requisições à bilheteria, uma depois da
outra, para que nada espere por nada: quatro consultas ao espetáculo 990, depois uma reserva,
quatro vezes seguidas. Ele imprime cada tempo de resposta em milissegundos inteiros, como o `curl`
mediu.

```sh
# boxoffice/twenty.sh
# Twenty requests, one after another: four looks at show 990, then a
# booking, four times over. Prints each response time in milliseconds.
for i in $(seq 1 20); do
  if [ $((i % 5)) -eq 0 ]; then
    curl -s -o /dev/null -w '%{time_total}\n' -X POST localhost:8000/bookings \
      -d "{\"show_id\": 990, \"seat\": $i, \"customer\": \"ana\"}"
  else
    curl -s -o /dev/null -w '%{time_total}\n' localhost:8000/shows/990
  fi
done | awk '{ printf "%.0f\n", $1 * 1000 }'
```

Salve como `~/boxoffice/twenty.sh`, deixe o servidor rodando no outro terminal e rode o script
para dentro de um arquivo; depois imprima o arquivo numa linha, e depois ordenado:

```
ana@nft:~/boxoffice$ bash twenty.sh > times.txt
ana@nft:~/boxoffice$ paste -sd' ' times.txt
19 32 18 18 63 19 18 18 18 65 18 19 24 20 62 37 21 32 32 64
ana@nft:~/boxoffice$ sort -n times.txt | paste -sd' '
18 18 18 18 18 18 19 19 19 20 21 24 32 32 32 37 62 63 64 65
```

A segunda linha é a ordem em que as requisições saíram. As quatro reservas, a quinta, a décima, a
décima quinta e a vigésima requisições, levaram 63, 65, 62 e 64 ms: os 40 ms do pagamento em cima
da consulta. As dezesseis leituras levaram entre 18 e 37 ms. A terceira linha são os mesmos vinte
números ordenados, e **todo percentil é lido numa lista ordenada**.

## O método da posição mais próxima

Existem várias formas de definir um percentil, e elas discordam um pouco em amostras pequenas.
Esta aula usa a mais simples, que também é a que o `measure.py` calcula:

> Ordene os n valores. O percentil p é o valor na posição p/100 × n, contando a partir de 1, com a
> posição arredondada **para cima** até um número inteiro.

Com n = 20:

| percentil | p/100 × 20 | posição | valor |
|---|---|---|---|
| p50, a mediana | 10 | 10 | 20 ms |
| p75 | 15 | 15 | 32 ms |
| p90 | 18 | 18 | 63 ms |
| p95 | 19 | 19 | 64 ms |
| p99 | 19.8 | 20 | 65 ms |

**O método sempre devolve um dos valores que você mediu**, o que facilita conferir à mão: conte
na lista ordenada até a posição 18 e você encontra 63. A mediana diz que metade das requisições
levou 20 ms ou menos; o p90 diz que duas das vinte levaram mais de 63 ms, e são as duas reservas
mais lentas.

A média das vinte é a soma delas, 617, dividida por 20: 30.85 ms. Nenhuma requisição levou isso.
Ela é uma vez e meia a mediana, porque quatro reservas lentas em vinte a puxam para cima, e se
você a citasse como "o tempo de resposta" não estaria descrevendo nem as leituras nem as reservas.

## Outras ferramentas interpolam

O k6, e a função `PERCENTIL` de uma planilha, usam outra definição: eles põem o percentil na
posição p/100 × (n − 1), contando a partir de 0, e quando ela cai entre dois valores traçam uma
reta entre eles. Para os vinte valores acima, o p90 cai em 0.9 × 19 = 17.1, um décimo do caminho
entre o décimo oitavo valor (63) e o décimo nono (64), então o k6 diria 63.1 ms onde a posição
mais próxima diz 63. A mediana dele para esses vinte é 20.5 ms, no meio entre o décimo e o décimo
primeiro valores.

Numa amostra de centenas os dois métodos concordam bem dentro do ruído entre execuções. **Em
vinte valores eles podem diferir, e nenhum está errado**: um relatório deve dizer qual usou, e
dois números calculados por métodos diferentes não devem ser comparados como se uma diferença
entre eles quisesse dizer alguma coisa.

## Quantas requisições um percentil precisa

Olhe de novo a linha do p99. A posição 19.8 arredonda para 20, o último valor: **com vinte
requisições, o p99 é o máximo**, e todo percentil acima de 95 também. Um percentil só quer dizer
alguma coisa quando há valores acima dele. Para o p99 ter dez requisições além dele, a execução
precisa de mil; para o p99.9, de dez mil. Um requisito no percentil 99 é, portanto, também um
requisito sobre a duração do teste: uma execução de algumas centenas de requisições não consegue
reprová-lo nem aprová-lo honestamente.
