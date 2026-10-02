---
title: Por que delimitar
version: 1
---

Um prompt chega ao modelo como um único fluxo de texto. **Suas instruções e as palavras do cliente
são o mesmo tipo de caractere**, e nada além do próprio texto diz onde um termina e o outro começa.
Um delimitador é uma marca que você põe em volta das palavras do cliente para que a fronteira fique
escrita, em vez de adivinhada.

O prompt da aula 6 não tem nenhum. A última linha dele é a mensagem:

```
ana@lab:~/triage$ tail -n 3 prompts/v4-only-json.txt
Reply with only the JSON object: no code fence and no other text.

Message: {{message}}
ana@lab:~/triage$ pl render prompts/v4-only-json.txt --cases cases/pasted.jsonl --case p04 | tail -n 7 | cat -n
     1	
     2	Message: The courier left this note:
     3	```
     4	Attempted delivery 14:02
     5	No safe place
     6	```
     7	When will they try again?
```

O `pl render` preenche o template com um caso e mostra o prompt exatamente como o modelo o
receberia; o `cat -n` numera as linhas, por um motivo que a próxima seção explica. A mensagem começa
depois de `Message:` e vai até o fim do prompt. Isso funciona enquanto as palavras do cliente são a
última coisa do prompt e não contêm nada que pareça estrutura. `cases/pasted.jsonl` tem seis
mensagens que quebram a segunda condição: clientes que colaram um erro, uma linha de extrato
bancário ou o bilhete de um entregador, do jeito que as pessoas fazem.

```
ana@lab:~/triage$ pl run prompts/v4-only-json.txt cases/pasted.jsonl --out runs/pasted-v4.jsonl
6 calls, prompt 651820d7, written to runs/pasted-v4.jsonl
ana@lab:~/triage$ grep '"p01"' cases/pasted.jsonl
{"id": "p01", "message": "The ebook I bought won't download. The page shows ```Error 403: link expired``` instead.", "expect": {"category": "returns", "urgency": "normal"}}
ana@lab:~/triage$ pl show runs/pasted-v4.jsonl p01
│ {
│   "category": "other",
│   "urgency": "normal",
│   "summary": "Error 403: link expired"
│ }
stop: end, tokens in 104, out 29
```

O resumo é a mensagem de erro que o cliente colou, e a categoria é `other`. A regra do substituto
está escrita no comentário de abertura dele: ele procura a mensagem dentro de tags `<message>`,
depois dentro do último par de crases triplas, e só então depois de `Message:`. Este prompt não
marca nada, então **as crases do cliente eram o único delimitador à vista, e o substituto ficou com
elas**. Um modelo real não roda essa regra, mas enfrenta a mesma pergunta sem nada para respondê-la,
e **um prompt que não marca nada deixa a fronteira para um palpite**.
