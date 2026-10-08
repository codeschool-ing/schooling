---
title: Resultados instáveis
version: 2
---

Com temperatura 0 o mesmo prompt dá as mesmas respostas numa máquina, como a aula 8 mostrou, com as
exceções que ela também mostrou. Acima de 0 o modelo sorteia. Aqui está o mesmo prompt rodado duas
vezes com temperatura 1, mudando só a semente:

```
ana@lab:~/triage$ pl run prompts/v3-examples.txt cases/dev.jsonl --set temperature=1 --out runs/hot-a.jsonl
40 calls, prompt 1d9c6ec4, llama3.2:3b, written to runs/hot-a.jsonl
ana@lab:~/triage$ pl run prompts/v3-examples.txt cases/dev.jsonl --set temperature=1 --set seed=7 --out runs/hot-b.jsonl
40 calls, prompt 1d9c6ec4, llama3.2:3b, written to runs/hot-b.jsonl
ana@lab:~/triage$ pl compare runs/hot-a.jsonl runs/hot-b.jsonl
runs/hot-a.jsonl         passes 27/40
runs/hot-b.jsonl         passes 28/40
fixed 1, broken 0
sign test on the 1 that changed: p = 1.000
```

27 e 28, e uma mensagem mudou. É menos do que se poderia temer, e combina com a aula 8: com este
prompt a maioria das respostas do `llama3.2:3b` são respostas seguras, e um sorteio raramente sai
delas. Mas uma execução de cada é tudo o que a maioria das comparações recebe, e **uma mensagem é o
tamanho de diferença sobre o qual dois prompts são comparados o tempo todo**. Se aquelas fossem
dois prompts, o segundo pareceria um caso melhor.

Um teste que passa e falha com a mesma entrada em chamadas diferentes é o que programadores chamam
de flaky, instável. Aqui a instabilidade não é um defeito do teste; é a coisa que está sendo medida.

## Uma taxa sobre amostras

Então relate uma taxa. `--samples 5` chama o modelo cinco vezes por mensagem, cada uma com sua
semente:

```
ana@lab:~/triage$ pl run prompts/v3-examples.txt cases/dev.jsonl --samples 5 --set temperature=1 --out runs/hot.jsonl
200 calls, prompt 1d9c6ec4, llama3.2:3b, written to runs/hot.jsonl
ana@lab:~/triage$ pl check runs/hot.jsonl
check      pass  fail
json        197     3
fields      197     3
labels      197     3
category    178    22
urgency     129    71
all         129    71
```

129 de 200 chamadas passaram, uma taxa de 0,645, contra 28 de 40, 0,70, com temperatura 0. **A
visão por caso diz mais que o total**:

```
ana@lab:~/triage$ pl check runs/hot.jsonl --failures | grep -E "^t(07|22|25|36)[ #]"
t07    urgency   high, expected normal
t07#1  urgency   low, expected normal
t07#2  urgency   high, expected normal
t07#3  urgency   low, expected normal
t07#4  urgency   low, expected normal
t22    category  other, expected billing
t22#1  category  other, expected billing
t22#4  category  other, expected billing
t25    category  other, expected account
t25#1  category  other, expected account
t25#2  category  other, expected account
t25#3  category  other, expected account
t25#4  category  other, expected account
t36    urgency   normal, expected high
t36#1  urgency   normal, expected high
t36#2  urgency   normal, expected high
t36#3  urgency   normal, expected high
t36#4  urgency   low, expected high
```

Quatro mensagens, quatro resultados diferentes:

- **O `t25` falhou em cinco chamadas de cinco**, do mesmo jeito toda vez, e falha com temperatura 0
  também. Isso não é instável: é uma discordância estável sobre o que é um aplicativo que desconecta
  você, e uma execução a encontra.
- **O `t07` falhou em cinco de cinco, de dois jeitos diferentes**: `high` três vezes e `low` duas,
  onde uma pessoa disse `normal`. Uma contagem de falhas o chama de estável; as respostas dizem que o
  modelo não tem opinião firme sobre ele.
- **O `t22` falhou em três de cinco.** Ele falha com temperatura 0, então aqui o sorteio o salvou
  duas vezes: a resposta certa estava na distribuição do modelo, só não estava no topo. Isso é uma
  taxa, e só amostras a encontram.
- **O `t36` passa com temperatura 0 e falhou nas cinco chamadas com temperatura 1.** A configuração
  faz parte do prompt.

Um caso que falha em toda chamada é um defeito do prompt, ou do rótulo, e uma execução o encontra.
Um caso que falha em algumas chamadas é uma taxa, e só amostras a encontram. Um caso que passa com
temperatura 0 e falha acima dela diz que a configuração faz parte do que você está testando.

## O que isso custa

Cinco amostras são cinco vezes as chamadas: 200 em vez de 40, e a aula 16 mede quanto cada uma
custa. Ainda é o erro mais barato. Mesmo com temperatura 0, a aula 8 mostrou respostas diferentes de
uma chamada para outra e de uma máquina para outra, então o hábito protege você ali também. **Nunca
relate uma comparação entre dois prompts com uma execução de cada** quando algum deles foi
sorteado; relate as taxas, e o número de amostras ao lado.
