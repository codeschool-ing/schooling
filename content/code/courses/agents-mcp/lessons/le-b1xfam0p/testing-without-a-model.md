---
title: Tests that need no model
version: 1
---

An agent's behaviour depends on a model, but most of the code in `minagent` does not: validation, refusals, limits, the trace and the outcome are ordinary Python, and they can be tested like ordinary Python. The adapter seam from section 04 is what makes that possible: a test hands the agent a model that replies with exactly what the test wants.

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
      "note": "**The whole fake.** It returns the replies it was given, in order, and remembers the last message of each request so a test can read what the loop sent back."
    },
    {
      "code": "def asks(*calls):\n    return Reply(\"\", [Call(f\"c{i}\", name, args) for i, (name, args) in enumerate(calls)], \"tool_use\", 10, 5,\n                 [{\"type\": \"tool_use\", \"id\": f\"c{i}\", \"name\": n, \"input\": a} for i, (n, a) in enumerate(calls)])\n\n\n",
      "note": "**A reply that calls tools**, written in one line by the test."
    },
    {
      "code": "def says(text):\n    return Reply(text, [], \"end_turn\", 10, 5, [{\"type\": \"text\", \"text\": text}])\n\n\n",
      "note": "**A reply that answers.**"
    },
    {
      "code": "@tool\ndef double(n: int) -> int:\n    \"\"\"Double a number.\"\"\"\n    return n * 2\n\n\n@tool(writes=True)\ndef delete_everything(confirm: bool) -> str:\n    \"\"\"Delete everything.\"\"\"\n    return \"deleted\"\n\n\n",
      "note": "**Two tools that exist only for the tests**: one that reads, one that writes."
    },
    {
      "code": "def test_a_typed_function_becomes_a_schema():\n    assert double.schema == {\"type\": \"object\", \"properties\": {\"n\": {\"type\": \"integer\"}}, \"required\": [\"n\"],\n                             \"additionalProperties\": False}\n\n\ndef test_a_function_with_no_docstring_is_refused():\n    with pytest.raises(ValueError, match=\"no docstring\"):\n        tool(lambda n: n)\n\n\n",
      "note": "**The decorator's output, pinned exactly.**"
    },
    {
      "code": "def test_bad_arguments_come_back_as_an_error_and_the_model_can_correct_them():\n    model = FakeModel(asks((\"double\", {\"n\": \"two\"})), asks((\"double\", {\"n\": 2})), says(\"4\"))\n    out = Agent(model, \"\", [double]).run(\"double two\")\n    assert model.seen[1][0][\"is_error\"] and \"'two' is not of type 'integer'\" in model.seen[1][0][\"content\"]\n    assert (out.status, out.answer, out.steps) == (\"answered\", \"4\", 3)\n\n\n",
      "note": "**The validation loop end to end**: a bad call, the error the model reads, the corrected call, the answer."
    },
    {
      "code": "def test_a_repeated_call_is_refused_with_its_reason():\n    model = FakeModel(asks((\"double\", {\"n\": 2})), asks((\"double\", {\"n\": 2})), says(\"4\"))\n    Agent(model, \"\", [double]).run(\"double two\")\n    assert model.seen[2][0][\"content\"] == \"this exact call was already made in this run; use its result\"\n\n\n",
      "note": "**The repeat guard's message.**"
    },
    {
      "code": "def test_the_step_limit_stops_the_run_and_says_what_was_found():\n    model = FakeModel(*[asks((\"double\", {\"n\": n})) for n in range(5)])\n    out = Agent(model, \"\", [double], max_steps=3).run(\"keep doubling\")\n    assert out.status == \"stopped\" and out.reason.startswith(\"Stopped (step limit: 3).\")\n    assert 'double({\"n\": 2})' in out.reason\n\n\n",
      "note": "**A stopped run names its limit and lists what it found.**"
    },
    {
      "code": "def test_a_write_without_confirmation_never_runs():\n    model = FakeModel(asks((\"delete_everything\", {\"confirm\": True})), says(\"I could not.\"))\n    out = Agent(model, \"\", [delete_everything]).run(\"delete it all\")\n    assert out.trace[0][\"calls\"][0][\"result\"].startswith(\"refused: this tool changes data\")\n\n\n",
      "note": "**The refusal for writes.** The function would return `\"deleted\"`; the test proves it never ran."
    },
    {
      "code": "def test_three_steps_of_only_errors_stop_the_run():\n    model = FakeModel(*[asks((\"nope\", {})) for _ in range(5)])\n    out = Agent(model, \"\", [double]).run(\"call something that does not exist\")\n    assert out.reason.startswith(\"Stopped (no progress: 3 steps in a row with only errors)\")",
      "note": "**The no-progress stop.**"
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

Seven tests, a twentieth of a second, no network and no labllm. **They test the host, which is the part this course says is yours**, and they fail the moment a change to the loop breaks a guard: drop the `writes` check, and `test_a_write_without_confirmation_never_runs` fails, naming the guarantee that was lost.

## What these tests do not cover

They say nothing about whether a real model, given these tools and this prompt, answers Bia's question well. That is a different kind of test: run the real agent over a set of realistic messages, many times, and check properties of the outcomes. The answer cites the order's real date; no refund happened without confirmation; the run stayed inside its limits. Lesson 18 builds that set and turns it into a success rate. The two kinds complement each other: **fake-model tests prove the host is correct; evaluation runs measure how well the model uses it.**

One rule from this repository's own `CLAUDE.md` applies directly: add the test that would have caught the failure you just found, not tests to raise a number. Each test above names a failure an agent host can have.
