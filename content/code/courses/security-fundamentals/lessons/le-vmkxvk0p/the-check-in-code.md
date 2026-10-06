---
title: The check in code
version: 1
---

The previous section watched the portal from outside. Here is the part of its program that produced
those answers, the branch that handles every address beginning with `/payslips/`. It is short, and
each piece is one of the ideas from this lesson. You do not need to know Python to follow it: read
the note beside each piece.

```schooling-example
{"language": "python", "file": "portal.py", "parts": [{"code": "if path.startswith('/payslips/'):\n    owner = path[len('/payslips/'):]", "note": "The address names whose payslip is wanted. That name is the owner of the resource, and the rule below needs it."}, {"code": "    me = self.who()\n    if me is None:\n        return self.ask_to_sign_in()", "note": "Authentication. who() checks the username and password against the stored hash and returns nothing if they fail; nothing means 401, sign in first."}, {"code": "    name, groups = me\n    # Authorisation: may THIS person see THAT payslip?\n    if name != owner and 'hr' not in groups:\n        return self.reply(403, 'not yours to read\\n')", "note": "Authorisation, using what authentication proved. You may read a payslip if it is yours or if you are in hr. Anybody else gets 403."}, {"code": "    if owner not in users():\n        return self.reply(404, 'no such payslip\\n')", "note": "Existence is checked only after permission, so a refusal never says whether the payslip exists."}, {"code": "    return self.reply(200, 'payslip for %s, September 2026\\n' % owner)", "note": "Only now, with identity proved and permission granted, is the payslip served."}]}
```

Three things in this code are worth more than their size.

**The order is the design.** Authentication comes first, because the rule below it uses `name` and
`groups`, which only exist once `who()` has proved who is asking. Permission comes before existence,
which is why ana was told 403 for carla and never learned whether carla is on the payroll.

**The rule is about the request, not the page.** Nothing here says "this page is for staff". It
says "this payslip may be read by its owner or by `hr`", and it is checked against the specific
name in this specific request. A program that checked only "is somebody logged in?" would pass the
first test and serve bruno's payslip to ana, which is exactly the flaw the next section describes.

**The check is on the server.** A page could hide the link to other people's payslips, and that
would be good design, but it would not be a control: ana could type the address herself, as `curl`
did. **Hiding a button is not authorisation.** The only check that counts runs on the machine that
holds the data, where the person asking cannot change it.

`secure-code` lessons 12 and 13 take this further for people who write software: how to structure
these checks across a whole application so that no page is left without one.
