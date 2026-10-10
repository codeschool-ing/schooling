---
title: MVC no servidor, onde o observer se perde
version: 1
---

**Todo framework web diz que é MVC, e cada um quer dizer uma coisa diferente da do Smalltalk.** No
servidor uma rota é o controller, um template é a view, e o controller busca o que a view precisa e
entrega a ela. A view não observa o modelo, porque não tem como: quando o modelo mudar de novo, a
página que ela desenhou já está no navegador de alguém. O nome veio junto quando uma das primeiras
especificações de JavaServer Pages, por volta de 1998, descreveu esse arranjo como *Model 2*, e
Rails, Django, Spring MVC e ASP.NET MVC seguiram essa adaptação.

Aqui está o balcão como uma aplicação web minúscula, ainda sobre `desk_model.py`, sem framework:

```schooling-example
{"language": "python", "file": "web.py", "parts": [
 {"code": "# web.py\nfrom datetime import date\nfrom html import escape\nfrom urllib.parse import parse_qs\nfrom desk_model import Desk\n\ndesk = Desk([\"B1\", \"B2\", \"B3\"], limit=2)\nTODAY = date(2026, 3, 2)", "note": "O mesmo modelo, importado sem mudança. Um único balcão vive enquanto o processo vive, que é como um servidor pequeno guarda estado entre requisições até a lição 10 lhe dar um banco de dados."},
 {"code": "\n\ndef shelf_page(on_shelf: list[str], loans: int) -> str:\n    items = \"\".join(f\"<li>{escape(code)}</li>\" for code in sorted(on_shelf))\n    return f\"<h1>On the shelf</h1><ul>{items}</ul><p>{loans} out</p>\"\n\n\ndef message_page(text: str) -> str:\n    return f\"<p class=msg>{escape(text)}</p>\"", "note": "As views. Cada uma é uma função de valores simples para HTML; nenhuma ouviu falar de `Desk`. O `escape` é tarefa da view, porque só a view sabe que a saída é HTML."},
 {"code": "\n\ndef show_shelf(form: dict) -> tuple[str, str]:\n    return \"200 OK\", shelf_page(desk.on_shelf, len(desk.loans))\n\n\ndef lend(form: dict) -> tuple[str, str]:\n    try:\n        loan = desk.lend(form[\"code\"], form[\"member\"], TODAY)\n    except ValueError as err:\n        return \"409 Conflict\", message_page(f\"refused: {err}\")\n    return \"200 OK\", message_page(f\"{loan.code} due back {loan.due}\")", "note": "Os controllers. Cada um pega o que a requisição trouxe, chama o modelo e escolhe uma view e um status. Uma recusa vira `409 Conflict`, que é uma decisão sobre HTTP e por isso fica aqui, e não no modelo."},
 {"code": "\n\nROUTES = {\n    (\"GET\", \"/shelf\"): show_shelf,\n    (\"POST\", \"/loans\"): lend,\n}", "note": "A tabela de rotas é a lista de controllers. O `urls.py` do Django, o `@app.route` do Flask, o `app.post` do Express e o `http.HandleFunc` do Go montam uma dessas."},
 {"code": "\n\ndef app(environ, start_response):\n    key = (environ[\"REQUEST_METHOD\"], environ[\"PATH_INFO\"])\n    controller = ROUTES.get(key)\n    if controller is None:\n        status, body = \"404 Not Found\", message_page(\"no such page\")\n    else:\n        size = int(environ.get(\"CONTENT_LENGTH\") or 0)\n        raw = environ[\"wsgi.input\"].read(size).decode()\n        form = {k: v[0] for k, v in parse_qs(raw).items()}\n        status, body = controller(form)\n    start_response(status, [(\"Content-Type\", \"text/html; charset=utf-8\")])\n    return [body.encode()]", "note": "Uma aplicação WSGI: uma função que todo servidor web Python sabe chamar com a requisição, um dicionário, e uma função de retorno para a linha de status. Ela acha o controller, decodifica o formulário e devolve a página."},
 {"code": "\n\nif __name__ == \"__main__\":\n    import io\n    from wsgiref.util import setup_testing_defaults\n\n    def request(method: str, path: str, body: str = \"\") -> None:\n        environ = {\"REQUEST_METHOD\": method, \"PATH_INFO\": path,\n                   \"CONTENT_LENGTH\": str(len(body)), \"wsgi.input\": io.BytesIO(body.encode())}\n        setup_testing_defaults(environ)\n        print(f\"{method} {path} {body}\".rstrip())\n        page = app(environ, lambda status, headers: print(\" \", status))\n        print(\" \", page[0].decode())\n\n    request(\"GET\", \"/shelf\")\n    request(\"POST\", \"/loans\", \"code=B1&member=bia\")\n    request(\"POST\", \"/loans\", \"code=B1&member=caio\")\n    request(\"GET\", \"/shelf\")", "note": "Em vez de subir um servidor, o programa monta quatro requisições do jeito que um servidor montaria e chama `app` com cada uma. A saída é o que um navegador receberia."}
]}
```

