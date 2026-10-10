---
title: O que ele pega
version: 2
---

Rode o prompt delimitado e escapado com temperatura 0 e peça ao modelo para conferir cada resposta
que deu:

```
ana@lab:~/triage$ pl run prompts/v6-escaped.txt cases/all.jsonl --out runs/v6.jsonl
70 calls, prompt fbc4c9b1, llama3.2:3b, written to runs/v6.jsonl
ana@lab:~/triage$ python3 selfcheck.py runs/v6.jsonl
t01    wrong WRONG The answer is not valid JSON because it is missing the nec
t02    right WRONG The reason is that the category "delivery" is not specific
t04    right WRONG The answer is not valid JSON because it is missing the nec
t05    right WRONG The answer is not valid JSON because it is missing the req
t06    wrong WRONG The answer is not valid JSON because it is missing the req
t07    right WRONG The answer is not valid JSON because it is missing a closi
t08    right WRONG The answer is not valid JSON because it is missing the req
t09    right WRONG The reason is that the JSON object is missing a closing br
t11    right WRONG The reason is that the JSON object is missing a closing br
t13    right WRONG The answer is not valid JSON because it is missing the req
t14    right WRONG The reason is that the JSON is missing a closing bracket a
t16    right WRONG The answer is not valid JSON because it is missing a closi
t17    right WRONG The reason is that the JSON object is missing a closing br
t18    right WRONG The answer is not valid JSON because it is missing the req
t19    wrong WRONG The answer is not valid JSON because it is missing the req
t21    right WRONG The reason is that the JSON is missing a closing bracket a
t22    wrong WRONG The answer is not valid JSON because it is missing the req
t23    right WRONG The reason is that the JSON object is missing a closing br
t25    wrong OK
t26    wrong WRONG The answer is not valid JSON because it is missing the req
t27    right WRONG The answer is not valid JSON because it is missing the req
t28    right WRONG The answer is not valid JSON because it is missing the req
t31    wrong WRONG The answer is missing a colon (:) between the key "categor
t32    right WRONG The answer is not valid JSON because it is missing the nec
t36    right WRONG The answer is not valid JSON because it is missing a closi
t37    wrong OK
t38    wrong OK
t39    wrong OK
h01    wrong OK
h02    right WRONG The answer is not valid JSON because it is missing the req
h03    wrong WRONG The answer is not valid JSON because it is missing the req
h05    wrong WRONG The answer is not valid JSON because it is missing the req
h06    wrong OK
h07    wrong WRONG The answer is not valid JSON because it is missing the req
h08    right WRONG The answer is not valid JSON because it is missing the nec
h11    wrong WRONG The reason is that the JSON object is missing a closing br
h12    wrong WRONG The reason is that the JSON answer is missing the "descrip
h13    right WRONG The answer is not valid JSON because it is missing a closi
h15    right WRONG The reason is that the JSON object is missing a closing br
h16    right WRONG The reason is that the JSON answer is missing the "descrip
h17    wrong WRONG The reason is that the JSON object is missing a required k
h18    right WRONG The answer is not valid JSON because it is missing the req
h19    right WRONG The answer is not valid JSON because it is missing the req
h21    wrong OK
h22    wrong WRONG The reason is that the answer is missing the "description"
h23    wrong WRONG The reason is that the JSON object is missing a required k
h24    wrong WRONG The reason is that the category "returns" is not the corre
h25    right WRONG The answer is not valid JSON because it is missing a closi
h26    wrong OK
h27    wrong WRONG The reason is that the JSON is missing a closing bracket a
h28    wrong WRONG The reason is that the category is missing a value. In JSO
h29    right WRONG The reason is that the JSON object is missing a closing br
h30    wrong WRONG The answer is missing the "message" key, which is present 

                 really wrong  really right
flagged                    18            27
not flagged                 8            17
precision 0.40   recall 0.69
```

Das setenta respostas, 26 estavam de fato erradas. O revisor marcou 45, e 18 delas estavam entre as
26.

Dois números resumem a tabela. A **precisão** pergunta quantas marcações estavam certas: 18 de 45,
0,40. A **revocação** pergunta quantos erros foram marcados: 18 de 26, 0,69. Uma verificação com
precisão alta e revocação baixa é quieta e confiável quando fala; uma com o contrário é barulhenta e
pega mais. Nenhum dos dois números quer dizer algo sem o outro.

## Contra uma moeda

Esses dois números precisam de uma referência, e a honesta é uma verificação que não lê nada. Marque
45 das setenta respostas ao acaso, e em média as marcações caem em respostas erradas na mesma
proporção que as respostas erradas têm na execução inteira: 26 de 70, uma precisão de 0,37. A revocação
seria 45 de 70, 0,64. **Os 0,40 e 0,69 do revisor mal passam de uma verificação que joga uma
moeda**, que é o que a tabela diz quando lida por colunas: ele marcou 18 das 26 respostas erradas,
69%, e 27 das 44 certas, 61%.

## O que ele disse

Leia os motivos, não só as marcações. Quase todos são sobre o formato, e quase todos são falsos.
Aqui está o `t07`, que o revisor disse *not valid JSON because it is missing a closing bracket*:

```
ana@lab:~/triage$ pl show runs/v6.jsonl t07
│ {"category": "delivery", "urgency": "high", "summary": "Customer disputes delivery address"}
stop: stop, tokens in 151, out 23, 2.9 s
```

É analisável, tem todos os campos, e a categoria está certa. O revisor recebeu uma pergunta de sim
ou não sobre este texto e respondeu com um defeito que o texto não tem. A mesma frase, *missing a
closing bracket* ou *missing the required field*, aparece na maioria das 45 marcações, em respostas
certas e erradas. **Uma marcação que vem com um motivo não fica mais confiável por ter um**: o
motivo é gerado como todo o resto, e aqui é quase sempre inventado.

E as respostas que estavam de fato quebradas? O `t38` nem é JSON, e o revisor disse OK. A última
seção desta aula volta a ele.

## O que escapou

Oito respostas erradas voltaram OK: `t25`, `t37`, `t38`, `t39`, `h01`, `h06`, `h21` e `h26`. Sete
são erros de rótulo, e o revisor leu a mensagem e o rótulo errado e concordou. **Um erro que o
modelo cometeria de novo é um erro que a própria verificação dele não enxerga**, porque a verificação
lê com o mesmo conhecimento com que a resposta foi escrita.
