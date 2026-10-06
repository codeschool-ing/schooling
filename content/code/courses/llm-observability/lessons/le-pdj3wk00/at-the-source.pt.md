---
title: Tirar antes de escrever
version: 1
---

O lugar mais seguro para remover algo é **antes que seja registrado**: uma vez que um valor está num
span, ele está na memória, numa fila de exportação, e depois em todo lugar para onde o span é copiado.
Então o assistente nunca põe as palavras de um cliente num span diretamente. Ele as passa primeiro
pelo `redact()`, do `redact.py`:

```schooling-example
{
  "language": "python",
  "file": "redact.py",
  "parts": [
    {
      "code": "import hashlib\nimport hmac\nimport os\nimport re\n\nPATTERNS = [\n    (\"email\", re.compile(r\"[\\w.+-]+@[\\w-]+(?:\\.[\\w-]+)+\")),\n    (\"phone\", re.compile(r\"\\+\\d{1,3}(?:[\\s-]?\\d){8,12}\")),\n    (\"card\", re.compile(r\"\\b(?:\\d[ -]?){13,19}\\b\")),\n    (\"order\", re.compile(r\"\\bMG-\\d{8}\\b\")),\n]",
      "note": "Quatro padrões, cada um com o nome que o substitui. A ordem importa: um endereço de e-mail sai antes que algo dentro dele possa parecer um número."
    },
    {
      "code": "def redact(text):\n    \"\"\"TEXT with every match of PATTERNS replaced by its name in brackets.\"\"\"\n    for name, pattern in PATTERNS:\n        text = pattern.sub(f\"[{name}]\", text)\n    return text\n\n\ndef found(text):\n    \"\"\"{name: count} of what redact() would take out of TEXT.\"\"\"\n    return {name: len(p.findall(text)) for name, p in PATTERNS if p.search(text)}",
      "note": "`redact()` substitui; `found()` só conta, que é o que o `scan.py` usou. Os dois leem a mesma lista, então o que se conta é o que seria removido."
    },
    {
      "code": "KEY = os.environ.get(\"PSEUDONYM_KEY\", \"\").encode()\n\n\ndef pseudonym(user):\n    \"\"\"A keyed hash of USER: the same person gets the same value, and without the key nobody can\n    go from the value back to the person by trying every user id.\"\"\"\n    if not KEY:\n        raise RuntimeError(\"PSEUDONYM_KEY is not set: refusing to record a user id unkeyed\")\n    return hmac.new(KEY, user.encode(), hashlib.sha256).hexdigest()[:16]",
      "note": "O pseudônimo, que uma seção mais adiante explica. A chave vem do ambiente, e sem chave a função se recusa em vez de recorrer a um hash sem chave."
    }
  ]
}
```

E no `assistant.py`, os dois atributos que carregam texto são escritos através dele:

```python
    with span("ask", **{"app.feature": feature, "app.release": release, "gen_ai.request.model": cfg["model"],
                        "user.hash": redact.pseudonym(user), "session.id": session or "",
                        "app.question": redact.redact(question)}) as root:
```

```python
        root.set_attribute("app.reply", redact.redact(reply))
```

Uma das perguntas sobre pedido da semana, feita à mão:

```
ana@lab:~/obs$ python assistant.py --feature order --user u021 "Hi, I am Joana Prado (joana.prado@example.com). My order MG-20481937 has not arrived after 12 working days. Is it lost?"
I could not find that in our documents.
trace 31b9488c6865b9bd1722d976e1ce6a0c
ana@lab:~/obs$ python tree.py --attrs | grep -E "app.question|app.reply|user.hash"
                     user.hash = "d6aad8d0fb204820"
                     app.question = "Hi, I am Joana Prado ([email]). My order [order] has not arrived after 12 working days. Is it lost?"
                     app.reply = "I could not find that in our documents."
```

O endereço e o número do pedido sumiram da pergunta, trocados pelo nome do que estava lá. A resposta é
uma recusa, então não tinha nada a remover. E o usuário é `d6aad8d0fb204820` em vez de `u021`, que é o
pseudônimo que a última seção desta aula explica.

**Um marcador que diz o que substituiu vale mais do que um espaço em branco.** `[email]` mantém a
frase legível e mantém um fato que importa para depurar: o cliente deu um endereço, então o
assistente tinha como contatá-lo e mesmo assim recusou. Um espaço em branco, ou uma fileira de
asteriscos, não mantém nenhuma das duas coisas.

## Conferindo que funcionou

Escrever uma remoção não é o mesmo que saber que ela rodou. A conferência é procurar nos spans
guardados um valor que foi enviado:

```
ana@lab:~/obs$ grep -c "joana.prado@example.com" spans.jsonl
0
ana@lab:~/obs$ grep -c "Joana Prado" spans.jsonl
1
```

O endereço não aparece em lugar nenhum. O nome aparece uma vez, na pergunta, e isso não é um defeito
dos padrões: não existe padrão para nome, que é o assunto de uma seção mais adiante.

Torne a conferência permanente. Um teste que manda um pedido com um endereço conhecido, que só existe
para o teste, e depois falha se esse endereço aparecer em qualquer span exportado, roda em um segundo
e pega o dia em que alguém acrescenta um atributo novo e esquece a função. **Um canário é um valor que
nunca deveria sair do outro lado**, e a ausência dele é a única evidência de que a remoção está ligada.

## Por que não remover num lugar só, mais tarde

É tentador escrever o texto como está e limpá-lo no backend de rastreamento, ou num job que roda de
madrugada. Três coisas dão errado. Toda cópia feita antes da limpeza guarda o original: a fila de
exportação, o buffer de entrada do backend, um backup feito à meia-noite. O backend precisa ser
informado de quais campos limpar, e ele não vai saber do atributo acrescentado no mês que vem. E uma
pessoa que pergunta o que se guarda sobre ela tem direito a uma resposta que inclua as cópias sujas.

Então a primeira linha fica no código que define o atributo, e a segunda, na próxima seção, fica no
processo, antes que o span saia dele. Nenhuma fica no backend.
