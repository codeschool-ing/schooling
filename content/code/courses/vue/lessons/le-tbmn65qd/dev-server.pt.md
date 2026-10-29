---
title: O servidor de desenvolvimento
version: 1
---

**O `npm run dev` inicia um servidor que ainda não converteu nada.** Ele fica pronto em menos de meio
segundo, e esse número não cresce com a aplicação, porque o trabalho acontece depois, um arquivo por
vez, quando o navegador pede:

```
ana@dev:~/vue/planner$ npm run dev

> planner@0.0.0 dev
> vite


  VITE v8.3.5  ready in 401 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
```

A linha `Network` quer dizer que o servidor só atende este computador. O `npm run dev -- --host`
deixaria um celular na mesma rede abrir a página, e deixaria qualquer outra pessoa nessa rede abri-la
também, e é por isso que fica desligado até você pedir.

## Uma requisição por módulo

Conte as requisições que a página da semana faz:

```
ana@dev:~/vue/planner$ look http://localhost:5173/ --network --text - | grep -c '^net'
33
```

Trinta e três, e a aula 13 imprimiu uma lista parecida: a página, o `main.ts`, cada componente, o
estilo de cada componente, a store, o router, o `planner.ts`, os composables, o Vue e os dados. **Cada
arquivo que o navegador importa é uma requisição, e o Vite converte cada arquivo quando essa requisição
chega.** Peça o `planner.ts` do jeito que o navegador pede:

```
ana@dev:~/vue/planner$ curl -s http://localhost:5173/src/planner.ts | head -24
// A date as YYYY-MM-DD, in the computer's own time zone.
export function isoDate(date) {
	const y = date.getFullYear();
	const m = String(date.getMonth() + 1).padStart(2, "0");
	const d = String(date.getDate()).padStart(2, "0");
	return `${y}-${m}-${d}`;
}
// The date n days after a YYYY-MM-DD date (before it, if n is negative).
export function addDays(iso, n) {
	const [y, m, d] = iso.split("-").map(Number);
	return isoDate(new Date(y, m - 1, d + n));
}
// The Monday of the week a date falls in, as YYYY-MM-DD.
export function weekStart(date) {
	const daysSinceMonday = (date.getDay() + 6) % 7;
	return addDays(isoDate(date), -daysSinceMonday);
}
// "19 October 2026", for people.
export function formatDay(iso) {
	const [y, m, d] = iso.split("-").map(Number);
	return new Date(y, m - 1, d).toLocaleDateString("en-GB", {
		day: "numeric",
		month: "long",
		year: "numeric"
```

O arquivo é TypeScript no disco e JavaScript no fio. Os tipos da aula 16 sumiram, `isoDate(date)` sem
`: Date`, e o código foi impresso de novo pelo conversor, com tabs e aspas duplas, e é assim que você
percebe que ele não é mais o arquivo que você escreveu. **Nada conferiu os tipos no caminho.** O Vite
remove os tipos, o que leva um instante por arquivo, e deixa a conferência para o `vue-tsc`, que leva
segundos para o projeto; é por isso que o script `type-check` da aula 16 existe separado do `dev`. Um
arquivo `.vue` é convertido do mesmo jeito, pelo `@vitejs/plugin-vue`, em um módulo JavaScript e uma
requisição separada para cada bloco `<style>`.

## O que acontece com os imports

Agora as primeiras linhas do `main.ts`, como o navegador as recebe:

```
ana@dev:~/vue/planner$ curl -s http://localhost:5173/src/main.ts | grep '^import'
import { createApp } from "/node_modules/.vite/deps/vue.js?v=a419e1e3";
import { createPinia } from "/node_modules/.vite/deps/pinia.js?v=a419e1e3";
import App from "/src/App.vue";
import { router } from "/src/router.ts";
import "/src/main.css";
```

Aconteceram dois tipos de reescrita. O `'./router.js'` virou `"/src/router.ts"`: o arquivo foi
renomeado para `.ts` na aula 16 e o import não, e o Vite achou o arquivo mesmo assim, como o TypeScript
acha. E o `'vue'`, um nome de pacote solto, virou um caminho dentro de `/node_modules/.vite/deps/`. Um
navegador não consegue carregar um nome solto, ele não faz ideia de onde o `vue` mora, então o
servidor troca cada nome solto por um endereço que ele consegue servir.

## O pré-empacotamento das dependências

Esse endereço aponta para uma pasta que o Vite preencheu na primeira vez que o servidor iniciou:

```
ana@dev:~/vue/planner$ ls node_modules/.vite/deps
_metadata.json
dist-BZygRcNR.js
dist-BZygRcNR.js.map
package.json
pinia.js
pinia.js.map
vue-router.js
vue-router.js.map
vue.js
vue.runtime.esm-bundler-CWNVreLk.js
vue.runtime.esm-bundler-CWNVreLk.js.map
```

**O Vue, o Pinia e o Vue Router foram empacotados, uma vez, em um arquivo cada**, com um chunk
compartilhado para o código que dois deles têm em comum. Os seus próprios arquivos são servidos um a
um porque você os edita; uma dependência não muda entre dois salvamentos, e pode ser feita de
centenas de módulos internos, uma requisição cada se fosse servida do jeito que os seus arquivos são.
Alguns pacotes do npm também são escritos em CommonJS, `require()` e `module.exports`, que nenhum
navegador carrega, e o pré-empacotamento os converte. O `?v=a419e1e3` no fim de cada endereço muda
quando as dependências mudam, então o navegador pode guardar esses arquivos no cache sem perguntar de
novo. Quando você instala um pacote, o Vite percebe que o lockfile mudou e empacota as dependências de
novo no próximo início.
