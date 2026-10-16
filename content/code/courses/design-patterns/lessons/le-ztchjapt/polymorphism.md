---
title: Polymorphism: one call, many behaviours
version: 1
---

**Polymorphism is the reason objects are worth the trouble.** It lets a piece of code call a method
without knowing which class will answer, so the code that decides *what happens* and the code that
decides *when it happens* can be written, tested and changed apart. Encapsulation keeps an
object's state honest; polymorphism is what lets you swap one object for another.

The library sends a reminder two days before a loan is due. Some members want an e-mail, some a
text message, and a few still ask for a printed slip at the desk. Written without polymorphism, the
reminder code asks which kind of member it has every time:

```python
if member.channel == "email":
    send_email(member.address, text)
elif member.channel == "sms":
    send_sms(member.phone, text)
elif member.channel == "print":
    print_slip(member.name, text)
```

That `if` has to be repeated wherever the library talks to a member, and the day a fourth channel
arrives, every copy has to be found. With polymorphism, each channel is an object that knows how to
deliver, and the reminder code only says *deliver*:

```schooling-example
{"language": "python", "file": "notices.py", "parts": [
 {"code": "# notices.py\nfrom typing import Protocol\n\n\nclass Channel(Protocol):\n    def deliver(self, text: str) -> str: ...", "note": "A `Protocol` names the method a channel must have. It is a type for readers and checkers; at run time nothing inherits from it."},
 {"code": "\n\nclass Email:\n    def __init__(self, address: str):\n        self.address = address\n\n    def deliver(self, text: str) -> str:\n        return f\"e-mail to {self.address}, subject \\\"Library\\\": {text}\"\n\n\nclass Sms:\n    def __init__(self, phone: str):\n        self.phone = phone\n\n    def deliver(self, text: str) -> str:\n        return f\"SMS to {self.phone}: {text}\"\n\n\nclass PrintedSlip:\n    def deliver(self, text: str) -> str:\n        return f\"slip for the desk: {text.upper()}\"", "note": "Three classes with nothing in common except a method called `deliver` that takes the same argument. None of them mentions `Channel`."},
 {"code": "\n\ndef remind(channels: list[Channel], title: str) -> None:\n    text = f\"'{title}' is due in two days\"\n    for channel in channels:\n        print(channel.deliver(text))", "note": "This function will never change when a channel is added. It does not know which classes exist; it knows the one method they share."},
 {"code": "\n\nif __name__ == \"__main__\":\n    remind([Email(\"bia@example.org\"), Sms(\"+55 11 5550-0142\"), PrintedSlip()],\n           \"A Hora da Estrela\")"}
]}
```

```
ana@laptop:~/patterns/oo$ python3 notices.py
e-mail to bia@example.org, subject "Library": 'A Hora da Estrela' is due in two days
SMS to +55 11 5550-0142: 'A Hora da Estrela' is due in two days
slip for the desk: 'A HORA DA ESTRELA' IS DUE IN TWO DAYS
```

One call, `channel.deliver(text)`, three behaviours. The e-mail gets a subject and the slip is in
capitals, and `remind` knows about neither.

## Three ways languages say "has this method"

Python finds the method at run time and asks nothing beforehand. That is **duck typing**: if it has
`deliver`, it is a channel. The `Protocol` above adds a description a type checker such as mypy can
hold the code to, without changing what runs. Each of the four languages of the `backend` track
says the same thing differently:

| language | how `Channel` is written | does `Email` have to name it? |
|---|---|---|
| Python | `class Channel(Protocol)`, or nothing at all | no |
| Go | `type Channel interface { Deliver(text string) string }` | no: any type with the method satisfies it |
| Java | `interface Channel { String deliver(String text); }` | yes: `class Email implements Channel` |
| TypeScript | `interface Channel { deliver(text: string): string }` | no: the shape is checked, not the name |

Go and TypeScript check the **shape**, like Python's protocol, but at compile time. Java checks the
**name**: a class with the right method that did not declare `implements Channel` is refused. Both
are polymorphism, and the design arguments in the rest of this course apply to all four.

Inheritance gives polymorphism too: a list of `Item` from the last section can hold films and books
and call `describe` on each. What this example shows is that you do not need a shared parent to get
it. That observation is most of lesson 2.
