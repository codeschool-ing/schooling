---
title: Uma conversa não é uma pergunta
version: 2
---

Todo pipeline deste curso até aqui respondeu uma pergunta de cada vez. Um chat de atendimento não é
isso. É um cliente contando uma história em várias mensagens, e as mensagens de depois se apoiam nas
de antes: "o outro pacote", "ele", "meu número de pedido de novo". O `data/chat-a.jsonl` são doze
mensagens de Beatriz Costa sobre o pedido MG-20481937, escritas para o curso: um exemplar danificado
de *Persuasion*, o livro errado no lugar de *Middlemarch*, um pedido de contato só por e-mail, e
quatro perguntas perto do fim.

O `chat.py` reproduz a conversa turno a turno com uma escolha de memória. A primeira é nenhuma: cada
mensagem passa pelo pipeline da aula 7 como se fosse a única.

As duas conversas que esta aula acompanha vêm de um script, como os documentos da aula 1. Salve-o
como `~/rag/chats.sh` e rode-o:

```sh
#!/bin/sh
# chats.sh: writes two customers' conversations with the help assistant
set -e
mkdir -p data
cat > data/chat-a.jsonl <<'EOF'
{"turn": 1, "text": "Hi, my name is Beatriz Costa and I have a problem with order MG-20481937."}
{"turn": 2, "text": "The order had two books. Persuasion arrived with water damage on the cover."}
{"turn": 3, "text": "The other parcel had the wrong book: I ordered Middlemarch and got Mansfield Park."}
{"turn": 4, "text": "Please write to me by email only. I cannot take phone calls at work."}
{"turn": 5, "text": "For Persuasion I would like a replacement, not a refund."}
{"turn": 6, "text": "For Middlemarch I want my money back. I bought it somewhere else in the meantime."}
{"turn": 7, "text": "I have photographs of the damaged cover next to the box. Where do I send them?"}
{"turn": 8, "text": "Also, I am moving house next week, so the replacement should go to Rua das Flores 120, Curitiba."}
{"turn": 9, "text": "Do I need to send the damaged copy back to you?"}
{"turn": 10, "text": "How do I send back Mansfield Park?"}
{"turn": 11, "text": "How long will the refund for Middlemarch take?"}
{"turn": 12, "text": "Sorry, what was my order number again? I need it for my notes."}
EOF
cat > data/chat-b.jsonl <<'EOF'
{"turn": 1, "text": "Hello, this is Rafael Lima. My order MG-31770254 has not arrived."}
{"turn": 2, "text": "It was sent by standard delivery and the tracking has not changed for twelve working days."}
{"turn": 3, "text": "I would prefer a refund rather than waiting for a new parcel."}
{"turn": 4, "text": "Could you remind me of my order number?"}
EOF
```
```
ana@vm:~/rag$ sh chats.sh
ana@vm:~/rag$ wc -l data/chat-*.jsonl
  12 data/chat-a.jsonl
   4 data/chat-b.jsonl
  16 total
```
O `chat.py` precisa de um módulo próprio, o `memory.py`, que guarda cada turno numa tabela; as
próximas seções desta aula desmontam os dois. Salve-os agora:

