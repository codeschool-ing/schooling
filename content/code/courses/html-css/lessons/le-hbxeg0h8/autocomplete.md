---
title: Helping the browser fill the form in
version: 1
---

Browsers remember what people type in forms, and they fill in a name, an address or a card number when they recognise a field asking for one. Whether they recognise it is up to the form. **The `autocomplete` attribute says exactly which piece of information a field wants**, from a fixed list of names:

```schooling-example
{"language": "html", "file": "delivery.html", "parts": [
 {"code": "<label for=\"fullname\">Name</label>\n<input id=\"fullname\" name=\"fullname\" autocomplete=\"name\">", "note": "`name` is the person's full name, in one field."},
 {"code": "<label for=\"mail\">Email</label>\n<input id=\"mail\" name=\"mail\" type=\"email\" autocomplete=\"email\">", "note": "The type checks the shape; `autocomplete` says which saved value goes here."},
 {"code": "<label for=\"street\">Street and number</label>\n<input id=\"street\" name=\"street\" autocomplete=\"address-line1\">", "note": "Addresses come in lines and parts: `address-line1`, `address-level2` for the city, `postal-code`."},
 {"code": "<label for=\"zip\">CEP</label>\n<input id=\"zip\" name=\"zip\" inputmode=\"numeric\" autocomplete=\"postal-code\">", "note": "Digits with a format, so text with a numeric keyboard rather than `type=\"number\"`, as section 04 said."},
 {"code": "<label for=\"code\">Code from the SMS</label>\n<input id=\"code\" name=\"code\" inputmode=\"numeric\" autocomplete=\"one-time-code\">", "note": "A phone can offer the code from the message that just arrived."}
]}
```

The `name` attributes in that form, `fullname` and `zip`, are what the server receives, and they can be anything the server expects. The `autocomplete` values are a vocabulary the browser knows, and they are not free text: `autocomplete="cep"` means nothing to any browser.

## Why it is more than a convenience

For most people autocomplete saves a few seconds. For somebody with a motor impairment typing is slow and tiring, and for somebody with a memory or learning disability recalling an address is the hard part. WCAG has a criterion, *Identify Input Purpose*, that asks for exactly this attribute on fields that collect information about the user. And for anyone on a phone it is the difference between finishing a form and leaving it.

**`autocomplete="off"` is mostly ignored for logins**, on purpose: browsers decided that stopping password managers made people choose worse passwords. For a field where a remembered value is genuinely wrong, a one-time code or a search box, `off` is still a fair request.
