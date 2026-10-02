---
title: Encontrando antes do modelo
version: 1
---

Você achou a contradição do `v2-long.txt` lendo, porque o prompt é curto e as duas linhas usam
palavras óbvias. Um prompt de sessenta linhas, editado por quatro pessoas ao longo de um ano, ninguém
lê do começo ao fim. **Um linter lê todas as linhas todas as vezes**, e é barato o bastante para
rodar antes de cada mudança:

```
ana@lab:~/triage$ pl lint prompts/v2-long.txt
prompts/v2-long.txt:4: contradiction (length): lines 4 against lines 16
prompts/v2-long.txt:11: 3 lines shout: 11,13,14
prompts/v2-long.txt:14: repeats line 11
167 tokens
ana@lab:~/triage$ pl lint prompts/v2-json.txt
prompts/v2-json.txt: nothing found
69 tokens
```

Três achados no prompt longo e nenhum no curto. Cada achado aponta uma linha, então pode ser
corrigido onde está:

| achado | o que significa |
|---|---|
| `contradiction (length)` | uma linha pedindo brevidade e outra pedindo detalhe, no mesmo prompt |
| `3 lines shout` | linhas com palavras como IMPORTANT ou NEVER, que põem algumas regras acima das outras |
| `repeats line 11` | a mesma instrução duas vezes, palavra por palavra |

## O que o linter está lendo

O `pl lint` é um punhado de listas de palavras e padrões. Ele sabe que *brief*, *concise*, *short*
e *one sentence* puxam para um lado e *in detail*, *thorough* e *everything* puxam para o outro, e
avisa quando um prompt contém os dois. **Ele não entende nenhuma das duas instruções.** Daí saem
duas consequências, e as duas aparecem neste laboratório.

Ele deixa passar uma contradição escrita com outras palavras:

```
ana@lab:~/triage$ printf 'Keep the summary to one line.\nLeave nothing out of the summary.\n' | pl lint /dev/stdin
/dev/stdin: nothing found
14 tokens
```

Essas duas linhas discordam exatamente como as linhas 4 e 16, e o linter não encontra nada, porque
*one line* e *leave nothing out* não estão em nenhuma das listas dele.

E ele aponta coisas que não são o que ele diz. Volte ao achado de gritaria: as linhas 11 e 14
começam com `IMPORTANT:`, e a linha 13 começa com *Never*, uma palavra comum com inicial maiúscula
no começo da frase. O padrão ignora maiúsculas e minúsculas, então contou a linha 13 como grito.
**Um achado é uma linha para olhar, não um veredito sobre ela.**

Então `nothing found` significa que nenhum padrão casou, o que é menos do que dizer que o prompt é
claro. Vale rodar o linter porque os erros que ele pega são os que entram sem ninguém perceber: uma
regra colada pela segunda vez, uma palavra em maiúsculas posta com pressa, uma linha nova que
desfaz uma antiga em silêncio. A aula 5 roda o linter num prompt com treze regras e ele encontra
quatro problemas.

::: track ai
Você escreveu Python em `python`, então leia o `cmd_lint` em `promptlab/cli.py`. São umas quarenta
linhas, e ver as listas de palavras é o jeito mais rápido de parar de confiar no `nothing found`
mais do que ele merece.
:::

::: track *
Os padrões do linter estão em `promptlab/cli.py`, no `cmd_lint`. Você não precisa lê-los, mas saber
que são listas de palavras basta para ler a saída dele com desconfiança.
:::
