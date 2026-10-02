---
title: Parando uma resposta
version: 1
---

Uma pessoa que vê a resposta indo para o lado errado aperta Parar. **Em código, parar é fechar a
conexão**: o provedor percebe que não consegue mais mandar e para de escrever. O `cancel.py` faz o
papel dessa página e para depois de quarenta caracteres.

```python
"""Stop reading after the first forty characters, as a page does when someone presses Stop."""
import anthropic

model = anthropic.Anthropic()
ASK = [{"role": "user", "content": "Explain in a paragraph why the cart stores prices in cents."}]
got = ""
with model.messages.stream(model="scripted-1", max_tokens=300, messages=ASK) as stream:
    for text in stream.text_stream:
        got += text
        if len(got) >= 40:
            break
print(repr(got))
```

O `break` sai do laço, e sair do bloco `with` fecha a resposta:

```
ana@dev:~/shop$ python cancel.py
'The cart stores prices as integer cents because'
ana@dev:~/shop$ sleep 1; tail -n 1 /var/log/labllm/requests.jsonl | python -c 'import json, sys; r = json.loads(sys.stdin.read()); print(r["status"], "| planned:", r["usage"]["output_tokens"], "tokens | sent before the close:", r["sent"])'
client went away | planned: 82 tokens | sent before the close: 9
```

**O labllm parou também.** Ele tinha 82 tokens planejados e mandou 9 antes de a escrita seguinte
achar a conexão fechada; o log dele diz `client went away`. Um provedor de verdade se comporta do
mesmo jeito visto de fora. Se os tokens que ele escreveu antes de perceber são cobrados está nos
termos dele; planeje como se fossem.

## O que Parar precisa querer dizer

- **Fechar o stream até o provedor**, não só o que vai ao navegador. Um relay que continua lendo
  depois de a página sumir paga por uma resposta que ninguém vai ver. No relay da aula 9 seção 04,
  uma conexão de navegador fechada faz a escrita seguinte falhar, o que sai do bloco `with` e fecha
  a requisição a montante.
- **Manter o que foi mostrado, e marcá-lo.** Quarenta caracteres de uma resposta não são uma
  resposta. Se a conversa continua, ou descarte a resposta parcial ou mande-a marcada como
  interrompida, para o modelo não lê-la como algo que terminou de dizer.
- **Não contar como erro.** Um stream parado é escolha de uma pessoa. Registrá-lo junto com as
  falhas faz a taxa de erro dizer algo sobre os seus usuários em vez de sobre o seu sistema.
