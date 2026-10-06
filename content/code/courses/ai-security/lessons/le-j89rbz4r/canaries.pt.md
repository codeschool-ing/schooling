---
title: Um marcador que avisa que o prompt de sistema saiu
version: 1
---

Um prompt de sistema guarda instruções que os clientes não devem ler: como o assistente trata
reembolsos, quais assuntos mandar a uma pessoa, às vezes nomes internos. A aula 5 trata de como um prompt
escapa. Esta seção trata de perceber quando ele escapou, com um **canário**: um marcador que não
significa nada, escrito no prompt de sistema e em nenhum outro lugar, e que portanto nunca deveria
aparecer numa resposta.

```
ana@lab:~/guard$ cat data/system-prompt.txt
You are Tarefa's support assistant. Answer questions about jobs, payments and
accounts from the help centre. Never ask for card numbers or passwords.
Internal marker: CANARY-7F3A-TAREFA. This marker is not for clients.
```

`CANARY-7F3A-TAREFA` é o marcador. A cadeia de filtros o procura em toda resposta, e a `r3` acima foi
bloqueada por ele com um alerta, porque uma resposta que contém o marcador repetiu o prompt de sistema
palavra por palavra. O alerta importa mais que o bloqueio: diz a alguém que o prompt está chegando às
respostas, o que vale uma investigação mesmo que toda resposta vazada seja barrada.

Agora as mesmas respostas com a camada canário desligada:

```
ana@lab:~/guard$ guard filter data/pipeline-outputs.jsonl --skip canary
layers: personal-data -> moderation -> links
r1  pass  
r2  BLOCK personal data: cpf
r3  pass  
r4  BLOCK moderation: harassment 0.82
r5  BLOCK link to a host not on the allowlist: https://pay-tarefa.example/confirm
r6  pass  
```

A `r3` passa, o que mostra o que a camada acrescentava. Veja também a `r6`, que passou nas duas
execuções. Ela descreve as instruções com as próprias palavras, e **o marcador não está lá**, então
nenhum canário consegue vê-la. Um canário detecta um vazamento literal e mais nada.

Três notas práticas:

- **Um marcador por versão do prompt**, para que um alerta diga qual versão vazou e desde quando.
- **Nunca ponha um segredo num prompt de sistema** confiando no canário para protegê-lo. O canário relata
  um vazamento; não impede nenhum. Chaves e credenciais ficam com as ferramentas, como disse a aula 20.
- **Escreva o prompt de sistema como se ele fosse ser lido.** Provavelmente vai ser, por alguém. Um prompt
  que envergonharia a empresa se publicado é um prompt a reescrever, sejam quais forem os filtros atrás.
