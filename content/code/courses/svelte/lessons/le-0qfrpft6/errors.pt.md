---
title: A página de erro
version: 1
---

**Quando o SvelteKit não consegue renderizar uma página, ele renderiza o `+error.svelte` mais próximo no
lugar dela**, dentro dos layouts acima dele. O 404 da seção anterior era a página simples do próprio
SvelteKit. Um `+error.svelte` na raiz de `src/routes` a substitui para todos os endereços, e mantém o
cabeçalho do planner em volta para que um estudante que digitou um endereço errado tenha para onde ir.
Salve como `src/routes/+error.svelte`:

```schooling-example
{"language": "html", "file": "src/routes/+error.svelte", "parts": [
 {"code": "<script>\n\timport { page } from '$app/state';\n</script>\n\n<svelte:head>\n\t<title>{page.status} · Study planner</title>\n</svelte:head>", "note": "`page.status` é o status HTTP, e `page.error` o erro que foi lançado, com uma `message`."},
 {"code": "<h1>{page.status === 404 ? 'Nothing at this address' : 'Something went wrong'}</h1>\n<p>{page.error?.message}</p>\n<p><a href=\"/\">Back to the planner</a></p>", "note": "A página diz o que aconteceu em palavras e oferece um caminho de volta. O código de status é para o navegador e para os logs."}
]}
```

```
ana@dev:~/planner$ look http://localhost:5173/courses/Algebra
at /courses/Algebra
title: 404 · Study planner
- main:
  - heading "Nothing at this address" [level=1]
  - paragraph: Not Found
  - paragraph:
    - link "Back to the planner":
      - /url: /
```

```
ana@dev:~/planner$ curl -s -o /dev/null -w '%{http_code}\n' http://localhost:5173/courses/Algebra
404
```

A página está mais amigável e **o status continua sendo 404**. Isso importa mais do que parece: um
crawler, um verificador de links ou uma ferramenta de monitoramento lê o status, não as palavras, e uma
página de "não encontrado" respondida com 200 diz a todos eles que o endereço existe.

## Onde uma página de erro vale

O SvelteKit procura um `+error.svelte` começando na pasta da rota que falhou e subindo, então uma seção
da aplicação pode ter a sua própria página de erro, mais perto da falha que a da raiz. Uma página de erro
é renderizada dentro dos layouts **acima** da sua própria pasta, e é por isso que esta tem o cabeçalho:
o layout raiz a envolve.

Duas falhas nunca chegam a um `+error.svelte`. Se o próprio layout raiz falha, não sobra layout para
renderizar a página de erro dentro, e o SvelteKit recorre a uma página estática, `src/error.html`, que
você pode escrever para substituir a padrão. E os erros em endpoints do servidor, que são a aula 17, são
respondidos como dados, não como páginas. A aula 13 lança erros de propósito, com `error(404, …)`, a
partir das funções que carregam os dados de uma página, e este arquivo é o que os mostra.
