---
title: Resources
version: 1
---

A tool is something the model asks to run. A **resource** is data a host can read: a document, a record, a file, each with a URI. Marginalia's help centre fits that well: forty articles that a host might show a person, attach to a conversation, or give the model when it is relevant.

```
ana@lab:~/agents$ python try_server.py resources 2> server.log
template: help://{article_id} text/markdown
search_help: {"result": [{"title": "How to return a book", "uri": "help://h14"}, {"title": "Damaged books on arrival", "uri": "help://h12"}, {"title": "Wrong book in the par
help://h14 -> # How to return a book  You have 30 days from delivery to return a printed book in the condition you received it. Start 
help://h99 -> MCPError no help article h99
```

- **`help://{article_id}`** is a **resource template**: one entry in the list that stands for forty URIs. A host that wants to show the help centre can list the templates; the specification also lets a server list concrete resources, which this one does not.
- **`search_help` returns URIs**, so the model's search and the host's reading meet: the model finds `help://h14`, and the host reads it (or asks the person, or lets the model read it, which is the host's decision).
- **Reading `help://h14`** returned the article as Markdown, with its `mimeType`.
- **Reading `help://h99`** failed with the reason, *"no help article h99"*. `ResourceNotFoundError` is the SDK's exception for exactly that; any other exception would have been a crash, with the reason kept on the server as for tools. The specification gives a resource that does not exist the code `-32602`.

The template matters for safety too. `help_article` looks the id up in a dictionary built from the file; it never builds a path from it. A resource handler that did `open(f"help/{article_id}.md")` would be one `../` away from reading any file ana can, which is `ai-dev` lesson 7's `read_handbook` check in another place. The SDK adds its own guard for template parameters (`ResourceSecurity`, which refuses traversal by default), and the safest handler is still one that never touches a path the client chose.
