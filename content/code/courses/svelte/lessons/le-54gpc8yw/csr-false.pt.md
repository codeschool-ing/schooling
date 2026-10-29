---
title: csr = false, e uma página sem JavaScript
version: 1
---

**`export const csr = false` é a troca oposta: o servidor renderiza a página, e nenhum JavaScript vai junto
com ela.** Os componentes continuam rodando, no servidor, para produzir o HTML; o navegador recebe o HTML e
o CSS e nada para rodar. Para a About, que não tem nada a fazer além de ser lida, isso é a página inteira.
Substitua o `src/routes/(info)/about/+page.js`:

```schooling-example
{"language": "javascript", "file": "src/routes/(info)/about/+page.js", "parts": [
 {"code": "// +page.js: page options for About."},
 {"code": "export const csr = false;", "note": "O servidor a renderiza; o navegador não recebe script nenhum. O `<script>` de cada componente da página, o do layout incluído, roda só no servidor."}
]}
```

Faça o build, reinicie e conte as tags `<script>` no que o servidor manda, para a About e para a semana:

```
ana@dev:~/planner$ curl -s http://localhost:3000/about | grep -c '<script'
0
ana@dev:~/planner$ curl -s http://localhost:3000/ | grep -c '<script'
1
```

**Nenhuma na About, uma na semana.** A da página da semana é o script inline que a seção anterior mostrou,
que importa o roteador do SvelteKit e a aplicação: o código que a aula 1 viu ser a maior parte dos 33 kB
que a sua primeira página custou. Uma página com `csr = false` dispensa tudo isso. A folha de estilo
continua ligada, então a página tem a mesma cara.

Do que a About abre mão é de tudo o que o código do navegador fazia:

- **Os links dela são links comuns.** "Back to the planner" carrega a semana como uma página nova, com uma
  requisição pelo HTML inteiro, e não como uma navegação no cliente, porque não há roteador na About para
  interceptar o clique.
- **Nada nela consegue reagir.** Um botão com `onclick` não faria nada, exatamente como com o JavaScript
  desligado, porque, para esta página, ele está.
- **O servidor de desenvolvimento para de atualizá-la enquanto você salva**, já que essa atualização também
  é JavaScript. Um recarregamento mostra a mudança.

```
ana@dev:~/planner$ look http://localhost:3000/about --click 'Back to the planner' | head -4
-- click Back to the planner
at /
title: 255 min this week · Study planner
- main:
```

O link funciona, como qualquer link. **O `csr = false` é seguro exatamente onde o JavaScript desligado é**,
o que, para as páginas do próprio planner, agora é em toda parte, depois da aula 14. Elas o mantêm ligado
porque o planner fica mais rápido e mais fluido com ele, e sem ele continuaria funcionando.
