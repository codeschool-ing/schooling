---
title: Tom, por regras
version: 1
---

Exatidão e formato têm respostas que alguém anotou. Tom não tem, e a reação mais comum é
desistir de medi-lo. A alternativa é anotar as partes dele que **dá** para expressar como regras. O
`runs/drafts.jsonl` guarda doze respostas a clientes, escritas pelo curso e não por um modelo, e é por
isso que o `pl show` não informa tokens para elas. O `checks/tone.json` guarda as regras:

```
ana@lab:~/triage$ cat checks/tone.json
{
  "max_exclamations": 1,
  "max_words": 80,
  "banned": ["\\bdear (sir|madam)\\b", "\\bvalued customer\\b", "\\bas per\\b"],
  "promises": ["\\btoday\\b", "\\bimmediately\\b", "\\bguarantee", "\\bwithin 24 hours\\b"],
  "acknowledge": ["\\bsorry\\b", "\\bthank", "\\bapologi"]
}
ana@lab:~/triage$ pl tone runs/drafts.jsonl
t01  ok   
t02  FAIL exclamations
t03  FAIL promise
t04  FAIL banned, acknowledge
t05  ok   
t06  ok   
t07  ok   
t08  ok   
t09  FAIL promise
t10  FAIL exclamations
t11  FAIL length
t12  FAIL banned, promise

exclamations  2 of 12 fail
length        1 of 12 fail
banned        2 of 12 fail
promise       3 of 12 fail
acknowledge   1 of 12 fail
```

Cinco regras, cada uma um teste unitário no sentido da aula 11: no máximo um ponto de exclamação, no
máximo oitenta palavras, nenhuma das expressões que a loja nunca usa, nenhuma promessa de uma lista
curta, e algum reconhecimento do cliente. Cinco dos doze rascunhos passam em todas as regras.

## O que uma regra enxerga

**Uma regra pega exatamente o que ela nomeia**, e isso tem dois lados:

```
ana@lab:~/triage$ pl show runs/drafts.jsonl t02
│ Thank you for your patience! The tracking stopped at the courier's depot. I've asked them to trace it and I'll write again by Thursday!
stop: end, tokens in 0, out 0
ana@lab:~/triage$ pl show runs/drafts.jsonl t03
│ Sorry the cover arrived torn. A replacement goes out today and there's no need to send the damaged copy back.
stop: end, tokens in 0, out 0
```

`t02` falha nos pontos de exclamação, dois onde a regra permite um, o que é justo. Ela também promete
escrever de novo *by Thursday*, uma data, e a regra `promise` não percebeu, porque a lista dela nomeia
*today*, *immediately*, *guarantee* e *within 24 hours*, e Thursday não é nenhuma dessas. `t03` falha
em `promise` por *a replacement goes out today*. Se a loja de fato envia reposições no mesmo dia, essa
é a frase mais útil da resposta.

Então os rascunhos mostram os dois erros de uma regra em duas linhas: uma promessa que ela perdeu e
uma frase boa que ela marcou. **Uma regra é um substituto para um julgamento**, e os erros dela são
onde o julgamento e o substituto se separam. Isso não é motivo para largar as regras. Elas são de
graça, dão o mesmo veredito sempre, e pegam *Dear Sir/Madam* e *valued customer* sem falhar.

## O que nenhuma regra aqui enxerga

Nenhuma das cinco pergunta se a resposta é verdadeira, se responde à pergunta, ou se soa como alguém
que se importa. `t01` passa em tudo; uma resposta educada sobre o pedido errado também passaria. Tom
além das regras precisa de alguém lendo uma amostra, ou de um modelo encarregado de julgar, e a aula 13
mede até onde dá para confiar num modelo juiz para isso.
