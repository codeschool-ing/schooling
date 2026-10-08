---
title: Quem está perguntando
version: 2
---

A aula 2 terminou num vazamento. Um atendente perguntou quando um pedido fica retido para revisão
manual de fraude, e o pipeline, buscando em todos os documentos para todo mundo, respondeu com o
limite que a equipe financeira tinha escrito como não sendo para atendentes: 0,82. Nada no pipeline
falhou. Ele não sabia quem estava perguntando, então não tinha como saber o que quem perguntou podia
ler.

Todo pedaço carrega o `audience` do seu documento desde a aula 5: `public`, `staff`, `finance`,
`sellers` ou `developers`. O que faltava era a outra metade, **uma decisão sobre quais públicos cada
leitor abre**, tomada uma vez e escrita onde possa ser revisada. É a primeira parte do `access.py`,
cujas outras funções as próximas seções desmontam; salve o módulo inteiro agora, porque todo programa
desta aula o importa:

```schooling-example
{
  "language": "python",
  "file": "access.py",
  "parts": [
    {
      "code": "\"\"\"Who may read what: the audiences each role opens, decided by the system and never by the question.\"\"\"\nimport psycopg\nfrom vectors import embed\nfrom pgvector.psycopg import register_vector\n\nROLES = {\n    \"customer\":  [\"public\"],\n    \"seller\":    [\"public\", \"sellers\"],\n    \"developer\": [\"public\", \"developers\"],\n    \"agent\":     [\"public\", \"staff\"],\n    \"finance\":   [\"public\", \"staff\", \"finance\"],\n}",
      "note": "Quem pode ler o quê, escrito uma vez. Cada papel abre uma lista de públicos, os valores do campo `audience` que todo pedaço carrega desde a aula 5."
    },
    {
      "code": "def audiences(role):\n    \"\"\"The audiences a role may read. A role nobody wrote down reads nothing.\"\"\"\n    return ROLES.get(role, [])",
      "note": "Um papel que não está no dicionário recebe uma lista vazia, e uma lista vazia não casa com linha nenhuma. Um erro de digitação no nome do papel fecha a porta em vez de abri-la."
    },
    {
      "code": "def connect():\n    \"\"\"The assistant's own connection: a role that can only SELECT, and only what the policy lets through.\"\"\"\n    conn = psycopg.connect(host=\"localhost\", user=\"assistant\", password=\"reads-only\", autocommit=True)\n    register_vector(conn)\n    return conn",
      "note": "O assistente se conecta com um papel próprio no banco, `assistant`, que pode ler a tabela e mais nada."
    },
    {
      "code": "def search(conn, role, question, k=3, only=None):\n    \"\"\"Lesson 6's search with the role's audiences in the WHERE, inside a transaction that also tells\n    the database whose search it is, so its policy applies the same limit a second time. ONLY, a\n    narrowing the reader asked for, is intersected with what the role allows and can never add to it.\"\"\"\n    allowed = [a for a in audiences(role) if only is None or a in only]\n    q = embed(question)[0]\n    with conn.transaction():\n        conn.execute(\"SELECT set_config('rag.audiences', %s, true)\", (\",\".join(allowed),))\n        return conn.execute(\n            \"SELECT id, path, text, audience, 1 - (embedding <=> %s) FROM chunks\"\n            \" WHERE status = 'current' AND audience = ANY(%s)\"\n            \" ORDER BY embedding <=> %s LIMIT %s\", (q, allowed, q, k)).fetchall()",
      "note": "Os públicos do papel vão para o `WHERE`, então a busca só ordena o que o leitor pode ver. A mesma lista é definida para a transação como `rag.audiences`, que a política do banco lê na próxima seção; o `true` faz a configuração acabar com a transação, para não vazar para a próxima requisição na mesma conexão."
    }
  ]
}
```

O papel vem da sessão: a conta que entrou, as permissões dela no sistema da própria loja. Nunca vem da
requisição nem da pergunta. Neste curso um dicionário faz as vezes desse sistema, e um programa
diz qual papel está representando.