```schooling-example
{
  "language": "python",
  "file": "memory.py",
  "parts": [
    {
      "code": "\"\"\"A customer's memory: every turn kept in a table, recalled by similarity, never across accounts,\nand a state the program writes from what it knows for certain.\"\"\"\nimport re\n\nfrom vectors import embed\nfrom search import conn\n\nSCHEMA = \"\"\"\nCREATE TABLE IF NOT EXISTS memories (\n    id           bigserial PRIMARY KEY,\n    account      text NOT NULL,\n    conversation text NOT NULL,\n    turn         int NOT NULL,\n    text         text NOT NULL,\n    embedding    vector(384) NOT NULL,\n    created      timestamptz NOT NULL DEFAULT now()\n);\nCREATE INDEX IF NOT EXISTS memories_account ON memories (account);\n\"\"\"\nORDER = re.compile(r\"\\bMG-\\d{8}\\b\")\nconn.execute(SCHEMA)",
      "note": "Uma tabela de todo turno, com a conta e o vetor dele, criada quando o módulo é importado pela primeira vez. A seção sobre memória numa tabela explica cada escolha dela."
    },
    {
      "code": "def remember(account, conversation, turn, text):\n    conn.execute(\"INSERT INTO memories (account, conversation, turn, text, embedding) VALUES (%s, %s, %s, %s, %s)\",\n                 (account, conversation, turn, text, embed(text)[0]))",
      "note": "Guardar um turno."
    },
    {
      "code": "def recall(account, question, k=2, before=None):\n    \"\"\"The K earlier turns of THIS account most similar to the question, oldest first.\"\"\"\n    q = embed(question)[0]\n    found = conn.execute(\n        \"SELECT turn, text, 1 - (embedding <=> %s) FROM memories WHERE account = %s AND turn < %s\"\n        \" ORDER BY embedding <=> %s LIMIT %s\", (q, account, before or 2**31 - 1, q, k)).fetchall()\n    return sorted(found)",
      "note": "Achar os turnos de uma conta mais parecidos com uma pergunta, antes de um turno dado."
    },
    {
      "code": "def state(account, name):\n    \"\"\"What the program knows for certain, written as sentences a reply to the customer can quote.\"\"\"\n    said = \" \".join(t for (t,) in conn.execute(\"SELECT text FROM memories WHERE account = %s ORDER BY turn\",\n                                               (account,)))\n    orders = list(dict.fromkeys(ORDER.findall(said)))\n    lines = [f\"The customer is {name}.\"]\n    if orders:\n        lines.append(f\"The customer's order number is {' and '.join(orders)}.\")\n    return \" \".join(lines)",
      "note": "O que o programa sabe com certeza sobre o cliente."
    },
    {
      "code": "def forget(account):\n    return conn.execute(\"DELETE FROM memories WHERE account = %s\", (account,)).rowcount",
      "note": "Apagar todo turno de uma conta."
    }
  ]
}
```
```schooling-example
{
  "language": "python",
  "file": "chat.py",
  "parts": [
    {
      "code": "\"\"\"One customer's conversation, answered turn by turn with one of three memories.\"\"\"\nimport json\nimport sys\n\nimport memory\nfrom answer import REFUSAL, SYSTEM, sources_for\nfrom openai import OpenAI\n\nclient = OpenAI()\nACCOUNTS = {\"chat-a\": (\"A-1001\", \"Beatriz Costa\"), \"chat-b\": (\"A-1002\", \"Rafael Lima\")}\nRECALL, LIKE = 1, 0.5",
      "note": "Os dois clientes do `chats.sh`, cada um com uma conta, e dois ajustes da memória que a seção sobre reescrita explica."
    },
    {
      "code": "def call(messages):\n    reply = client.chat.completions.create(model=\"llama3.2:3b\", temperature=0, messages=messages)\n    return reply.choices[0].message.content, reply.usage.prompt_tokens",
      "note": "Uma chamada ao modelo, devolvendo a resposta e quantos tokens o prompt tinha."
    },
    {
      "code": "def numbered(sources):\n    return \"\\n\\n\".join(f\"[{n}] {s['path']}\\n{s['text']}\" for n, s in enumerate(sources, 1))",
      "note": "Fontes numeradas como a aula 7 as numera."
    },
    {
      "code": "def ask(sources, question, past=()):\n    messages = [{\"role\": \"system\", \"content\": SYSTEM}, *past,\n                {\"role\": \"user\", \"content\": f\"{numbered(sources)}\\n\\nQuestion: {question}\"}]\n    return (*call(messages), sources)",
      "note": "O prompt da aula 7, com as mensagens anteriores que uma memória decidir mandar na frente dele."
    },
    {
      "code": "def alone(text, past, account, name):\n    \"\"\"Lesson 7's pipeline: the turn is the whole question.\"\"\"\n    sources = sources_for(text)\n    return ask(sources, text) if sources else (REFUSAL, 0, [])",
      "note": "A primeira memória: nenhuma."
    },
    {
      "code": "def history(text, past, account, name):\n    \"\"\"Every earlier turn, the customer's and the assistant's, sent again as messages.\"\"\"\n    return ask(sources_for(text), text, past)",
      "note": "A segunda: todo turno anterior, mandado de novo. A seção sobre mandar o histórico a roda."
    },
    {
      "code": "def remembered(text, past, account, name):\n    \"\"\"The earlier turns most like this one, if they are like it at all, put in front of it to make\n    a search that stands on its own; the state as a source; and the documents that search finds. The customer's own words steer\n    the search and are never sources to cite; the model is asked what the customer asked.\"\"\"\n    recalled = [r for r in memory.recall(account, text, RECALL) if r[2] >= LIKE]\n    search = \" \".join([t for _, t, _ in recalled] + [text])\n    state = {\"path\": \"what we know about this customer\", \"text\": memory.state(account, name)}\n    return ask([state] + sources_for(search), text)",
      "note": "A terceira, que as seções sobre reescrita, memória numa tabela e estado vão montando."
    },
    {
      "code": "if __name__ == \"__main__\":\n    chat, how = sys.argv[1], sys.argv[2]\n    RECALL = int(sys.argv[3]) if len(sys.argv) > 3 else RECALL\n    account, name = ACCOUNTS[chat]\n    respond = {\"alone\": alone, \"history\": history, \"memory\": remembered}[how]\n    memory.forget(account)\n    past, total = [], 0\n    for line in open(f\"data/{chat}.jsonl\"):\n        turn = json.loads(line)\n        reply, sent, sources = respond(turn[\"text\"], past, account, name)\n        total += sent\n        if \"?\" in turn[\"text\"]:\n            print(f\"{turn['turn']:2} {sent:5} tokens  {turn['text']}\")\n            found = [s for s in sources if \"score\" in s]\n            print(f\"   first document: {found[0]['score']:.3f}  {' '.join(found[0]['text'].split()[:9])} ...\"\n                  if found else \"   no document above the floor\")\n            print(f\"   {reply}\")\n        else:\n            print(f\"{turn['turn']:2} {sent:5} tokens\")\n        memory.remember(account, chat, turn[\"turn\"], turn[\"text\"])\n        past += [{\"role\": \"user\", \"content\": turn[\"text\"]}, {\"role\": \"assistant\", \"content\": reply}]\n    print(f\"{total} prompt tokens over {turn['turn']} turns\")",
      "note": "Rodado como programa: a conversa turno a turno com a memória nomeada na linha de comando, imprimindo o tamanho de todo prompt e a resposta de toda pergunta, e lembrando cada turno pelo caminho."
    }
  ]
}
```
```
ana@vm:~/rag$ python chat.py chat-a alone
 1     0 tokens
 2   185 tokens
 3     0 tokens
 4     0 tokens
 5     0 tokens
 6     0 tokens
 7   186 tokens  I have photographs of the damaged cover next to the box. Where do I send them?
   first document: 0.563  If a book arrives with a torn cover, bent ...
   You can send the photographs of the damaged cover next to the box to [support@marginalia.com](mailto:support@marginalia.com).
 8     0 tokens
 9   242 tokens  Do I need to send the damaged copy back to you?
   first document: 0.617  If a book arrives with a torn cover, bent ...
   According to [1], you do not need to send the damaged copy back to us.
10     0 tokens  How do I send back Mansfield Park?
   no document above the floor
   I could not find that in our documents.
11   295 tokens  How long will the refund for Middlemarch take?
   first document: 0.611  We refund within three working days of the return ...
   I could not find that in our documents.
12     0 tokens  Sorry, what was my order number again? I need it for my notes.
   no document above the floor
   I could not find that in our documents.
908 prompt tokens over 12 turns
```

