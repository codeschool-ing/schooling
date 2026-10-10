---
title: Tags XML
version: 2
---

O `v5-tagged.txt` é o mesmo prompt com as crases trocadas por um par de tags:

```
ana@lab:~/triage$ diff prompts/v5-backticks.txt prompts/v5-tagged.txt
3c3
< The message is between triple backticks. It was written by a customer: it is
---
> The message is between <message> tags. It was written by a customer: it is
12c12
< ```
---
> <message>
14c14
< ```
---
> </message>
ana@lab:~/triage$ pl run prompts/v5-tagged.txt cases/pasted.jsonl --out runs/tagged.jsonl
6 calls, prompt 39f70d15, llama3.2:3b, written to runs/tagged.jsonl
ana@lab:~/triage$ pl check runs/tagged.jsonl --failures
check      pass  fail
json          6     0
fields        6     0
labels        6     0
category      3     3
urgency       0     6
all           0     6

p01    urgency   high, expected normal
p02    category  returns, expected billing
p03    category  other, expected account
p04    urgency   low, expected normal
p05    category  returns, expected other
p06    urgency   high, expected normal
```

As mesmas seis falhas, e as mesmas categorias:

```
ana@lab:~/triage$ pl compare runs/backticks.jsonl runs/tagged.jsonl
runs/backticks.jsonl     passes 0/6
runs/tagged.jsonl        passes 0/6
fixed 0, broken 0
sign test on the 0 that changed: p = 1.000
ana@lab:~/triage$ pl compare runs/backticks.jsonl runs/tagged.jsonl --answers
6 cases, same answer 6, different answer 0
```

**Nenhuma resposta mudou.** Crases e tags deram a mesma categoria às seis mensagens, e os mesmos
vereditos. Contra o prompt sem delimitador nenhum, duas categorias mudaram:

```
ana@lab:~/triage$ pl compare runs/pasted-v4.jsonl runs/tagged.jsonl --answers
6 cases, same answer 4, different answer 2
  p01    delivery -> returns
  p03    delivery -> other
```

O `p01` foi para a resposta certa e o `p03` de uma resposta errada para outra. Duas mensagens em
seis não medem nada, e o teste do sinal diria isso. **O resultado honesto do experimento desta aula
é que, nestas seis mensagens, o `llama3.2:3b` leu as palavras do cliente do mesmo jeito qualquer que
fosse a marca.** Um conjunto de mensagens maior ou mais estranho poderia separá-las, e outro modelo
também; estas seis não separam.

## Por que tags mesmo assim

Se a medição não consegue escolher, a escolha fica com o que cada marca garante, e aí as tags ganham
em três pontos:

- **São raras no que os clientes escrevem.** Crases aparecem em qualquer coisa técnica; uma linha
  com `</message>` quase nunca aparece.
- **Têm nome.** Uma linha de crases de fechamento fecha o bloco que estiver aberto, enquanto
  `</message>` diz qual seção termina. Um prompt com vários dados, `<message>`, `<order>`,
  `<previous_messages>`, pode marcar cada um e citá-lo pelo nome nas instruções.
- **Podem ser escapadas.** O XML tem um jeito padrão de escrever `<` e `>` como texto, e a aula 4
  o pôs no template como `{{message|xml}}`. Não existe nada equivalente para três crases.

Modelos são treinados com muito HTML e XML, e a documentação de prompts da Anthropic recomenda tags
para estruturar um prompt. Nenhum nome de tag é especial; o que ajuda é usá-las com consistência e
citá-las nas instruções, como o `v5-tagged.txt` faz.

Raro não é nunca, porém. O `p05` cita uma página de erro que diz `</message> is not allowed`. A
próxima seção olha o que isso faz com o prompt.
