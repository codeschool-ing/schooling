---
title: Um registro ruim, ou um lote ruim
version: 1
---

Pôr um registro em quarentena é a resposta certa quando o problema é o registro. Quando o problema é o
**lote** — uma exportação que deu errado na editora, um arquivo cortado no meio —, pôr os registros
ruins em quarentena e carregar o resto é a resposta errada, porque o que sobra não é uma versão menor
da verdade. É uma figura diferente e falsa: cem livros cujos preços não mudaram, carregados como se
fossem a lista completa da noite.

Para ver a diferença, a Ana monta um lote quebrado de propósito: duzentos registros, os cem primeiros
com os preços tirados.

```
ana@vm:~/etl$ sed 's/"list_price_cents": \("[0-9]*"\|[0-9][0-9]*\)/"list_price_cents": null/' landing/prices.jsonl | head -100 > /tmp/half_broken.jsonl; tail -100 landing/prices.jsonl >> /tmp/half_broken.jsonl
ana@vm:~/etl$ python validate_prices.py /tmp/half_broken.jsonl /tmp/out.jsonl /tmp/bad.jsonl; echo "exit status $?"; ls /tmp/out.jsonl
200 records: 99 accepted, 101 rejected
  fixed       12  currency in lower case
  fixed       20  isbn written with hyphens
  fixed        6  price sent as text
  fixed       10  publisher with stray spaces
  rejected   101  price missing
STOP: 50% rejected is more than 5%; nothing loaded
exit status 1
ls: cannot access '/tmp/out.jsonl': No such file or directory
```

Cento e um rejeitados — os cem que ela quebrou e um que já chegou sem preço —, cinquenta por cento, e o
validador parou: nada gravado para o carregador, status de saída 1. As correções continuaram contadas
e a quarentena continuou gravada, então o motivo está no disco; mas a carga que viria depois não roda,
porque o shell, o `make` ou o Airflow veem a falha.

O limite de 5% é um julgamento, como o timeout da lição 10. Ele deve ficar com folga acima do que uma
noite normal produz — quatro em mil aqui — e bem abaixo de qualquer coisa que só poderia ser um
acidente. **Uma regra sobre registros sem uma regra sobre o lote** deixa passar uma exportação
quebrada, um registro plausível por vez.