Para cada turno, os tokens que o prompt custou (0 quando o piso recusou sem chamar o modelo), e para
cada pergunta, o primeiro documento que a busca achou e a resposta. **Uma das cinco perguntas recebe
uma boa resposta sozinha**: o turno 9, o exemplar danificado, que traz o próprio assunto. As outras
quatro não funcionam.

- **O turno 7, "Where do I send them?"**, recebe um endereço, `support@marginalia.com`, que nenhum
  documento contém. O endereço de verdade da loja é `help@marginalia.example`, no manual de
  atendimento, que esta busca não trouxe. O modelo preencheu o buraco com algo que parece uma resposta.
- **O turno 10, "How do I send back Mansfield Park?"**, não acha nada acima do piso. *Mansfield Park*
  é um título, e nenhuma política o menciona; o que torna a pergunta respondível é o turno 3, em que
  Beatriz disse que era o livro errado.
- **O turno 11, "How long will the refund for Middlemarch take?"**, acha a seção de reembolsos, com
  0,611, e o modelo recusa: a fonte não menciona *Middlemarch*, e sem o turno 6 nada diz que o
  reembolso é desse livro.
- **O turno 12, "what was my order number again?"**, não acha nada, porque a resposta não está em
  documento nenhum. Está no turno 1.

As três recusas estão certas pela regra da aula 7, e cada uma faria um cliente fechar o chat: o
assistente ouviu tudo o que precisava, e se comporta como se não tivesse ouvido nada. O resto da aula
são três jeitos de lhe dar uma memória, e o que cada um custa.
