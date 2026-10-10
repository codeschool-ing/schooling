---
title: Voltar atrás, e o que a revisão de um prompt confere
version: 1
---

Quando uma mudança num prompt dá errado em produção, o movimento seguro mais rápido é **pôr de volta a
última versão aprovada**, e só então entender o que aconteceu. Redigitá-la de memória é como se comete
um segundo erro durante o primeiro. O `approve` guardou uma cópia de cada texto aprovado, e o
`rollback` copia uma de volta:

```
ana@lab:~/guard$ guard prompts rollback data/prompts/classify.txt aa32449d3f
restored data/prompts/classify.txt to approved version aa32449d3f
ana@lab:~/guard$ guard prompts status; echo "exit status $?"
data/prompts/classify.txt    aa32449d3f  approved by ana.lima on 2026-10-01
data/helpdesk/hc-fees.md     ff40a81202  approved by ana.lima on 2026-10-01
data/helpdesk/hc-payouts.md  0fe2b8eec1  approved by ana.lima on 2026-10-01
data/helpdesk/hc-refunds.md  f32fa16253  approved by ana.lima on 2026-10-01
data/model.json              3138932013  approved by ana.lima on 2026-10-01
exit status 0
```

O prompt está de novo em `aa32449d3f`, aprovado, e o status de saída é 0. O rollback não recusou nada
aqui porque a versão pedida tinha sido aprovada; uma versão que nunca foi não pode ser restaurada por
este comando, então um rollback não vira um jeito de implantar um texto não revisado.

## O que quem revisa um prompt olha

A revisão de uma mudança de prompt faz as perguntas que a revisão de código faz, mais duas que são de
modelos:

| pergunta | o que responde |
|---|---|
| o que mudou? | o diff do arquivo, no pull request |
| ainda faz o trabalho dele? | os casos da aula 23, rodados contra a versão nova: aqui, os doze tickets |
| enfraquece alguma defesa? | os casos que medem as defesas das aulas 14 a 16 |
| o modelo é o que foi testado? | o `data/model.json`, numa versão aprovada |
| quem aprovou, e por quê? | o registro, com um nome e um motivo |

## Fixar o modelo, além do prompt

O `data/model.json` diz `llama3.2:3b` com temperatura 0 e seed 1, e está sob revisão como o prompt. Um
nome de modelo de fornecedor que sempre aponta para o lançamento mais novo muda por baixo do
assistente no calendário do fornecedor, e cada medida acima vira a medida de um modelo que já não está
lá. **Fixe a versão datada ou numerada que o fornecedor oferece**, como a aula 19 pediu no
questionário dela, e passe para uma nova pela mesma revisão: mudar o arquivo, rodar os casos, aprovar
com um nome.

## O que isto não cobre

Uma versão diz qual texto rodou; não diz que o texto era bom. A aprovação é o julgamento de uma
pessoa, registrado, e a medida são doze tickets. **Os dois valem tanto quanto os casos que rodam**, e
esse é o assunto da aula 23.
