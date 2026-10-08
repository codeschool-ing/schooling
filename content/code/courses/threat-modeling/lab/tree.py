#!/usr/bin/env python3
"""An attack tree for one goal, and what controls do to the cheapest way to reach it."""
import sys

NEVER = float("inf")

# A node is ("OR" or "AND", name, children), or (days, name) for a leaf.
# Days are the team's estimate of an outsider's effort, not a measurement.
TREE = ("OR", "Mark a booking paid without paying", [
    ("AND", "Forge the gateway's webhook", [
        (1, "Learn the webhook's address"),
        (1, "Send a request the portal accepts"),
    ]),
    ("AND", "Change the status in the staff console", [
        (5, "Take over a staff account"),
        (2, "Reach the console"),
    ]),
    ("AND", "Change the row in the database", [
        (10, "Take over the reminder worker"),
        (1, "Use its owner account"),
    ]),
])

# Each control makes one leaf impossible.
CONTROLS = {
    "signature": "Send a request the portal accepts",
    "mfa": "Take over a staff account",
    "clinic-only": "Reach the console",
    "least-privilege": "Use its owner account",
}


def cheapest(node, blocked):
    """The attacker's cheapest cost for a node, and the leaves on that route."""
    if not isinstance(node[0], str):
        days, name = node
        return (NEVER if name in blocked else days), [name]
    kind, _, children = node
    routes = [cheapest(child, blocked) for child in children]
    if kind == "OR":
        return min(routes, key=lambda route: route[0])
    return sum(days for days, _ in routes), [leaf for _, leaves in routes for leaf in leaves]


chosen = sys.argv[1:]
days, leaves = cheapest(TREE, {CONTROLS[c] for c in chosen})
print("controls:", ", ".join(chosen) or "none")
if days == NEVER:
    print("cheapest: unreachable")
else:
    print(f"cheapest: {days:g} days")
    for leaf in leaves:
        print("  -", leaf)
