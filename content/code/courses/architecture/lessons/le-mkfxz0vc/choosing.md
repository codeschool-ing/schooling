---
title: Choosing
version: 1
---

| the need | start with | why |
| --- | --- | --- |
| a dashboard refreshed every minute, a few viewers | polling | nothing to build or run; the waste is small |
| the page should change when something happens on the server | Server-Sent Events | plain HTTP, reconnects and resumes on its own |
| messages in both directions, many per second | WebSocket | the only one built for it |
| networks that block everything above, or very old clients | long polling | works wherever HTTP does |
| one server telling another | a webhook, or a broker | neither side is a browser |

For Quitanda, the order-status page and the "only 2 left" badge are **SSE**: the server has news, the
page listens, and an order page left open on a phone survives the train's tunnels. A future support chat
would be a **WebSocket**. And whichever is used, with more than one instance a **backplane** goes in on
the same day, because the failure it prevents is silent.

When you are done, stop the lab:

```sh
docker compose down
```
