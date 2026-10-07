---
title: Parando uma resposta
version: 2
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
with model.messages.stream(model="llama3.2:3b", max_tokens=300, messages=ASK) as stream:
    for text in stream.text_stream:
        got += text
        if len(got) >= 40:
            break
print(repr(got))
```

O `break` sai do laço, e sair do bloco `with` fecha a resposta:

```
ana@dev:~/shop$ python cancel.py
'The practice of storing prices in cents in'
```

E isto é o que o terminal que roda o `ollama serve` imprimiu naquele momento, as três últimas linhas:

```
srv          stop: cancel task, id_task = 1421
slot      release: id  0 | task 1421 | stop processing: n_tokens = 47, truncated = 0
srv  update_slots: all slots are idle
```

**O Ollama parou também.** `cancel task` é o servidor percebendo a conexão fechada, e `n_tokens = 47`
é até onde ele chegou: os 38 tokens da pergunta e do template, e 9 de resposta, mais ou menos os
quarenta caracteres que o script guardou. Um provedor se comporta do mesmo jeito visto de fora. Se
os tokens que ele escreveu antes de perceber são cobrados está nos termos dele; planeje como se
fossem.

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
