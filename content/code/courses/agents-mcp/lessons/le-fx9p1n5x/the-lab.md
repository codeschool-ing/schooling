---
title: The lab this course runs in
version: 1
---

Every transcript in this course was recorded on one Linux machine built by `lab.sh`, which sits beside `course.json`. It is the same kind of lab `embeddings-vectors` uses, and it reuses that course's help centre, books and embedding model rather than building a second copy. Build it once:

```sh
sudo bash lab.sh up
```

It creates the user `ana`, a Python virtual environment in `/opt/agents` with every library the lessons import (pinned in the script), the working directory `~/agents`, and labllm, the model provider the programs talk to. Each lesson's `captures.sh` starts with `lab.sh reset`, which rebuilds `~/agents` from nothing, so every transcript starts from the same state.

```
ana@lab:~/agents$ curl -s http://127.0.0.1:8600/; echo
{"labllm": "a stand-in provider; see lab/labllm.py", "models": ["scripted-1", "scripted-mini"]}
ana@lab:~/agents$ ls data
books.jsonl
help.jsonl
shop.db
ana@lab:~/agents$ du -sh /opt/agents/share /opt/agents/lib
113M	/opt/agents/share
634M	/opt/agents/lib
ana@lab:~/agents$ du -sh /opt/agents/lib/python3.11/site-packages/claude_agent_sdk
232M	/opt/agents/lib/python3.11/site-packages/claude_agent_sdk
ana@lab:~/agents$ python -c "import shop; print(shop.get_order(\"M-1042\"))"
{'id': 'M-1042', 'customer_id': 'c-101', 'placed_on': '2026-09-20', 'status': 'delivered', 'delivered_on': '2026-09-24', 'shipping': 490, 'tracking': 'BR5512340002', 'lines': [{'book_id': 'b39', 'quantity': 1, 'cents': 2990}], 'total': 3480, 'refunded': 0}
```

`~/agents/data` holds Marginalia's help centre and catalogue, copied from `embeddings-vectors`, and `shop.db`, the orders. `shop.py` turns those files into plain functions (`get_order`, `get_customer`, `get_book`, `search_help`, `refund`) that each lesson wraps as tools. The lab's calendar stops on 6 October 2026, so an order's age comes out the same on every run.

## The model is a stand-in, and the course says so every time

**No model provider's API was reachable from the machine this course was recorded on**, and an API key is a bill a course cannot hand out. So labllm answers instead. It speaks the wire formats of three real APIs (Anthropic's Messages, OpenAI's Chat Completions and Google's Gemini), tool calls included, closely enough that the providers' SDKs and the three agent SDKs of lessons 8 to 10 talk to it unmodified.

**What it does not have is a model.** Its replies are chosen from rules the course wrote, in `lab/scripted/`: a rule names a conversation by a phrase in the user's message and the step it has reached, and gives the reply, which may be text, a tool call or both. **So whenever a transcript shows which tool an agent chose, or what it said at the end, those are the course's words.** Every lesson says so where it happens. What is real is everything else: the SDKs, the loops, the tools and their results, the schemas and their validation, the MCP servers, the errors and the limits. That is the part this course is about, and the part that would stay the same with a real model behind it.

## Three ways to have the machine

| path | what it takes | |
|---|---|---|
| **a Linux machine where you have root**, Ubuntu 24.04 | Python 3.11, Node.js 22, `iproute2` and `openssl`; about 750 MB in `/opt/agents` | **recommended**, and the one every transcript was recorded on |
| a virtual machine running Ubuntu 24.04 | the same, plus the VM's own memory and disk: give it 4 GB of memory and 15 GB of disk | for Windows and macOS |
| a cloud development environment that gives you root | the same packages | not tried by this course |

The 750 MB is the `du` line in the transcript above: 113 MB of shared files and 634 MB of libraries. The last `du` is one of those libraries on its own, 232 MB of it: the Claude Agent SDK, which bundles the Claude Code command-line program that lesson 9 drives. The build needs the network once, to fetch the libraries from PyPI and npm and the embedding model from Chroma's bucket; after that the lab reaches nothing outside the machine.
