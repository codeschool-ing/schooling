---
title: O que os exemplos vazam
version: 1
---

O substituto copia a forma da resposta do primeiro exemplo. **Isso inclui coisas que você não quis
dizer como forma.** Veja como `t17` voltou com o prompt de exemplos:

```
ana@lab:~/triage$ pl show runs/v3.jsonl t17
│ {"category": "delivery", "urgency": "high", "summary": "Their order was dispatched ten days ago and still hasn't arrived."}
stop: end, tokens in 247, out 38
```

Uma linha, as chaves na ordem dos exemplos, um espaço depois de cada dois-pontos. O prompt sem
exemplos produzia o mesmo JSON em cinco linhas. Nada verifica isso e nada precisa verificar, mas é o
primeiro sinal do que o próximo arquivo faz de propósito.

## Um campo que ninguém quis

`prompts/v3-leaky.txt` é o `v3-examples.txt` com uma mudança. Alguém copiou o primeiro exemplo de um
chamado real e deixou o número do pedido:

```
ana@lab:~/triage$ grep -n order prompts/v3-leaky.txt
9:Message: I paid for express delivery but the order came by normal post.
10:Output: {"category": "billing", "urgency": "normal", "summary": "Wants the express delivery charge back.", "order": "4471"}
ana@lab:~/triage$ pl run prompts/v3-leaky.txt cases/dev.jsonl --out runs/leaky.jsonl
40 calls, prompt 0acdc3c7, written to runs/leaky.jsonl
ana@lab:~/triage$ pl check runs/leaky.jsonl
check      pass  fail
json         40     0
fields        0    40
labels        0    40
category      0    40
urgency       0    40
all           0    40
ana@lab:~/triage$ pl show runs/leaky.jsonl t04
│ {"category": "account", "urgency": "high", "summary": "They can't log in.", "order": "4471"}
stop: end, tokens in 246, out 39
```

**Cada uma das quarenta respostas traz `"order": "4471"`**, inclusive a do cliente que não consegue
entrar e não tem pedido nenhum. O modelo não tinha valor para um campo que lhe mostraram, então
copiou o que tinha. No substituto isso é uma regra; num modelo real é uma tendência, e bem
documentada: nomes, datas e números dos exemplos aparecem em respostas sobre outra coisa.

Duas coisas nessa transcrição valem guardar.

**A verificação pegou porque é rigorosa.** `fields` reprova uma resposta com um campo que ninguém
pediu. Uma verificação que só procurasse os campos necessários teria aprovado as quarenta, e o número
do pedido chegaria a quem lê o JSON em seguida.

**E toda resposta falhou do mesmo jeito.** Um defeito num exemplo não é um erro ocasional; ele é
copiado em todas as respostas, o que o torna barulhento num conjunto de teste e invisível numa
demonstração, em que você testa uma mensagem e o campo a mais parece um recurso.

## Impedir que os exemplos ensinem a coisa errada

- **Varie o que deve variar.** Se os três resumos começassem com *Wants*, todo resumo começaria.
  Os exemplos aqui começam com *Wants*, *Wants* e *Asks*, e isso já é um padrão.
- **Tire o que pertence a um cliente**: nomes, números de pedido, datas, valores. Troque por valores
  que obviamente são de exemplo, ou deixe de fora.
- **Faça os exemplos responderem exatamente o que o prompt pede**, campo por campo. Um exemplo é a
  instrução mais forte de um prompt, então um exemplo que discorda da descrição vence.
- **Verifique com rigor**, para que o que um exemplo vaza reprove num teste em vez de chegar a um
  leitor.
