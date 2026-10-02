---
title: Um template, todos os casos
version: 1
---

Um conjunto de teste é possível por causa dos templates. **Quarenta execuções de um template, com só
a mensagem mudando, significam que qualquer diferença entre duas execuções é obra do template**, e
essa é a condição em que toda comparação deste curso se apoia. O mesmo arquivo renderiza todos os
casos do mesmo jeito:

```
ana@lab:~/triage$ pl render prompts/v6-escaped.txt --cases cases/dev.jsonl --case t02 | tail -n 3
<message>
My parcel was meant to arrive on Monday and the tracking hasn't moved since Friday.
</message>
ana@lab:~/triage$ pl run prompts/v6-escaped.txt cases/dev.jsonl --out runs/v6.jsonl
40 calls, prompt fbc4c9b1, written to runs/v6.jsonl
```

Se as instruções estivessem coladas em quarenta arquivos, ou editadas à mão para uma mensagem
difícil, a execução estaria medindo quarenta prompts de uma vez, e uma mudança em um deles
apareceria como ruído na contagem.

## As configurações moram com o template

A mensagem não é a única coisa que muda o que o modelo faz. A temperatura, o limite de saída, o
modelo e o cache também são configurações, e um arquivo de prompt neste laboratório pode trazê-las
num cabeçalho, um `nome: valor` por linha, acima de uma linha de três traços:

```
ana@lab:~/triage$ head -n 3 prompts/v17-static-first.txt
cache: on
---
You sort customer messages for Folio, an online bookshop, so that the right
```

`cache: on` é assunto da aula 17. O que importa aqui é onde está escrito: no mesmo arquivo das
instruções, para quem lê o prompt ver todos os valores com que ele roda.

## O que o id do prompt cobre

O `pl run` imprime um id para o prompt que rodou, e o registra em cada linha da execução. São os
oito primeiros caracteres do SHA-256 do arquivo:

```
ana@lab:~/triage$ pl run prompts/v17-static-first.txt cases/dev.jsonl --out runs/v17.jsonl
40 calls, prompt b04095b1, written to runs/v17.jsonl
ana@lab:~/triage$ sha256sum prompts/v17-static-first.txt | cut -c1-8
b04095b1
ana@lab:~/triage$ pl run prompts/v17-static-first.txt cases/dev.jsonl --out runs/v17-hot.jsonl --set temperature=0.8
40 calls, prompt b04095b1, written to runs/v17-hot.jsonl
```

Mude uma palavra, uma linha em branco ou uma configuração do cabeçalho e o id muda. **Defina a
temperatura na linha de comando, em vez disso, e o id continua o mesmo**: as duas execuções acima
dizem `b04095b1`, e uma delas amostrou com 0.8. Quem comparar as duas depois, só pelos arquivos de
execução, vai acreditar que rodaram o mesmo prompt. Esse é o argumento prático a favor do cabeçalho.
Uma configuração escrita no arquivo é coberta pelo id, e uma configuração digitada na linha de
comando não é coberta por nada, a não ser que alguém a anote. A aula 14 se apoia nesse id para
acompanhar o que cada mudança fez.
