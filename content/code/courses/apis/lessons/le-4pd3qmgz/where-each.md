---
title: Which one, where
version: 1
---

Three protocols, and they are not three answers to one question. **OAuth 2.0 is about access to an
API; OpenID Connect and SAML are about signing a person in.** The table puts them side by side:

| | OAuth 2.0 | OpenID Connect | SAML 2.0 |
|---|---|---|---|
| the question it answers | may this client call this API, within this scope? | who signed in to this client? | who signed in to this application? |
| what it hands over | an access token, for the API | an ID token, for the client, plus OAuth's access token | a signed XML assertion, for the application |
| format | not fixed; often a JWT | JWT | XML with an XML signature |
| how it travels | redirects, then a direct request to `/token` | the same | redirects and a form the browser posts |
| where you meet it | an app calling Google Drive, GitHub or a payment API on a user's behalf; services calling each other with client credentials | "Sign in with Google", "Sign in with Microsoft", the sign-in of most new web and phone apps | a company's staff signing in to the tools it buys, through the company's identity provider |

They also meet in one place. A company identity provider usually speaks both SAML and OpenID
Connect, and a product sold to companies tends to support both, because each customer arrives with
one or the other.

## What a first job looks like

**You will not write an authorization server, and you should not.** The work is integrating with
one that somebody else runs. That is usually a hosted identity provider, such as Auth0, Okta,
Microsoft Entra ID, Google or AWS Cognito, or Keycloak where a company runs its own; it owns the
passwords, the second factor, the consent screens and the signing keys. Your application talks to
it through a library for your language, certified where certification exists (the OpenID
Foundation lists certified ones), which runs the flow and does every check in this lesson in code
that thousands of other projects have already tested.

What is left to you is configuration and judgement, and it is where integrations go wrong. A
review of one asks these questions, each of which a section of this lesson answers:

| question | the section |
|---|---|
| Is every `redirect_uri` registered exactly, with no wildcard? | The authorization code flow |
| Does every client use PKCE with `S256`, and send and check `state`? | PKCE |
| Does each client ask for the fewest scopes it needs, and read the `scope` it was granted? | Scopes and consent |
| Does the app check the ID token's signature, `iss`, `aud`, `exp` and `nonce`, and never sign anybody in with an access token? | OpenID Connect |
| Are refresh tokens rotated, kept on a server or in the platform's store, and is reuse an alert? | Refresh tokens |
| Is each machine client's secret in a secret store, its scope minimal, one client per job? | Client credentials |
| Are the implicit and password grants switched off? | What is gone |
| Is SAML handled by a maintained library that checks audience, times and replay? | SAML |

`idp.py` was for reading. When the day comes to sign real people in, the authorization server is
somebody else's product, the checks run in somebody else's library, and your part is getting the
questions above right.
