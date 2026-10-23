---
title: Who is asking, and how the server remembers
version: 1
---

**HTTP has no memory: every request arrives on its own, and a server that wants to know who sent it
has to be told, every time.** Authentication is the question *who is this*, answered once, at sign-in,
with something only that person has. Authorisation is the question asked on every request after
that, *may this person do this*, and it needs the answer to the first to be carried along.

How it is carried is the subject of this lesson, and there are three answers in use:

- **A session cookie.** At sign-in the server makes up a long random id, remembers whom it belongs to,
  and gives it to the browser in a cookie. The browser sends the cookie back with every request to
  that site, and the server looks the id up. The id means nothing on its own; the meaning is in the
  server's memory.
- **A self-contained token**, usually a JWT. At sign-in the server writes down who you are and until
  when, signs it, and hands it over. On each request it checks the signature and reads the claim. It
  remembers nothing; the meaning travels inside the token.
- **Delegated identity**, OAuth 2.0 and OpenID Connect. The planner does not check a password at all:
  it sends you to somebody who already knows you, an identity provider, and receives a statement from
  them. The statement is a token, and the planner then carries the answer in one of the first two ways.

## What the front-end owns

On a site built from pages the server renders, all of this is the back-end's business. **An
application like the planner, whose page is a program running in the browser, takes part in it**: it
sends the sign-in, it decides where a token is kept, it attaches it to requests or relies on the
browser to send a cookie, and it is the code an attacker's script would run next to. The rest of
this part of the course, lessons 5 to 9, is the front-end's share of that.

The planner has had no accounts until now, and nothing in this lesson changes what it draws. It gains
a server of its own, with one account and the three answers above tried against it, so that each one
can be seen working rather than described.