```schooling-example
{
  "language": "python",
  "file": "roles.py",
  "parts": [
    {
      "code": "import sys\n\nimport access\nfrom answer import FLOOR, REFUSAL, ask\nfrom search import conn as loader\n\nquestion = sys.argv[1]\nprint(question)\nfor role in sys.argv[2:]:\n    found = [r for r in access.search(loader, role, question) if r[4] >= FLOOR]\n    updated = dict(loader.execute(\"SELECT id, updated FROM chunks WHERE id = ANY(%s)\", ([r[0] for r in found],)))\n    sources = [{\"path\": p, \"text\": t, \"updated\": updated[i]} for i, p, t, _, _ in found]\n    print(f\"{role:9} {', '.join(f'{r[1]} ({r[3]}, {r[4]:.3f})' for r in found) or 'nothing above the floor'}\")\n    print(f\"{'':9} {ask(question, sources) if sources else REFUSAL}\")",
      "note": "Uma pergunta feita em nome de cada papel da linha de comando, pela busca filtrada: o que a busca de cada papel achou, e a resposta que ele recebeu."
    }
  ]
}
```
```
ana@vm:~/rag$ python roles.py "When does an order get held for manual fraud review?" customer agent finance
When does an order get held for manual fraud review?
customer  Returns and refunds policy > Damaged, faulty and wrong items (public, 0.516), Terms of sale > 2. Placing an order (public, 0.506)
          I could not find that in our documents.
agent     Customer support handbook > Suspected fraud (staff, 0.586), Returns and refunds policy > Damaged, faulty and wrong items (public, 0.516), Terms of sale > 2. Placing an order (public, 0.506)
          According to [1], an order is held for manual fraud review when it looks suspicious, such as a new account ordering many copies of one expensive title to an address that is not the billing address.
finance   Refund controls and chargebacks > Automatic holds (finance, 0.644), Customer support handbook > Suspected fraud (staff, 0.586), Returns and refunds policy > Damaged, faulty and wrong items (public, 0.516)
          According to [1], an order with a fraud score of 0.82 or more is held before dispatch and goes to manual review.
```

A mesma pergunta, três leitores, três conjuntos de fontes. **Só o financeiro recebe o documento do
financeiro**, e o 0,82 na resposta. A primeira fonte do atendente é a seção do manual sobre suspeita de
fraude, e a resposta é o que o manual diz a um atendente: um pedido que parece suspeito, como uma conta
nova pedindo muitos exemplares de um título caro, fica retido para revisão. Nenhum número, porque as
fontes do atendente não têm nenhum. As fontes do cliente são duas seções públicas que passam do piso
sem tratar de retenção por fraude, e o modelo recusou, o que para o cliente é a resposta certa. Uma
pergunta sobre o que fazer, e não sobre a regra, mostra o que o manual dá a um atendente:

```
ana@vm:~/rag$ python roles.py "What happens to an order that looks fraudulent?" agent finance
What happens to an order that looks fraudulent?
agent     Customer support handbook > Suspected fraud (staff, 0.678), Terms of sale > 2. Placing an order (public, 0.516)
          According to the customer support handbook [1], if an order looks suspicious, you should open a finance review with the reason "fraud" and continue to answer the customer normally, allowing the finance team to decide on the course of action. 

Additionally, according to the terms of sale [2], if an order is suspected to be fraudulent, the company may refuse to dispatch the order, and if they do, they will refund any amount already taken within three working days.
finance   Customer support handbook > Suspected fraud (staff, 0.678), Refund controls and chargebacks > Automatic holds (finance, 0.554), Terms of sale > 2. Placing an order (public, 0.516)
          According to [1], if an order looks suspicious, you should open a finance review with the reason "fraud" and continue to answer the customer normally. Finance will then decide on the order and inform you what to say.

However, it's also worth noting that the payment provider gives every order a fraud score, and if the score is 0.82 or more, the order is held before dispatch and goes to manual review [2]. This suggests that the order is indeed flagged for potential fraud, but it's up to finance to make the final decision.

It's also worth noting that the terms of sale state that you may refuse an order before dispatch if it's out of stock, has an obvious error in price, or the payment is not confirmed [3]. However, this doesn't necessarily mean that the order is fraudulent, but rather that it's not valid for dispatch.

In any case, the most up-to-date information on handling suspicious orders comes from [1], which advises to open a finance review with the reason "fraud" and let finance decide.
```

O atendente ouve o que o manual diz aos atendentes: abrir uma revisão do financeiro com o motivo
*fraud* e continuar atendendo o cliente normalmente. O financeiro recebe a mesma instrução e, como
fonte 2, o fato sobre notas de fraude do seu próprio documento; as duas respostas também usaram os
termos de venda, que qualquer pessoa pode ler. **Cada leitor recebeu a melhor resposta que as suas
permissões permitem**, e ninguém recebeu uma resposta feita de texto que não pode ler.