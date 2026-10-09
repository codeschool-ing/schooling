---
title: Um registro de decisão
version: 2
---

Um registro de decisão é um arquivo curto escrito no momento em que uma escolha é feita, dizendo o
que foi escolhido e por quê. A forma vem da arquitetura de software: o texto de Michael Nygard
*Documenting Architecture Decisions* (2011) propôs um arquivo pequeno e numerado por decisão, com o
contexto, a decisão, o status e as consequências, guardado no repositório junto com o código. **Ele
funciona para prompts pelo mesmo motivo que funciona para código**: as escolhas que parecem mais
estranhas muitas vezes são as que alguém pesou por mais tempo.

## A evidência primeiro

O registro abaixo responde à pergunta de fevereiro: os exemplos devem ser JSON, ou linhas simples? A
evidência começa pela comparação da aula 14, rodada de novo, a versão com exemplos simples contra o
arquivo como está agora:

```
ana@lab:~/triage$ git show 86913c0:prompts/triage.txt > runs/plain.txt
ana@lab:~/triage$ pl run runs/plain.txt cases/dev.jsonl --out runs/plain.jsonl
40 calls, prompt 055cb22b, llama3.2:3b, written to runs/plain.jsonl
ana@lab:~/triage$ pl run prompts/triage.txt cases/dev.jsonl --out runs/dev.jsonl
40 calls, prompt c1916fcd, llama3.2:3b, written to runs/dev.jsonl
ana@lab:~/triage$ pl compare runs/plain.jsonl runs/dev.jsonl
runs/plain.jsonl         passes 27/40
runs/dev.jsonl           passes 24/40
fixed 1, broken 4
broken: t12 t23 t28 t38
sign test on the 5 that changed: p = 0.375
```

Quatro quebradas e uma consertada pela volta ao JSON, p = 0.375. Uma das quatro:

```
ana@lab:~/triage$ grep t12 cases/dev.jsonl
{"id": "t12", "message": "Tracking says delivered but there is nothing at my door.", "expect": {"category": "delivery", "urgency": "high"}}
ana@lab:~/triage$ pl show runs/plain.jsonl t12
│ {"category": "delivery", "urgency": "high", "summary": "expects delivery but nothing received"}
stop: stop, tokens in 258, out 24, 3.5 s
ana@lab:~/triage$ pl show runs/dev.jsonl t12
│ {"category": "delivery", "urgency": "normal", "summary": "Wants to know why the order was not delivered as expected."}
stop: stop, tokens in 303, out 32, 4.2 s
```

Uma encomenda marcada como entregue que nunca chegou é urgente, e o prompt das linhas simples disse
isso. É uma mensagem. Antes de alguém escrever uma decisão só com o dev, o holdout recebe a mesma
pergunta:

```
ana@lab:~/triage$ pl run runs/plain.txt cases/holdout.jsonl --out runs/plain-holdout.jsonl
30 calls, prompt 055cb22b, llama3.2:3b, written to runs/plain-holdout.jsonl
ana@lab:~/triage$ pl compare runs/plain-holdout.jsonl runs/holdout.jsonl
runs/plain-holdout.jsonl passes 12/30
runs/holdout.jsonl       passes 15/30
fixed 5, broken 2
broken: h12 h16
sign test on the 7 that changed: p = 0.453
```

**O holdout aponta para o outro lado**: os exemplos em JSON aprovam 15 de 30, as linhas simples 12,
cinco mensagens consertadas e duas quebradas pelo JSON. O dev favorece as linhas simples por três, o
holdout favorece o JSON por três, e nenhum dos testes do sinal chega perto de pequeno. Neste modelo,
estas setenta mensagens não conseguem distinguir os dois. Isso é um resultado, e um registro que o
deixasse de fora seria do tipo que faz a próxima pessoa rodar o mesmo experimento de novo.

## O registro

```localised
0001  Os exemplos continuam em JSON, exatamente como a resposta

Data     2026-08-17
Status   aceita

Contexto
  prompts/triage.txt mostra três exemplos da resposta. Em 14 de agosto
  (86913c0) eles foram reescritos como linhas simples, para ler melhor;
  em 17 de agosto (85dfa4e) voltaram a ser JSON. A instrução de
  responder só com o objeto JSON esteve lá o tempo todo.

Opções consideradas
  1. Sem exemplos, o formato descrito em palavras (61d470e): 22/40 dev.
  2. Exemplos em linhas simples (86913c0): 27/40 dev, 12/30 holdout,
     11553 tokens no dev.
  3. Exemplos em JSON (85dfa4e): 24/40 dev, 15/30 holdout,
     13408 tokens no dev.

Decisão
  Opção 3, por um motivo que os números não resolvem: a forma da
  resposta é aquilo de que o programa depende, e um exemplo nessa forma
  é o único lugar onde ela é mostrada ao modelo. As opções 2 e 3 não se
  separam nesses conjuntos de teste; a opção 2 custa 14% menos tokens.

Evidência
  pl compare runs/plain.jsonl runs/dev.jsonl
  fixed 1, broken 4; sign test on the 5 that changed: p = 0.375
  pl compare runs/plain-holdout.jsonl runs/holdout.jsonl
  fixed 5, broken 2; sign test on the 7 that changed: p = 0.453

Revisar quando
  o modelo mudar; existir um conjunto de teste grande o bastante para
  separar 2 e 3; ou o custo virar a restrição, o que faz da opção 2 o
  padrão. Qualquer um desses passa pela trava da aula 14.
```

Cada parte está lá para um leitor que não estava na sala.

- *Contexto* diz o que era verdade quando a escolha foi feita, para o leitor saber se ainda é.
- *Opções consideradas* lista as que perderam, com os números. A opção rejeitada é a que a próxima
  pessoa vai propor, e é aqui que ela descobre que foi tentada.
- *Decisão* dá o motivo, e diz com clareza quando o motivo é um julgamento e não uma medição. **Um
  registro que vestisse esta escolha de comprovada estaria mentindo**, e a próxima pessoa confiaria
  nele exatamente até onde a mentira fosse.
- *Evidência* é um comando e o que ele imprimiu. Colar a saída mantém a afirmação verificável depois
  que os arquivos de execução sumirem; o comando deixa qualquer um produzi-la de novo.
- *Revisar quando* nomeia as condições que tornariam a decisão errada. **Um registro sem isso
  parece permanente**, e nada num prompt é.

## Mantendo-os honestos

Numere os registros e nunca edite um depois de aceito. Quando uma decisão é revertida, escreva um
registro novo que diga isso e marque o antigo como substituído, que é a regra que o texto de Nygard
dá. O raciocínio antigo continua legível, e o novo tem de explicar o que mudou. Ligue cada registro
ao commit que o executa, para que o log aponte para o motivo mesmo sem poder guardá-lo: a mensagem
do `85dfa4e` poderia ter sido *Put the examples back in JSON (decision 0001)*.

**Escreva um quando houve uma escolha de verdade**, não para todo commit. O `c8f1927`, escapar a
mensagem, precisava de uma frase na mensagem do commit; a forma dos exemplos, que uma pessoa razoável
mudaria, e mudou, precisava de um registro.
