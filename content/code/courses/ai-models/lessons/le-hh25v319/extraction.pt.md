---
title: Uma segunda tarefa, outro vencedor
version: 1
---

A aula 4 seção 04 disse que um modelo pode passar numa tarefa e falhar em outra, e é por isso que
cada tarefa é avaliada sozinha. A tarefa de extração, nos mesmos quarenta e-mails, com o
`prompts/extract.txt`:

```
ana@desk:~/desk$ python evalkit.py run extract runs/extract.jsonl 0 llama3.2:3b qwen2.5:3b llama3.2:1b
```

```
ana@desk:~/desk$ python evalkit.py report runs/extract.jsonl
model         strict   loose     loose, 95%  p50 s  out tok
llama3.2:3b    36/40   36/40     77% to  96%   1.49      9.4
qwen2.5:3b     25/40   25/40     47% to  76%   1.19      8.1
llama3.2:1b     8/40   12/40     18% to  45%   0.79     11.7
```

**A ordem se inverteu.** O llama3.2:3b, segundo na classificação, acha o número do pedido 36 vezes
em 40, e toda resposta que ele escreveu era JSON válido. O qwen2.5:3b, o melhor classificador,
acerta
25. O llama3.2:1b escreve JSON válido com o número certo 8 vezes, e 12 se o programa pescar o número
do texto em volta. As falhas dizem por quê:

```
ana@desk:~/desk$ python evalkit.py errors runs/extract.jsonl | grep -v "^llama3.2:1b"
llama3.2:3b  c07 wrong     expected LB-20399        got '{"order": "null"}'
llama3.2:3b  c09 wrong     expected None            got '{"order": "SMH-IL-12345"}'
llama3.2:3b  c24 wrong     expected None            got '{"order": "LB-12345"}'
llama3.2:3b  c32 wrong     expected LB-20478        got '{"order": "LB-20478-1204"}'
qwen2.5:3b   c01 wrong     expected LB-20417        got '{"order": null}'
qwen2.5:3b   c03 wrong     expected LB-20452        got '{"order": null}'
qwen2.5:3b   c07 wrong     expected LB-20399        got '{"order": null}'
qwen2.5:3b   c11 wrong     expected LB-20329        got '{"order": null}'
qwen2.5:3b   c13 wrong     expected LB-20470        got '{"order": null}'
qwen2.5:3b   c17 wrong     expected LB-20301        got '{"order": null}'
qwen2.5:3b   c18 wrong     expected LB-20493        got '{"order": null}'
qwen2.5:3b   c21 wrong     expected LB-20440        got '{"order": null}'
qwen2.5:3b   c22 wrong     expected LB-20481        got '{"order": null}'
qwen2.5:3b   c26 wrong     expected LB-20431        got '{"order": null}'
qwen2.5:3b   c27 wrong     expected LB-20497        got '{"order": null}'
qwen2.5:3b   c30 wrong     expected LB-20412        got '{"order": null}'
qwen2.5:3b   c31 wrong     expected LB-20366        got '{"order": null}'
qwen2.5:3b   c32 wrong     expected LB-20478        got '{"order": "LB-20478-1204"}'
qwen2.5:3b   c40 wrong     expected LB-20474        got '{"order": null}'
```

**O qwen2.5:3b diz que não há pedido quando há**, catorze vezes: `null` para um e-mail que cita
`LB-20417` entre parênteses, `LB-20452` no meio de uma frase, `LB-20474` à vista. É um modelo
cauteloso na direção errada. Cada uma dessas respostas é JSON válido e é lida sem erro, e um
programa que confia nelas diz a catorze clientes que não acha o pedido deles.

**O llama3.2:3b inventa.** O c24 e o c09 não citam pedido nenhum, e a resposta certa é `null`. Para
o c24 ele respondeu `LB-12345`, que é o exemplo do `prompts/extract.txt`: o formato que o prompt
deu, copiado como conteúdo. Para o c09, uma pergunta sobre a edição ilustrada de *Small Hours*, ele
inventou `SMH-IL-12345`. **Casos cuja resposta certa é "não há" são onde a invenção aparece**, e a
seção 03 guardou quinze deles por isso. `SMH-IL-12345` não é número de pedido que a loja poderia
ter, e uma consulta falha nele. `LB-12345` está no formato da própria loja, então um programa que o
consulta vê um número de pedido, e no dia em que a loja chegar ao pedido 12345 vai achar o de outra
pessoa.

**Os dois transformaram `LB-20478` em `LB-20478-1204`** no c32, que pede para acrescentar o
apartamento 1204 a esse pedido: o modelo juntou dois números da mesma frase. E o `"null"` do
llama3.2:3b para o c07, entre aspas, é uma string onde o JSON tem um valor para nada, num e-mail que
cita o pedido.

As respostas do 1b são outro tipo de erro:

```
ana@desk:~/desk$ python evalkit.py errors runs/extract.jsonl | grep "^llama3.2:1b" | head -6
llama3.2:1b  c01 wrong     expected LB-20417        got '{"status": "preparing"}'
llama3.2:1b  c02 wrong     expected LB-20388        got '{"order": "null"}'
llama3.2:1b  c03 loose ok  expected LB-20452        got 'null\n{"order": "LB-20452"}'
llama3.2:1b  c05 loose ok  expected None            got 'Here\'s a JSON answer:\n\n{"visit": "Yes, you can visit the Museu de Arte Moderna (MAM) in Curitiba."}'
llama3.2:1b  c06 wrong     expected LB-20501        got '{"order": null}'
llama3.2:1b  c07 wrong     expected LB-20399        got '{"status": "REFUNDING"}'
```

Chaves que o prompt nunca pediu, `status` e `visit`, e um `null` antes do JSON. Ele não segura o
formato, que é a primeira coisa de que a extração precisa.

## Por tarefa, então

| | classificação, loose | extração, strict | números de pedido errados escritos |
|---|---|---|---|
| llama3.2:3b | 19 | 36 | 3: dois inventados, um alterado |
| qwen2.5:3b | 30 | 25 | 1 alterado, e 14 pedidos perdidos |
| llama3.2:1b | 5 | 8 | não segura nenhum dos formatos |

A pergunta para cada linha deixa de ser "qual é o melhor" e passa a ser **"com que erros a loja
consegue viver, em qual tarefa"**. Um pedido perdido manda uma resposta que pede o número ao cliente
de novo. Um inventado consulta o pedido e não acha nada, ou acha o de outra pessoa. A seção 10
decide.
