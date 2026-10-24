---
title: Os outros hooks
version: 1
---

**O SvelteKit tem três arquivos de hooks, e o planner usou um.** `src/hooks.server.js` roda no servidor;
`src/hooks.client.js` roda no navegador; `src/hooks.js` roda nos dois. Os hooks que não servem ao
planner valem ser conhecidos pelo nome, para que o problema que cada um resolve seja reconhecido quando
aparecer. Nenhum código abaixo faz parte do planner, e nenhum é rodado nesta aula.

**O `handleError` em `hooks.client.js`** é a metade do navegador da seção anterior: um erro lançado
enquanto o navegador carrega ou renderiza uma página chega a ele em vez disso. É onde uma aplicação
manda os erros do navegador para um serviço de monitoramento, já que eles nunca chegam sozinhos ao log
do servidor.

**O `handleFetch`**, em `hooks.server.js`, fica na frente de todo `fetch` que uma função load ou uma
action faz no servidor. O uso comum é mandar uma requisição feita para o endereço público de uma API a
um endereço interno mais rápido, quando o servidor e a API estão na mesma rede:

```javascript
// src/hooks.server.js: an example of handleFetch, not part of the planner.
export async function handleFetch({ request, fetch }) {
	if (request.url.startsWith('https://api.example.com/')) {
		request = new Request(request.url.replace('https://api.example.com/', 'http://localhost:9999/'), request);
	}
	return fetch(request);
}
```

**O `reroute`**, em `hooks.js`, muda a rota com que um endereço é casado, antes de qualquer outra coisa
rodar, sem mudar o endereço. É como uma rota pode responder por vários nomes, um endereço em inglês e um
em português para a mesma página, por exemplo:

```javascript
// src/hooks.js: an example of reroute, not part of the planner.
const aliases = { '/sobre': '/about' };

export function reroute({ url }) {
	return aliases[url.pathname];
}
```

Não devolver nada mantém a rota do próprio endereço.

**O `transport`**, em `hooks.js`, ensina o SvelteKit a levar uma classe sua de uma função load de
servidor até o navegador, com uma função que a transforma em dados e outra que a reconstrói. É a saída
para onde apontava a mensagem `load_not_serializable` da aula 13. Ele não faz funções viajarem; faz
viajar uma classe cujo estado é dado, mandando os dados e chamando o construtor de novo do outro lado.

**O `init`** roda uma vez, quando o servidor inicia ou a aplicação inicia no navegador, para trabalhos
como conectar a um banco de dados antes de a primeira requisição chegar.
