---
title: Testes que não precisam de modelo
version: 1
---

O comportamento de um agente depende de um modelo, mas a maior parte do código do `minagent` não depende: validação, recusas, limites, o rastro e o resultado são Python comum, e podem ser testados como Python comum. A costura do adaptador da seção 04 é o que torna isso possível: um teste entrega ao agente um modelo que responde exatamente o que o teste quer.

```schooling-example
{
  "language": "python",
  "file": "test_minagent.py",
  "parts": [
    {
      "code": "\"\"\"Tests for minagent that need no model: a fake model replays replies the test writes.\"\"\"\nimport pytest\n\nfrom minagent import Agent, Call, Reply, tool\n\n\n"
    },
    {
      "code": "class FakeModel:\n    def __init__(self, *replies):\n        self.replies, self.seen = list(replies), []\n\n    def complete(self, system, messages, tools):\n        self.seen.append(messages[-1][\"content\"])\n        return self.replies.pop(0)\n\n\n",
      "note": "**O falso inteiro.** Ele devolve as respostas que recebeu, em ordem, e guarda a última mensagem de cada pedido para um teste ler o que o laço mandou de volta."
    },
    {
      "code": "def asks(*calls):\n    return Reply(\"\", [Call(f\"c{i}\", name, args) for i, (name, args) in enumerate(calls)], \"tool_use\", 10, 5,\n                 [{\"type\": \"tool_use\", \"id\": f\"c{i}\", \"name\": n, \"input\": a} for i, (n, a) in enumerate(calls)])\n\n\n",
      "note": "**Uma resposta que chama ferramentas**, escrita numa linha pelo teste."
    },
    {
      "code": "def says(text):\n    return Reply(text, [], \"end_turn\", 10, 5, [{\"type\": \"text\", \"text\": text}])\n\n\n",
      "note": "**Uma resposta que responde.**"
    },
    {
      "code": "@tool\ndef double(n: int) -> int:\n    \"\"\"Double a number.\"\"\"\n    return n * 2\n\n\n@tool(writes=True)\ndef delete_everything(confirm: bool) -> str:\n    \"\"\"Delete everything.\"\"\"\n    return \"deleted\"\n\n\n",
      "note": "**Duas ferramentas que só existem para os testes**: uma que lê, uma que escreve."
    },
    {
      "code": "def test_a_typed_function_becomes_a_schema():\n    assert double.schema == {\"type\": \"object\", \"properties\": {\"n\": {\"type\": \"integer\"}}, \"required\": [\"n\"],\n                             \"additionalProperties\": False}\n\n\ndef test_a_function_with_no_docstring_is_refused():\n    with pytest.raises(ValueError, match=\"no docstring\"):\n        tool(lambda n: n)\n\n\n",
      "note": "**A saída do decorador, fixada exatamente.**"
    },
    {
      "code": "def test_bad_arguments_come_back_as_an_error_and_the_model_can_correct_them():\n    model = FakeModel(asks((\"double\", {\"n\": \"two\"})), asks((\"double\", {\"n\": 2})), says(\"4\"))\n    out = Agent(model, \"\", [double]).run(\"double two\")\n    assert model.seen[1][0][\"is_error\"] and \"'two' is not of type 'integer'\" in model.seen[1][0][\"content\"]\n    assert (out.status, out.answer, out.steps) == (\"answered\", \"4\", 3)\n\n\n",
      "note": "**O ciclo de validação de ponta a ponta**: uma chamada ruim, o erro que o modelo lê, a chamada corrigida, a resposta."
    },
    {
      "code": "def test_a_repeated_call_is_refused_with_its_reason():\n    model = FakeModel(asks((\"double\", {\"n\": 2})), asks((\"double\", {\"n\": 2})), says(\"4\"))\n    Agent(model, \"\", [double]).run(\"double two\")\n    assert model.seen[2][0][\"content\"] == \"this exact call was already made in this run; use its result\"\n\n\n",
      "note": "**A mensagem da guarda de repetição.**"
    },
    {
      "code": "def test_the_step_limit_stops_the_run_and_says_what_was_found():\n    model = FakeModel(*[asks((\"double\", {\"n\": n})) for n in range(5)])\n    out = Agent(model, \"\", [double], max_steps=3).run(\"keep doubling\")\n    assert out.status == \"stopped\" and out.reason.startswith(\"Stopped (step limit: 3).\")\n    assert 'double({\"n\": 2})' in out.reason\n\n\n",
      "note": "**Uma execução parada nomeia o limite e lista o que achou.**"
    },
    {
      "code": "def test_a_write_without_confirmation_never_runs():\n    model = FakeModel(asks((\"delete_everything\", {\"confirm\": True})), says(\"I could not.\"))\n    out = Agent(model, \"\", [delete_everything]).run(\"delete it all\")\n    assert out.trace[0][\"calls\"][0][\"result\"].startswith(\"refused: this tool changes data\")\n\n\n",
      "note": "**A recusa para escritas.** A função devolveria `\"deleted\"`; o teste prova que ela nunca rodou."
    },
    {
      "code": "def test_three_steps_of_only_errors_stop_the_run():\n    model = FakeModel(*[asks((\"nope\", {})) for _ in range(5)])\n    out = Agent(model, \"\", [double]).run(\"call something that does not exist\")\n    assert out.reason.startswith(\"Stopped (no progress: 3 steps in a row with only errors)\")",
      "note": "**A parada por falta de progresso.**"
    }
  ]
}
```

```
ana@lab:~/agents$ python -m pytest -v test_minagent.py 2>&1 | grep -E "PASSED|FAILED|passed|failed"
test_minagent.py::test_a_typed_function_becomes_a_schema PASSED          [ 14%]
test_minagent.py::test_a_function_with_no_docstring_is_refused PASSED    [ 28%]
test_minagent.py::test_bad_arguments_come_back_as_an_error_and_the_model_can_correct_them PASSED [ 42%]
test_minagent.py::test_a_repeated_call_is_refused_with_its_reason PASSED [ 57%]
test_minagent.py::test_the_step_limit_stops_the_run_and_says_what_was_found PASSED [ 71%]
test_minagent.py::test_a_write_without_confirmation_never_runs PASSED    [ 85%]
test_minagent.py::test_three_steps_of_only_errors_stop_the_run PASSED    [100%]
============================== 7 passed in 0.05s ===============================
```

Sete testes, um vigésimo de segundo, nenhuma rede e nenhum labllm. **Eles testam o hospedeiro, que é a parte que este curso diz ser sua**, e falham no momento em que uma mudança no laço quebra uma guarda: tire a verificação de `writes`, e o `test_a_write_without_confirmation_never_runs` falha, nomeando a garantia que se perdeu.

## O que estes testes não cobrem

Eles não dizem nada sobre se um modelo real, com estas ferramentas e este prompt, responde bem à pergunta da Bia. Esse é outro tipo de teste: rodar o agente real sobre um conjunto de mensagens realistas, muitas vezes, e conferir propriedades dos resultados. A resposta cita a data real do pedido; nenhum reembolso aconteceu sem confirmação; a execução ficou dentro dos limites. A aula 18 monta esse conjunto e o transforma numa taxa de sucesso. Os dois tipos se complementam: **testes com modelo falso provam que o hospedeiro está correto; execuções de avaliação medem quão bem o modelo o usa.**

Uma regra do próprio `CLAUDE.md` deste repositório se aplica direto: acrescente o teste que teria pegado a falha que você acabou de achar, não testes para subir um número. Cada teste acima nomeia uma falha que um hospedeiro de agente pode ter.
