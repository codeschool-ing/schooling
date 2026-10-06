"""The gate between a model that proposes tool calls and the tools.

The model decides nothing here. It PROPOSES a call; this module reads the
proposal against data/tools.json and answers ALLOW, HOLD (a person must
confirm) or DENY, with the rule that decided. The scope of every call is
checked against the session, which the code knows and the model does not
get to say: a model that writes "account": "ac-0Z5Q" into a proposal has
not become that client.

THE PROPOSED CALLS IN data/proposed-calls.jsonl WERE WRITTEN BY THE COURSE.
No model proposed them; each one is there to meet a different rule.
"""


def decide(call, session, manifest, confirmed=()):
    tool = manifest["tools"].get(call["tool"])
    if tool is None:
        return "DENY", "tool %s is not granted to this agent" % call["tool"]
    args = call["args"]
    if tool.get("scope") == "session-account" and args.get("account") != session["account"]:
        return "DENY", "account %s is not the session's (%s)" % (args.get("account"), session["account"])
    if "recipients" in tool and args.get("to") not in [session["account"] if r == "session-account" else r
                                                     for r in tool["recipients"]]:
        return "DENY", "recipient %s is outside the tool's scope" % args.get("to")
    if "max_cents" in tool:
        paid = session["paid_cents"].get(args.get("job"), 0)
        if args.get("cents", 0) > paid:
            return "DENY", "refund of %d is more than the %d paid for job %s" % (
                args.get("cents", 0), paid, args.get("job"))
    if tool.get("confirm"):
        if call["id"] in confirmed:
            return "ALLOW", "confirmed by %s" % confirmed[call["id"]]
        return "HOLD", "%s needs a person to confirm: %s" % (call["tool"], tool["confirm"])
    return "ALLOW", "%s, %s" % (tool["access"], "within scope")


def run(calls, session, manifest, confirmed=None):
    confirmed = confirmed or {}
    budget = manifest["calls_per_conversation"]
    out = []
    for n, call in enumerate(calls, 1):
        if n > budget:
            out.append((call, "DENY", "budget of %d calls per conversation is spent" % budget))
            continue
        decision, why = decide(call, session, manifest, confirmed)
        out.append((call, decision, why))
    return out
