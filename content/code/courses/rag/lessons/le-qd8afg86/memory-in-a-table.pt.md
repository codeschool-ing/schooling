---
title: Memória numa tabela
version: 1
---

Recuperar um turno exige que os turnos estejam em algum lugar que uma busca alcance. O `memory.py` os
guarda numa tabela, no mesmo banco que os documentos, uma linha por turno, com embedding do mesmo
modelo:

```schooling-example
{
  "language": "python",
  "file": "memory.py",
  "parts": [
    {
      "code": "SCHEMA = \"\"\"\nCREATE TABLE IF NOT EXISTS memories (\n    id           bigserial PRIMARY KEY,\n    account      text NOT NULL,\n    conversation text NOT NULL,\n    turn         int NOT NULL,\n    text         text NOT NULL,\n    embedding    vector(384) NOT NULL,\n    created      timestamptz NOT NULL DEFAULT now()\n);\nCREATE INDEX IF NOT EXISTS memories_account ON memories (account);\n\"\"\"\nORDER = re.compile(r\"\\bMG-\\d{8}\\b\")\nconn.execute(SCHEMA)",
      "note": "Uma linha por turno de toda conversa, com a conta a que pertence e o embedding do turno. O índice em `account` existe porque toda consulta tem de nomear uma."
    },
    {
      "code": "def remember(account, conversation, turn, text):\n    conn.execute(\"INSERT INTO memories (account, conversation, turn, text, embedding) VALUES (%s, %s, %s, %s, %s)\",\n                 (account, conversation, turn, text, embed(text)[0]))",
      "note": "Cada turno é guardado assim que é dito, antes de o próximo chegar."
    },
    {
      "code": "def recall(account, question, k=2, before=None):\n    \"\"\"The K earlier turns of THIS account most similar to the question, oldest first.\"\"\"\n    q = embed(question)[0]\n    found = conn.execute(\n        \"SELECT turn, text, 1 - (embedding <=> %s) FROM memories WHERE account = %s AND turn < %s\"\n        \" ORDER BY embedding <=> %s LIMIT %s\", (q, account, before or 2**31 - 1, q, k)).fetchall()\n    return sorted(found)",
      "note": "A busca da aula 6 sobre os turnos do próprio cliente. O `account` não é opcional: a função não pode ser chamada sem dizer de quem é a memória que ela busca. O `before` impede que um turno recupere a si mesmo."
    }
  ]
}
```

É **memória externa**: fora do modelo, fora do prompt, num armazenamento que a aplicação possui e
consulta. O modelo nunca lembra nada entre duas chamadas; o que quer que pareça lembrar foi posto na
frente dele pelo programa, e esta tabela é onde o programa guarda isso. Isso transforma memória num
problema comum de engenharia, com um esquema, um índice, consultas que dá para ler e linhas que dá
para apagar.

Três propriedades desta tabela são decisões, e não detalhes.

- **Toda linha leva a conta.** Não a conversa, que é uma sessão e termina, mas a pessoa, que volta.
  Toda pergunta sobre memória, recuperação, privacidade, exclusão, é uma pergunta sobre as linhas de
  uma pessoa.
- **Os turnos são guardados como o cliente os escreveu**, sem resumo nem extração. Um resumo é a
  leitura que um modelo fez do que foi dito, e a aula 15 é sobre quando essa troca vale a pena; as
  palavras originais sempre podem ser resumidas depois, e um resumo nunca pode voltar a ser elas.
- **Recuperar é buscar, com as ferramentas da aula 6.** O mesmo modelo de embeddings e a mesma
  distância de cosseno da busca nos documentos, então o `LIKE` da seção anterior, parecido com um
  piso, pode ser escolhido do mesmo jeito, olhando notas.

O `chat.py` grava cada turno depois de respondê-lo e recupera antes de responder o próximo, então um
turno pode recuperar tudo o que foi dito antes dele e nunca a si mesmo.
