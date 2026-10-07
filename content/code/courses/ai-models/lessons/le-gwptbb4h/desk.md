---
title: ana's desk, built on your machine
version: 1
---

Every lesson in this course follows one person. **ana** runs the support desk of Lantern Books, a
small online bookshop, and has to choose the model that will sort the shop's e-mail. Her project is
a folder called `desk`, and the lessons are what she types at it. You build the same folder on your
own machine now, and every program the course shows goes into it.

## A folder and a Python of its own

```
ana@desk:~$ mkdir -p desk/cases desk/prompts && cd desk
ana@desk:~/desk$ python3 -m venv .venv && . .venv/bin/activate
ana@desk:~/desk$ pip install -q openai==3.24.0 anthropic==1.11.0 ollama==0.6.3 google-genai==2.28.0 mistralai==3.0.0 huggingface_hub==2.1.1
ana@desk:~/desk$ pip list | grep -iE '^(openai|anthropic|ollama|google-genai|mistralai|huggingface)'
anthropic                          1.11.0
google-genai                       2.28.0
huggingface_hub                    2.1.1
mistralai                          3.0.0
ollama                             0.6.3
openai                             3.24.0
```

`.venv` is a **virtual environment**: a Python with its own libraries, inside the project, so
nothing installed here touches the rest of your computer. The `python` course builds one in lesson
18; the short version is that `. .venv/bin/activate` switches to it, and you run it again in every
new terminal before you work on the desk. On Windows the line is `.venv\Scripts\activate`.

`-q` keeps `pip` quiet, so no output is success, and `pip list` shows what arrived. The six
libraries are the official ones from each provider the course reaches, at the versions every
transcript was taken with. Install those versions, not the latest: a newer library is usually fine
and occasionally prints something different, and then the lesson and your screen disagree for no
reason you can see.

## Where the requests go: `desk.env`

Most programs in the course build their client with no arguments, `OpenAI()` or `Anthropic()`,
and the library then reads two settings from the environment: the address to send to and the key to
send with it. `desk.env` points both libraries at Ollama, on your own computer:

```sh
# Where the SDKs send their requests: Ollama, on this computer.
# The keys are placeholders; the libraries refuse to start without one, and Ollama ignores it.
export OPENAI_BASE_URL=http://127.0.0.1:11434/v1
export OPENAI_API_KEY=ollama
export ANTHROPIC_BASE_URL=http://127.0.0.1:11434
export ANTHROPIC_API_KEY=ollama
```

Save it as `~/desk/desk.env` and load it with `. ./desk.env`, in the same terminal, after the
activate line. **Ollama answers in OpenAI's shape and in Anthropic's**, which is why the same two
libraries a paying customer uses work here unchanged. With a paid key of your own, this file is
what changes, to the provider's address and your key, and each program then names the provider's
model in place of `llama3.2:3b`.

## The two prompts

Ana's first job is sorting: every e-mail gets one of five labels, so it reaches the right person.
`prompts/triage.txt`:

```
You sort the e-mail of Lantern Books, an online bookshop.
Answer with exactly one label and nothing else:
order-status, refund, address-change, product-question, other.
```

Her second is pulling the order number out of an e-mail, so the reply can look it up.
`prompts/extract.txt`:

```
Read the customer's e-mail and answer with JSON only, in this shape:
{"order": "LB-12345"}
Use null for "order" when the e-mail names no order.
```

## The forty cases

Forty e-mails from the shop's inbox, with names and addresses removed, each with the label a person
gave it and the order number it names, or `null`. Lesson 5 is about why they are written down and
how to use them; every lesson before it borrows one or two. Save them as `cases/triage.jsonl`, one
e-mail per line:

