---
title: Mesma entrada, mesma saída
version: 1
---

**Reprodutível** tem um sentido preciso: dadas as mesmas entradas e o mesmo código, o pipeline
produz as mesmas saídas. Não saídas parecidas, os mesmos bytes. Isso pode ser testado com as mesmas
impressões digitais que protegem os arquivos brutos:

```
ana@lab:~/clean$ sha256sum out/*.csv > /tmp/first.sha256 && python run.py 2>/dev/null && sha256sum --check /tmp/first.sha256
out/changes.csv: OK
out/customers.csv: OK
out/orders.csv: OK
```

As impressões das três saídas são tiradas, o pipeline inteiro roda de novo a partir dos brutos, e
todo arquivo bate. Se algum não batesse, alguma coisa no pipeline dependeria de mais do que as suas
entradas e o seu código, e vale conhecer os suspeitos de sempre:

- **O relógio.** Uma coluna calculada a partir de "hoje", como uma idade ou um número de dias desde
  o último pedido, muda todo dia. A aula 12 contou dias a partir de uma data fixa, 1º de janeiro de
  2026, e é por isso que a saída dela não muda amanhã.
- **Aleatoriedade sem semente.** Uma amostra, um embaralhamento ou um modelo que sorteia números dá
  uma resposta diferente a cada execução, a menos que a semente seja fixada e anotada.
- **Uma ordem que ninguém pediu.** Uma tabela gravada na ordem em que um `groupby` ou um hash a
  devolveu pode mudar entre versões de uma biblioteca; ordene antes de gravar quando a ordem
  importar.
- **O ambiente.** O script do laboratório da aula 1 fixa cada biblioteca numa versão,
  `pandas==3.0.6` e as outras, porque uma versão nova pode mudar um padrão e, com ele, uma saída.

Um pipeline que passa nesse teste transforma uma discordância em algo tratável. Se duas pessoas
chegam a números diferentes, ou as entradas diferem, o que o manifesto dos brutos mostra, ou o
código difere, o que o controle de versão mostra. **Não há um terceiro lugar onde a diferença possa
se esconder.**
