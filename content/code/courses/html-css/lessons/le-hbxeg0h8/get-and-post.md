---
title: GET or POST
version: 1
---

`method` decides where the form's data goes in the request, and the choice follows from what the request does, not from taste. `web-fundamentals` lesson 6 described the two methods; this is what they mean for a form.

**`get` puts the data in the address.** The search earlier in this lesson sent `GET /search?q=Clarice+Lispector`. Everything is visible in the address bar, can be bookmarked, shared, and pressed again with the back button. That is right for a request that **only reads**: a search, a filter, a page of results. Sending it twice does no harm.

**`post` puts the data in the body of the request.** The order form sent:

```
ana@laptop:~/site$ probe order.html fill '#name' 'Ana Souza' fill '#email' ana@example.com fill '#cep' 05422-000 fill '#copies' 2 fill '#title' 'Vidas Secas' send button
POST /order
Content-Type: application/x-www-form-urlencoded
name=Ana+Souza&email=ana%40example.com&cep=05422-000&copies=2&title=Vidas+Secas
```

The address is just `/order`, and the data travels after the headers, encoded the same way, `name=Ana+Souza&…`, with a `Content-Type` saying so. That is right for a request that **changes something**: placing an order, subscribing, posting a comment. A browser that is asked to send a POST again, by a reload or the back button, warns before doing it, because sending an order twice is a second order.

## Two rules that follow

**Anything private goes by POST.** An address bar ends up in the browser's history, in server logs and sometimes in the address the next site receives as the page somebody came from. A password or a personal document number in a query string has been written down in all of those places. POST keeps it out of the address; HTTPS, which `web-fundamentals` lesson 6 covered, keeps it out of everybody else's hands on the way.

**A file upload needs `method="post"` and `enctype="multipart/form-data"`.** The default encoding, the one in both requests above, cannot carry a file. With `<input type="file">` in the form and that `enctype`, the body is split into parts, one per field, and the file goes in its own part.
