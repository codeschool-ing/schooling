"""judge.py: a model asked to grade one reply on one criterion, with the call traced and priced like any other.

    import judge
    verdict = judge.grade("relevance", question, reply, sources)   # {"score", "verdict", "reason"}

The judge here is judge-1, the lab's stand-in, which grades by embedding
similarity by rules written at the top of lab/labobs.py. The prompt is the one
a team would send a real model; only the model behind it is the lab's.
"""
import json

from openai import OpenAI

from telemetry import span

MODEL = "judge-1"
SYSTEM = """You grade replies written by Marginalia's help assistant to its customers.
Criterion: {criterion}
{rubric}
Reply with a JSON object and nothing else: {{"score": a number from 0 to 1, "verdict": "pass" or "fail", "reason": one sentence}}."""
RUBRIC = {
    "faithfulness": "Is every statement in the reply supported by the sources? A refusal states nothing and passes.",
    "relevance": "Does the reply address the question the customer asked?",
    "correctness": "Does the reply give the same answer as the expected one?",
}
client = OpenAI(max_retries=2, timeout=20)


def grade(criterion, question, reply, sources=(), expected=None):
    numbered = "\n".join(f"[{n}] {s['id']}\n{s['text']}" for n, s in enumerate(sources, 1))
    user = f"<question>{question}</question>\n<reply>{reply}</reply>\n<sources>\n{numbered}\n</sources>"
    if expected is not None:
        user += f"\n<expected>{expected}</expected>"
    with span(f"chat {MODEL}", **{"gen_ai.operation.name": "chat", "gen_ai.request.model": MODEL,
                                   "app.criterion": criterion}) as s:
        r = client.chat.completions.create(model=MODEL, response_format={"type": "json_object"}, messages=[
            {"role": "system", "content": SYSTEM.format(criterion=criterion, rubric=RUBRIC[criterion])},
            {"role": "user", "content": user}])
        s.set_attribute("gen_ai.response.model", r.model)
        s.set_attribute("gen_ai.usage.input_tokens", r.usage.prompt_tokens)
        s.set_attribute("gen_ai.usage.output_tokens", r.usage.completion_tokens)
        verdict = json.loads(r.choices[0].message.content)
        s.set_attribute("app.verdict", verdict["verdict"])
    return verdict
