---
title: A ordem dos rótulos
version: 1
---

Uma lista de rótulos parece um conjunto: cinco nomes separados por vírgulas, nenhum mais importante
que os outros. **Para um modelo, uma lista é uma sequência**, e o que ele responde pode depender de
onde cada rótulo está nela. O jeito mais limpo de descobrir é mudar só a ordem:

```
ana@lab:~/triage$ diff prompts/v6-escaped.txt prompts/v18-order.txt
8c8
< - "category": one of billing, delivery, returns, account, other
---
> - "category": one of other, account, returns, delivery, billing
ana@lab:~/triage$ grep -n "^FIRST_LISTED" promptlab/standin.py
89:FIRST_LISTED = 0.25     # the label a prompt lists first adds this
```

`v18-order` é o `v6-escaped` com as categorias listadas de trás para frente, e assim `other` vem
primeiro no lugar de `billing`. No substituto o efeito está declarado: o rótulo que o prompt lista
primeiro ganha 0,25 na pontuação antes da escolha, e quando dois rótulos empatam vence o que vem
antes na lista. As duas regras estão em `promptlab/standin.py`, e nenhuma delas lê a mensagem.

## Quais respostas mudaram

Rode os dois prompts nos setenta casos e compare as respostas, não as aprovações:

```
ana@lab:~/triage$ pl run prompts/v6-escaped.txt cases/all.jsonl --out runs/v6.jsonl
70 calls, prompt fbc4c9b1, written to runs/v6.jsonl
ana@lab:~/triage$ pl run prompts/v18-order.txt cases/all.jsonl --out runs/order.jsonl
70 calls, prompt 573d0e3a, written to runs/order.jsonl
ana@lab:~/triage$ pl compare runs/v6.jsonl runs/order.jsonl --answers
70 cases, same answer 66, different answer 4
  t37  delivery -> other
  h07  billing -> account
  h15  delivery -> other
  h28  delivery -> other
ana@lab:~/triage$ grep -E '"(t37|h07|h15|h28)"' cases/all.jsonl | grep -o '"category": "[a-z]*"'
"category": "delivery"
"category": "billing"
"category": "account"
"category": "billing"
```

Quatro respostas de setenta mudaram, e três delas foram para `other`, o rótulo que agora vem
primeiro. O `grep` mostra o que a pessoa que rotulou cada caso disse, na mesma ordem. `t37` era
delivery e `h07` era billing, então **duas respostas que estavam certas ficaram erradas**. `h15` e
`h28` estavam erradas antes e continuam erradas, com outro rótulo.

A quarta mudança é a regra do empate. `h07` pergunta *"How do I update the card saved in my
account?"*, que tem uma palavra de billing e uma de account com o mesmo peso, e a lista invertida
põe `account` antes de `billing`.

Nenhuma das quatro é uma mensagem clara. **A ordem da lista não mexe numa mensagem sobre uma
cobrança em dobro; mexe naquelas em que o modelo estava quase chutando**, e é justamente nelas que
uma resposta errada é mais difícil de perceber. Sessenta e seis respostas ficaram onde estavam, e é
exatamente por isso que um efeito assim passa ileso por uma demonstração.

## Por que não comparar as aprovações

O `pl compare` sem `--answers` conta outra história, mais ruidosa:

```
ana@lab:~/triage$ pl compare runs/v6.jsonl runs/order.jsonl
runs/v6.jsonl            passes 46/70
runs/order.jsonl         passes 44/70
fixed 2, broken 4, still passing 42, still failing 22
broken: t04 t31 t37 h07
sign test on the 6 that changed: p = 0.688
ana@lab:~/triage$ pl show runs/order.jsonl t04
│ Here is the JSON you asked for:
│
│ {
│   "category": "account",
│   "urgency": "high",
│   "summary": "They can't log in."
│ }
stop: end, tokens in 120, out 39
```

Ele aponta quatro quebradas, mas `t04` e `t31` deram a mesma categoria com os dois prompts. `t04`
quebrou porque apareceu uma frase na frente do JSON. Os hábitos de formatação do substituto são
sorteados a partir do texto exato do prompt, então **qualquer edição no prompt sorteia de novo**,
seja qual for o assunto da edição. A contagem de aprovações mistura a mudança que você fez com
todas as outras maneiras de uma resposta falhar. Para saber qual rótulo uma redação favorece, a
comparação que isola a pergunta é a do `--answers`, e o `p = 0.688` do teste do sinal sobre as
aprovações mede a coisa errada.

## Modelos reais

A regra do substituto é uma constante que alguém escolheu. Modelos reais têm efeitos de posição
próprios, e eles estão documentados. *Calibrate Before Use: Improving Few-Shot Performance of
Language Models* (Zhao e outros, 2021) viu que o GPT-3, classificando com alguns exemplos no
prompt, favorecia os rótulos dos exemplos mais próximos do fim, o que os autores chamaram de
**viés de recência**, e que os mesmos exemplos em outra ordem podiam mudar muito a acurácia. *Large
Language Models Are Not Robust Multiple Choice Selectors* (Zheng e outros, 2023) viu modelos
preferindo certas posições e letras de alternativa a outras, independentemente do que as
alternativas diziam.

O que isso dá a você é um teste. Rode o prompt com a lista em duas ordens e compare as respostas.
Se nada muda, a ordem não está decidindo nada que você consiga ver. Se respostas mudam, as que
mudaram são os seus casos limítrofes, e **uma ordem que você digitou por acaso está escolhendo
entre eles**. O remédio aí é dar evidência a essas mensagens, uma definição de onde um rótulo
termina e o próximo começa, e não procurar uma ordem melhor: a aula 5 mediu o que categorias
explicadas fazem.