```
ana@laptop:~/patterns/presentation$ python3 web.py
GET /shelf
  200 OK
  <h1>On the shelf</h1><ul><li>B1</li><li>B2</li><li>B3</li></ul><p>0 out</p>
POST /loans code=B1&member=bia
  200 OK
  <p class=msg>B1 due back 2026-03-16</p>
POST /loans code=B1&member=caio
  409 Conflict
  <p class=msg>refused: B1 is not on the shelf</p>
GET /shelf
  200 OK
  <h1>On the shelf</h1><ul><li>B2</li><li>B3</li></ul><p>1 out</p>
```

A segunda requisição empresta o B1 à Bia e a terceira, o Caio pedindo o mesmo livro, é recusada com
`409 Conflict`. O último `GET /shelf` mostra dois itens na estante e `1 out`, então o estado
sobreviveu entre as requisições porque o objeto `desk` sobreviveu. Para experimentar num navegador,
o servidor da própria biblioteca padrão pode chamar o mesmo `app`:
`make_server("127.0.0.1", 8000, app).serve_forever()`, importado de `wsgiref.simple_server`. Nada
mais muda.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l07-request\" aria-label=\"Um diagrama de sequência de uma requisição a web.py, POST /loans, lido de cima para baixo. Cinco linhas de vida: o navegador, app, o controlador lend, o modelo Desk e a view message_page. O navegador manda a requisição para app; app procura a rota e chama lend com o formulário; lend chama desk.lend, que devolve um Loan; lend chama message_page com uma frase e recebe HTML de volta; lend devolve 200 OK e o HTML para app, e app manda a resposta ao navegador. Depois disso a página está no navegador, e uma mudança posterior no desk não redesenha nada até o navegador pedir de novo.\"><defs><marker id=\"l07-request-dp-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l07-request-dp-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"12.0\" y=\"19.0\" width=\"116.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"70.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">navegador</text><text x=\"70.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">cliente</text><path d=\"M70.0 72.0 L70.0 300.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"157.0\" y=\"19.0\" width=\"116.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"215.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">app</text><text x=\"215.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">roteador</text><path d=\"M215.0 72.0 L215.0 300.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"302.0\" y=\"19.0\" width=\"116.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">lend</text><text x=\"360.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">controlador</text><path d=\"M360.0 72.0 L360.0 300.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"447.0\" y=\"19.0\" width=\"116.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"505.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Desk</text><text x=\"505.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">modelo</text><path d=\"M505.0 72.0 L505.0 300.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"592.0\" y=\"19.0\" width=\"116.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"650.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">message_page</text><text x=\"650.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">view</text><path d=\"M650.0 72.0 L650.0 300.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M74.0 96.0 L209.0 96.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l07-request-dp-ah-phosphor)\"></path><text x=\"142.5\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">POST /loans</text><path d=\"M219.0 122.0 L354.0 122.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l07-request-dp-ah-phosphor)\"></path><text x=\"287.5\" y=\"113.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">lend(form)</text><path d=\"M364.0 148.0 L499.0 148.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l07-request-dp-ah-phosphor)\"></path><text x=\"432.5\" y=\"139.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">desk.lend(…)</text><path d=\"M501.0 174.0 L366.0 174.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l07-request-dp-ah-paper-dim)\"></path><text x=\"432.5\" y=\"165.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Loan</text><path d=\"M364.0 200.0 L644.0 200.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l07-request-dp-ah-phosphor)\"></path><text x=\"505.0\" y=\"191.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">message_page(…)</text><path d=\"M646.0 226.0 L366.0 226.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l07-request-dp-ah-paper-dim)\"></path><text x=\"505.0\" y=\"217.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&lt;p&gt;…&lt;/p&gt;</text><path d=\"M356.0 252.0 L221.0 252.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l07-request-dp-ah-paper-dim)\"></path><text x=\"287.5\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&quot;200 OK&quot;, html</text><path d=\"M211.0 278.0 L76.0 278.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l07-request-dp-ah-paper-dim)\"></path><text x=\"142.5\" y=\"269.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">a página</text><text x=\"360.0\" y=\"318.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">a página foi enviada: uma mudança posterior no desk não redesenha nada até a próxima requisição</text></svg>", "caption": "Uma requisição, de cima para baixo. O controlador chama o modelo, entrega valores simples a uma view, e a página sai; depois disso ninguém está observando.", "same": ["view"]}
```

## O que mudou em relação à versão de desktop

Três coisas, e cada uma decorre do HTTP.

**A view recebe valores, ela não lê o modelo.** `shelf_page` recebe uma lista e um número. Poderia
ser um template Jinja2 ou Django, uma página Thymeleaf no Spring ou um arquivo `html/template` no
Go; todos são funções de um dicionário de valores para texto. É um ganho real sobre a view de
desktop da seção anterior, cuja formatação só podia ser conferida numa tela. Aqui um teste chama
`shelf_page(["B2"], 1)` e lê uma string.

**Ninguém se inscreve.** `desk.subscribe` nunca é chamado em `web.py`. Uma mudança no balcão não tem
como chegar a uma página já enviada, então cada requisição renderiza do zero, e uma página que
precisa se atualizar sozinha tem de perguntar de novo ou manter uma conexão aberta. Esse trabalho
passou para o código que roda no navegador, que é onde o MVP e o MVVM voltam à cena.

**O controller decide sobre HTTP.** O código de status, que view usar e como uma recusa aparece para
um navegador são decisões de apresentação sobre a web, e ficam em `lend`. O modelo continua lançando
um `ValueError` com uma frase, exatamente como fazia para o terminal.

## Os nomes, framework por framework

As palavras escorregam, então leia cada framework pelas setas e não pelo vocabulário:

| framework | o controller é | a view é |
|---|---|---|
| Django (Python) | uma função ou classe em `views.py` | um template; o Django chama o padrão de MTV, model-template-view |
| Flask (Python) | uma função sob `@app.route` | um template Jinja2 |
| Express (JavaScript / TypeScript) | um handler passado a `app.get` ou `app.post` | um motor de templates, ou `res.json` para uma API |
| Spring MVC (Java) | um método numa classe `@Controller` | uma página Thymeleaf ou JSP, ou um objeto devolvido para uma API |
| `net/http` (Go) | uma `http.HandlerFunc` | um `html/template`, ou `json.NewEncoder(w)` |

O vocabulário do Django é o que mais confunde: a "view" dele é o controller da tabela acima. As
setas são as mesmas de todas as outras linhas.

**Um handler de rota que faz o trabalho sozinho é o laço emaranhado de novo, com uma URL na
frente.** O erro mais comum do lado do servidor é um controller que abre o banco, confere o limite,
calcula a multa e formata a resposta numa função só. Mantenha a regra no modelo e o controller fica
com três linhas: ler a requisição, chamar o modelo, escolher uma view.

Numa API que devolve JSON, a "view" é só o serializador. Os padrões de apresentação das duas
próximas seções moram no cliente que a lê: uma aplicação no navegador ou um app de celular, com tela
própria e seu próprio modelo do que mostrar.
