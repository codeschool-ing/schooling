---
title: Pegando uma regressão no mesmo dia
version: 1
---

A tabela da seção anterior foi impressa depois do fato, para uma aula. Em agosto, nada a imprimiu. O
`31a6a59` entrou na tarde do dia 14, e se alguém rodou o conjunto de teste contra ele a história não
conta. Por três dias o prompt no ar respondeu a cada mensagem num formato que nenhum programa
conseguia ler. **Uma regressão é encontrada quando alguém olha, e o único alguém confiável é uma
verificação que roda sozinha.**

## Uma verificação a cada mudança

A verificação é a mesma comparação que a aula 1 usou para decidir se os exemplos ajudavam, apontada
para o outro lado. Antes de uma mudança no prompt entrar, rode o arquivo novo sobre os conjuntos de
teste, rode o arquivo que está no ar e compare os dois mensagem por mensagem:

```
ana@lab:~/triage$ pl compare runs/c8470c9.jsonl runs/31a6a59.jsonl
runs/c8470c9.jsonl       passes 36/40
runs/31a6a59.jsonl       passes 0/40
fixed 0, broken 36, still passing 0, still failing 4
broken: t01 t02 t03 t04 t05 t06 t07 t08 t09 t10 t11 t12 t13 t15 t16 t17 t18 t19 t20 t21 t22 t23 t25 t26 t27 t29 t30 t31 t32 t33 t34 t35 t36 t38 t39 t40
sign test on the 36 that changed: p = 0.000
```

Essa saída, em 14 de agosto, teria barrado o merge. Trinta e seis mensagens quebradas e nenhuma
corrigida, **e ela dá o nome de cada uma**, então quem fez a mudança começa por `t01`, não por uma
contagem. O total é a linha menos útil ali. Uma mudança pode corrigir uma mensagem, quebrar outra e
deixar o total exatamente onde estava, e a linha que importa para uma barreira é `broken`.

Uma barreira montada sobre isso tem três partes, e nenhuma é engenhosa:

1. **Ela roda a cada mudança num arquivo de prompt**, antes do merge, no mesmo lugar que roda seus
   outros testes. Uma verificação de que alguém precisa lembrar roda nos dias em que a pessoa lembra.
2. **Ela roda todos os conjuntos de teste que o prompt tem**, não só dev. O `931c548` mostrou que dev
   não enxerga o que o conjunto de ataques enxerga, e uma barreira só com dev deixaria passar uma
   mudança que desfizesse aquilo.
3. **Ela falha com qualquer mensagem quebrada** e imprime os ids, e quem quiser fazer o merge mesmo
   assim diz por quê no commit. Às vezes quebrar uma mensagem para corrigir cinco é o certo; isso
   nunca deveria acontecer sem que ninguém perceba.

## Uma regressão sem diff

A barreira compara execuções, e uma execução é mais que o arquivo. Aqui está a execução com
temperatura 0.8 de antes, contra a execução do mesmo arquivo no padrão:

```
ana@lab:~/triage$ pl compare runs/now.jsonl runs/hot.jsonl
runs/now.jsonl           passes 36/40
runs/hot.jsonl           passes 28/40
fixed 0, broken 8, still passing 28, still failing 4
broken: t06 t08 t18 t20 t23 t25 t33 t38
sign test on the 8 that changed: p = 0.008
```

Oito mensagens quebradas, e um teste do sinal de 0.008 diz que é improvável que seja acaso. **O id do
prompt é o mesmo nas duas execuções, e o `git diff` não mostraria nada**, porque a mudança nunca
esteve no arquivo. Uma barreira que só roda quando o arquivo do prompt muda nunca veria isso. É o
argumento prático para a regra da seção anterior: quando todo parâmetro mora no arquivo, toda mudança
no que a produção roda é uma mudança no arquivo, e a barreira vê todas.

A aula 15 registra o que uma regressão como a do `31a6a59` ensina, para que a próxima pessoa que for
deixar os exemplos mais fáceis de ler saiba por que eles têm a cara que têm.
