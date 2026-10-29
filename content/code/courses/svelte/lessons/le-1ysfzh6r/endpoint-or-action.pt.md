---
title: Um endpoint ou uma action
version: 1
---

**Para um formulário numa das páginas da própria aplicação, uma action. Para todo o resto, um
endpoint.** Essa é a regra que a documentação dá, e o planner agora tem os dois, então os motivos podem
ser vistos lado a lado:

| | form action | endpoint |
|---|---|---|
| quem manda | um `<form>` numa página da aplicação | qualquer programa: um script, o servidor de outro site, um `fetch` num componente |
| funciona com JavaScript desligado | sim, é um formulário | só se algo que não é JavaScript a mandar |
| depois que roda | a página renderiza de novo, ou um redirecionamento, e as funções load rodam de novo | o `Response` que ele devolver |
| um erro | o `+error.svelte` mais próximo, dentro dos layouts | JSON, ou uma página simples de reserva, nunca o `+error.svelte` |
| layouts | ela pertence a uma página, e a página tem layouts | nenhum: arquivos `+layout` não têm efeito nele |
| hooks | o `handle` roda | o `handle` roda |

**A linha do erro é a que surpreende.** Um endpoint não tem página, então um erro nele não consegue
mostrar a página de erro. O SvelteKit responde com o erro em JSON a uma requisição que não pede HTML, e
com uma página simples de reserva, o `src/error.html` se o projeto tiver um, a um navegador:

```
ana@dev:~/planner$ curl -s -w '\n' http://localhost:5173/courses/piano/sessions.csv
{"status":404,"message":"There is no course called “piano”."}
```

`{"status":404,"message":…}`: o `error(404, …)` do endpoint de CSV, escrito como dados, sem nada do
cabeçalho ou dos links do planner em volta.

**A aula 12 prometeu isto** em "A página de erro": erros em endpoints "são respondidos como dados, não
como páginas". Eles continuam passando pelo `handleError`, então um inesperado vai para o log com o id da
sua requisição, como a aula 16 arrumou.

Mais uma diferença não está na tabela porque é sobre tempo, não sobre mecanismo. As **remote functions**
experimentais do SvelteKit 3, que a aula 14 mencionou, deixam um componente chamar uma função no servidor
como se fosse local, e cobrem boa parte do que uma aplicação escreve endpoints para fazer hoje. Elas
ainda são experimentais; endpoints não, e um endpoint é o que qualquer programa de fora da aplicação, que
não sabe nada de SvelteKit, sempre vai precisar.
