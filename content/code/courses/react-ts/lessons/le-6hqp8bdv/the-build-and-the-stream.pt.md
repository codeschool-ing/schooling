---
title: O build, e uma página que chega aos poucos
version: 1
---

**O build de produção é onde a fronteira vira arquivos.** Pare o servidor de desenvolvimento e faça o
build:

```
ana@dev:~/planner-next$ npm run build

> planner-next@0.1.0 build
> next build

▲ Next.js 16.4.3 (Turbopack)
✓ Running next.config.ts took 35ms
- Cache Components enabled
- Partial Prefetching enabled

  Creating an optimized production build ...
✓ Compiled successfully in 3.1s
  Running TypeScript ...
  Finished TypeScript in 1821ms ...
  Collecting page data using 3 workers ...
  Generating static pages using 3 workers (0/3) ...
✓ Generating static pages using 3 workers (3/3) in 218ms
  Finalizing page optimization ...

Route (app)
┌ ◐ /
└ ○ /_not-found


○  (Static)             prerendered as static content
◐  (Partial Prerender)  prerendered as static HTML with dynamic server-streamed content
```

O `Running TypeScript` é a conferência que o `tsc -b` fazia no projeto do Vite, aqui parte do build. A
tabela do fim é sobre o Cache Components. `/` é **◐, um prerender parcial**: a casca estática dela, o
título e a reserva *Loading the planner…*, foi renderizada agora, no build, e o planejador em si vai ser
renderizado a cada requisição e transmitido para dentro dela. `/_not-found` é a página 404 do Next.js,
toda estática.

Agora a promessa do começo da aula, conferida nos arquivos. `.next/static` é o que vai para os
navegadores; `.next/server` fica no servidor:

```
ana@dev:~/planner-next$ grep -rl 'localhost:3001' .next/static | wc -l
0
ana@dev:~/planner-next$ grep -rl 'ArrowRight' .next/static | wc -l
2
ana@dev:~/planner-next$ grep -rl 'localhost:3001' .next/server | wc -l
2
```

- **O endereço da API não está em nenhum arquivo que um navegador recebe.** Ele está no
  `lib/planner.ts`, que só Server Components importam.
- **O `ArrowRight` está**, em dois arquivos, porque o `WeekKeys` é um Client Component.
- Os arquivos do servidor têm o endereço, porque é lá que o `fetch` roda.

Essa é a fronteira como um deploy a vê, e é por isso que o `console.log` do `Planner` nunca aparece no
console de um navegador em produção: o código dele não está lá.

O **streaming** é a outra metade do ◐. Reinicie a API com `DELAY=2000`, o interruptor da aula 11 que
faz toda resposta esperar dois segundos, e inicie o servidor de produção com `npm start`. Depois meça
uma requisição da página:

```
ana@dev:~/planner-next$ curl -s -o /dev/null -w '%{time_starttransfer} %{time_total}\n' 'http://localhost:3000/?week=2026-10-19' | awk '{ printf "first byte after %.1f s, last after %.1f s\n", $1, $2 }'
first byte after 0.0 s, last after 2.0 s
ana@dev:~/planner-next$ curl -s 'http://localhost:3000/?week=2026-10-19' | sed 's/<!-- -->//g' | grep -b -o 'Loading the planner…' | head -n 1
910:Loading the planner…
ana@dev:~/planner-next$ curl -s 'http://localhost:3000/?week=2026-10-19' | sed 's/<!-- -->//g' | grep -b -o '80 of 195 minutes done'
7176:80 of 195 minutes done
```

**O primeiro byte chegou na hora, e o último depois de dois segundos.** O servidor não esperou a API
para começar a responder. Mandou a casca estática imediatamente, manteve a conexão aberta e mandou o
planejador quando a API respondeu, na mesma resposta. Um navegador desenha a casca, com *Loading the
planner…*, assim que ela chega, e troca pelo planejador quando o resto vem.

Os dois `grep -b` imprimem onde na resposta cada texto está, como posição em bytes: a reserva no byte
910, perto do começo, e os minutos no 7176, perto do fim, depois dos dois segundos. A reserva não foi
substituída no HTML; o fim da resposta traz o HTML do planejador num elemento escondido e algumas linhas
de script que o põem no lugar. Isso é `Suspense` no servidor: a fronteira que a aula 13 usou para
esperar código agora decide **qual parte de uma página pode chegar atrasada**.
