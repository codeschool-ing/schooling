---
title: O registro de falhas
version: 2
---

Um registro de decisão explica uma escolha. Um registro de falhas explica um acidente: toda vez que
o prompt é pego fazendo algo errado, uma entrada dizendo o que aconteceu e o que agora impede que
aconteça de novo. A prática é mais velha que os prompts. O livro *Site Reliability Engineering* do
Google (2016) dedica um capítulo, *Postmortem Culture: Learning from Failure*, a escrevê-las sem
culpados, e **o ponto vale sem mudança: a entrada é sobre o sistema, não sobre quem fez a edição**.

## A evidência para a entrada

O prompt como está falha em `json` em duas mensagens do dev, e elas têm algo em comum:

```
ana@lab:~/triage$ grep -E "\"t3[78]\"" cases/dev.jsonl
{"id": "t37", "message": "The book I ordered says 'in stock' but my order still says 'awaiting dispatch' after a week.", "expect": {"category": "delivery", "urgency": "normal"}}
{"id": "t38", "message": "The ebook I bought won't open on my reader.", "expect": {"category": "returns", "urgency": "normal"}}
ana@lab:~/triage$ pl show runs/dev.jsonl t37
│ {"category": "delivery", "urgency": "high", "summary": "Wants to know why the order status hasn"}}
stop: stop, tokens in 315, out 28, 4.2 s
ana@lab:~/triage$ pl show runs/dev.jsonl t38
│ {"category": "returns", "urgency": "normal", "summary": "The ebook won"}}
stop: stop, tokens in 303, out 22, 3.0 s
```

O `t37` para em *hasn* e o `t38` em *won*, e os dois fecham o objeto duas vezes. O modelo escreveu o
apóstrofo de *hasn't* e de *won't*, terminou a string ali, e se perdeu. A aula 3 achou o `t38`
fazendo exatamente isso com o `v2-json.txt`, e nada desde então o consertou.

## A entrada

```localised
F-0001  Resumos cortados num apóstrofo; a resposta não é JSON

Visto        2026-08-17, prompts/triage.txt em 85dfa4e (id c1916fcd)
Mensagens    t37 "...still says 'awaiting dispatch' after a week."
             t38 "The ebook I bought won't open on my reader."
O modelo     {"category": "returns", "urgency": "normal",
disse         "summary": "The ebook won"}}
Pego por     json, a primeira verificação: 2 de 40 no dev
Causa        o modelo termina a string do resumo num apóstrofo de uma
             contração que está copiando da mensagem
Correção     ainda não. O modo de schema da aula 3 mantém a resposta como
             JSON válido; ele não está no prompts/triage.txt. Decisão a seguir.
Teste novo   nenhum necessário: t37 e t38 já são casos do dev. A trava da
             aula 14 reprova qualquer mudança que quebre um terceiro
Custo        dois chamados em quarenta chegam a uma pessoa sem classificação
```

Seis linhas carregam o peso.

- *Mensagens* e *O modelo disse* são a evidência, citada em vez de descrita. Uma resposta real diz
  a um leitor mais que uma frase sobre respostas, e a do `t38` mostra o corte e a chave dupla de uma
  vez.
- *Pego por* nomeia a verificação, ou a verificação que o teria pegado. Quando a resposta é *nada
  teria pegado*, essa é a linha mais importante do registro, porque é um buraco nos testes.
- *Causa* diz o que o autor da entrada acredita e nada mais. Duas mensagens com o mesmo corte são um
  padrão; *o modelo não lida com apóstrofos* seria uma afirmação que ninguém mediu.
- *Correção* cita um commit ou diz que ainda não há nenhum. Uma entrada honesta sobre uma falha em
  aberto vale mais que um registro que só anota as fechadas.
- *Teste novo* é o que a mantém consertada.

## A linha que mais importa

Esta falha é do tipo conveniente: o conjunto de teste já a pega, e o trabalho que falta é uma
correção. A maioria das falhas é do outro tipo. Um cliente escreve algo que ninguém imaginou, a
resposta sai errada, e alguém nota na fila do suporte. **A correção não termina até essa mensagem,
limpa de nomes e números, virar um caso num conjunto de teste**, com a resposta que uma pessoa
decidiu ser a certa. Senão a trava não tem em que falhar, e a mesma falha pode voltar com a próxima
mudança e passar em todas as verificações.

Leia uma dúzia de entradas juntas e elas mostram padrões que nenhuma sozinha mostra. Aqui duas
mensagens já formam um: um apóstrofo numa contração, copiado para uma string JSON, é onde este modelo
se perde. Uma terceira entrada terminando em *cortado num apóstrofo* seria o registro dizendo algo
sobre como as respostas são produzidas e não sobre três mensagens.
