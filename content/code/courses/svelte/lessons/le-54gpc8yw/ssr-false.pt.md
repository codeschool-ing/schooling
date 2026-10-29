---
title: ssr = false, e a página que chega vazia
version: 1
---

**`export const ssr = false` faz o servidor mandar uma página sem nada dentro e deixa toda a renderização
para o navegador.** É assim que a maioria das aplicações de página única funciona, e o SvelteKit consegue
fazer isso por página. Experimente na About. Salve isto como `src/routes/(info)/about/+page.js`:

```schooling-example
{"language": "javascript", "file": "src/routes/(info)/about/+page.js", "parts": [
 {"code": "// +page.js: page options for About. (A trial: the next section changes it.)\nexport const ssr = false;", "note": "O servidor manda a página sem renderizá-la; o navegador faz tudo."}
]}
```

Faça o build, reinicie o servidor e leia o corpo do que ele manda para `/about`:

```
ana@dev:~/planner$ curl -s http://localhost:3000/about | sed -n '/<body/,/<\/body>/p'
	<body data-sveltekit-preload-data="hover">
		<div style="display: contents">
			<script>
				{
					__sveltekit_1il064a = {
						base: new URL(".", location).pathname.slice(0, -1),
						version: "1792803344039"
					};

					const element = document.currentScript.parentElement;

					import("./_app/immutable/entry/start.DB_ekTOL.js").then(async (kit) => {
						kit.init(__sveltekit_1il064a);
						const app = await import("./_app/immutable/entry/app.CM8src-9.js");
						kit.start(app, element);
					});
				}
			</script>
		</div>
	</body>
```

**Nenhum título, nenhum parágrafo, nenhum cabeçalho com os seus links**: um script, que importa o código
do SvelteKit e o da aplicação e então renderiza a página no navegador. Num navegador com JavaScript, o
resultado é a mesma página:

```
ana@dev:~/planner$ look http://localhost:3000/about
at /about
title: About · Study planner
- main:
  - heading "About the planner" [level=1]
  - paragraph: The study planner lists your courses, the sessions you plan for each, and the minutes in your week. It keeps everything on this computer, in one small file, and asks nobody for anything.
  - paragraph:
    - link "Back to the planner":
      - /url: /
```

e num sem, nada:

```
ana@dev:~/planner$ look http://localhost:3000/about --no-js
at /about
```

Isso custa três coisas, e cada uma é um motivo para ficar com o padrão:

- **Nada até o script rodar.** O navegador baixa o HTML, depois os scripts, depois os roda, e só então há
  algo para ver. Com SSR o texto já está na primeira resposta.
- **Nada de nada sem JavaScript**, a dependência que a aula 14 passou uma aula inteira tirando do planner.
- **Nada para quem lê HTML e não roda scripts**: alguns buscadores, as prévias de link em aplicativos de
  conversa, e um monte de ferramentas.

O `ssr = false` faz sentido para uma página que não pode ser renderizada no servidor de jeito nenhum, porque
usa `window` ou `document` enquanto renderiza, ou usa uma biblioteca que faz isso. Para uma página que pode
ser renderizada no servidor, ele abre mão das três coisas em troca de nada.
