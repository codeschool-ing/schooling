---
title: Delegation instead of a password
version: 1
---

The bookshop wants a reading app that shows the books you bought, and the list lives behind the
shop's API. **The first way anybody builds this is the wrong one: the app asks for your password
to the shop and signs in as you.** It works on the first day, and everything about it is a
liability after that.

A password handed to an app gives it four things you never meant to give:

| what the app receives | what you wanted it to have |
|---|---|
| everything your account can do, changing the password included | one list, to read |
| access until you change the password, which also cuts off every other app you gave it to | access you can end for this app alone |
| your password, stored on a server you have never seen | nothing that works anywhere else |
| an identity the shop cannot tell apart from yours | a log that says which app did what |

**OAuth 2.0 replaces the password with delegation.** The app sends you to the shop. You sign in
there, on the shop's own page, and the shop asks whether this app may read your purchases. If you
say yes, the app receives an **access token**: a string that opens what you agreed to and nothing
else, for a few minutes, and that the shop can stop honouring without touching your password. The
app never sees the password at all. OAuth 2.0 is RFC 6749, published in 2012, and the "Connect
your account" buttons you have pressed are almost all built on it.

Lesson 7's bearer token was made by the API for its own use. Here three parties are involved: one
service issues the token, another accepts it, and a person agreed to it in between.

## The four roles

OAuth names four parties, and every flow in this lesson is a conversation between some of them:

| role | in the bookshop | in this lesson's lab |
|---|---|---|
| **resource owner** | you, whose purchases these are | the one user `idp.py` knows, Ana |
| **client** | the reading app | you, typing `curl`, registered as `shelf-web` |
| **authorization server** | the shop's sign-in service, which issues tokens | `idp.py`'s `/authorize` and `/token` |
| **resource server** | the shop's API, which accepts tokens | `idp.py`'s `/books/stock` and `/userinfo` |

**"Client" means the app, never the browser.** The browser carries messages between you and the
other three, and it is the party OAuth trusts least, because whatever passes through it can be
read by other things running there: an extension, the history, a log.

The authorization server and the resource server are two jobs. In a company they are two
programs, often owned by two teams: the API never sees a password and the sign-in service never
serves a book. This lesson's lab does both in one Python file to keep it to one file, and its
resource-server half checks a token the way a separate API would, with the authorization server's
public key and without asking it anything.

**For a defender the gain is where the password lives.** It stays in one program, the
authorization server, which is the only one that has to be good at protecting passwords. Every
other program handles tokens, which are narrower, expire in minutes and can be withdrawn from one
app without touching the others.