```json
{"id": "c01", "text": "Hi, I ordered two books on Monday (order LB-20417) and the tracking page still says 'preparing'. When will it ship?", "label": "order-status", "order": "LB-20417"}
{"id": "c02", "text": "The copy of 'The Salt Road' I received has twenty pages printed upside down. I'd like my money back, please. Order LB-20388.", "label": "refund", "order": "LB-20388"}
{"id": "c03", "text": "I moved last week. Can you send order LB-20452 to Rua das Flores 120, apt 31 instead of my old address?", "label": "address-change", "order": "LB-20452"}
{"id": "c04", "text": "Is the hardback edition of 'Nine Lighthouses' the same translation as the paperback?", "label": "product-question", "order": null}
{"id": "c05", "text": "Do you have a physical shop I can visit in Curitiba?", "label": "other", "order": null}
{"id": "c06", "text": "Order LB-20501 was marked delivered yesterday but nothing arrived. The doorman says no parcel came.", "label": "order-status", "order": "LB-20501"}
{"id": "c07", "text": "I cancelled LB-20399 within an hour of placing it and I was still charged. Please refund the charge.", "label": "refund", "order": "LB-20399"}
{"id": "c08", "text": "Please change the delivery address on LB-20460: the building number is 48, not 84.", "label": "address-change", "order": "LB-20460"}
{"id": "c09", "text": "Does the illustrated edition of 'Small Hours' come with the fold-out map?", "label": "product-question", "order": null}
{"id": "c10", "text": "Can I get an invoice with my company's tax number for order LB-20377?", "label": "other", "order": "LB-20377"}
{"id": "c11", "text": "It has been twelve days since I ordered (LB-20329). Is something wrong?", "label": "order-status", "order": "LB-20329"}
{"id": "c12", "text": "The book arrived soaked from the rain and the cover is ruined. I don't want a replacement, just the refund. LB-20415", "label": "refund", "order": "LB-20415"}
{"id": "c13", "text": "My order LB-20470 is going to my office but I'm on holiday from tomorrow. Could it go to my home address instead? Rua Aurora 9.", "label": "address-change", "order": "LB-20470"}
{"id": "c14", "text": "How many pages does 'The Quiet Engineer' have? The listing doesn't say.", "label": "product-question", "order": null}
{"id": "c15", "text": "I'd like to unsubscribe from your newsletter.", "label": "other", "order": null}
{"id": "c16", "text": "Hello, where is my parcel? LB-20488", "label": "order-status", "order": "LB-20488"}
{"id": "c17", "text": "I returned order LB-20301 three weeks ago and haven't seen the money. The return was accepted on the 2nd.", "label": "refund", "order": "LB-20301"}
{"id": "c18", "text": "I typed my postcode wrong on LB-20493. It should be 80010-000. Can you fix it before it ships?", "label": "address-change", "order": "LB-20493"}
{"id": "c19", "text": "Is 'Winter Orchard' suitable for a ten-year-old reader?", "label": "product-question", "order": null}
{"id": "c20", "text": "Your courier left a card saying they will try again tomorrow, but I won't be home. Order LB-20466. Can they leave it with a neighbour?", "label": "order-status", "order": "LB-20466"}
{"id": "c21", "text": "I was charged twice for LB-20440. One of the charges needs to go back to my card.", "label": "refund", "order": "LB-20440"}
{"id": "c22", "text": "Can I collect LB-20481 from the warehouse instead of having it delivered?", "label": "address-change", "order": "LB-20481"}
{"id": "c23", "text": "Will 'The Salt Road' be published in Portuguese?", "label": "product-question", "order": null}
{"id": "c24", "text": "I'm a teacher and would like to order thirty copies. Do you give discounts to schools?", "label": "other", "order": null}
{"id": "c25", "text": "The tracking number you sent for LB-20455 doesn't work on the courier's site.", "label": "order-status", "order": "LB-20455"}
{"id": "c26", "text": "I ordered the hardback but you sent the paperback (LB-20431). I'll keep it if you refund the difference.", "label": "refund", "order": "LB-20431"}
{"id": "c27", "text": "Please deliver LB-20497 to the reception desk of my building rather than to my door.", "label": "address-change", "order": "LB-20497"}
{"id": "c28", "text": "Are the e-book and the printed book sold together, or separately?", "label": "product-question", "order": null}
{"id": "c29", "text": "I forgot my password and the reset email never comes.", "label": "other", "order": null}
{"id": "c30", "text": "Order LB-20412 shows as shipped, but the courier says they have not received it from you.", "label": "order-status", "order": "LB-20412"}
{"id": "c31", "text": "The gift voucher I bought (LB-20366) was never sent to my friend, and her birthday has passed. I'd rather have the money back.", "label": "refund", "order": "LB-20366"}
{"id": "c32", "text": "Could you add the apartment number 1204 to LB-20478? I left it out.", "label": "address-change", "order": "LB-20478"}
{"id": "c33", "text": "Which edition of 'Nine Lighthouses' has the larger print?", "label": "product-question", "order": null}
{"id": "c34", "text": "I want to complain about the courier, who was rude to my mother.", "label": "other", "order": null}
{"id": "c35", "text": "Has LB-20490 left the warehouse yet? I need it by Friday.", "label": "order-status", "order": "LB-20490"}
{"id": "c36", "text": "The second volume in LB-20422 is missing. Please refund it, I found it elsewhere.", "label": "refund", "order": "LB-20422"}
{"id": "c37", "text": "I'm moving next month. Is it possible to change the address on my standing order for the quarterly box?", "label": "address-change", "order": null}
{"id": "c38", "text": "Do you ship to Portugal, and how long does it take?", "label": "product-question", "order": null}
{"id": "c39", "text": "Please delete my account and everything you hold about me.", "label": "other", "order": null}
{"id": "c40", "text": "The parcel for LB-20474 came back to you as undeliverable. What happens now?", "label": "order-status", "order": "LB-20474"}
```

## Check that it all answers

`check.py` sends the first case to the model, with the sorting prompt, through the OpenAI library
and `desk.env`:

```python
import json

from openai import OpenAI

client = OpenAI()  # the address and the key come from desk.env
prompt = open("prompts/triage.txt").read()
case = json.loads(open("cases/triage.jsonl").readline())

r = client.chat.completions.create(model="llama3.2:3b", temperature=0, messages=[
    {"role": "system", "content": prompt}, {"role": "user", "content": case["text"]}])
print(case["id"], r.model, r.choices[0].message.content)
```

```
ana@desk:~/desk$ wc -l cases/triage.jsonl
40 cases/triage.jsonl
ana@desk:~/desk$ python check.py
c01 llama3.2:3b order-status
```

One line back means every piece is in place: the server, the model, the virtual environment, the
two files and the address in `desk.env`. If you got something else, the next section is where it is.
