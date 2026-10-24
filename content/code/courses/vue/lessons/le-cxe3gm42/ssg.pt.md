---
title: Geração estática, renderizada uma vez no build
version: 1
---

**O `nuxt generate` renderiza cada página uma vez, quando você faz o build, e grava cada uma num
arquivo.** O que ele produz não precisa de Node nem de Nitro para ser servido, só de um host que envia
arquivos, do tipo para o qual o `dist` da aula 17 foi pensado, e o HTML de cada página já vem
completo. Isso é *geração de site estático*, SSG, e é a forma mais barata e mais rápida de servir uma
página que é igual para todo mundo:

```
ana@dev:~/vue/planner-nuxt$ npx nuxt generate 2>&1 | tail -12
[nitro]   ├─ /courses/spanish/_payload.json?_b=1c26fe19-34f6-439f-a0d1-43933c07f768 (4ms) (skipped)
[nitro]   ├─ /courses/guitar/_payload.json?_b=1c26fe19-34f6-439f-a0d1-43933c07f768 (3ms) (skipped)
[nitro]   ├─ /courses/statistics (27ms)
[nitro]   ├─ /courses/statistics/_payload.json?_b=1c26fe19-34f6-439f-a0d1-43933c07f768 (1ms) (skipped)
[nitro]   ├─ /courses/spanish/_payload.json (5ms)
[nitro]   ├─ /courses/guitar/_payload.json (3ms)
[nitro]   ├─ /courses/statistics/_payload.json (2ms)
[nitro] ℹ Prerendered 10 routes in 1.832 seconds
[nitro] ✔ Generated public .output/public
[nitro] ✔ You can preview this build using npx serve .output/public
config 266ms · modules 50ms · app 456ms · types 410ms · client 1.05s · server 448ms · nitro 1.99s
◆ ✨ You can now deploy .output/public to any static hosting! (4.67s)
```

**Dez rotas, encontradas seguindo links.** O Nuxt renderizou `/`, leu os `<NuxtLink>` dela, renderizou
as três páginas de curso para onde eles levam e gravou um `_payload.json` ao lado de cada página: os
dados que o `useFetch` recebeu ao renderizá-la, que o navegador lê em vez de chamar a API. Uma página a
que nenhum link leva não é gerada, a não ser que a configuração a liste.

```
ana@dev:~/vue/planner-nuxt$ ls .output/public .output/public/courses
.output/public:
200.html
404.html
_nuxt
_payload.json
courses
favicon.ico
index.html
robots.txt

.output/public/courses:
guitar
spanish
statistics
```

O `index.html` e uma pasta por curso, cada uma com o próprio `index.html`. O `200.html` é a casca que
um host estático deve mandar para um endereço sem arquivo, para o router assumir dali, o trabalho que
o `vite preview` fazia para o build da aula 17, e o `404.html` é a página de erro.

## O que gerar o planner faz errado

Duas coisas, e as duas são da natureza do planner, não um erro no comando.

**Os dados são os dados do build.** Cada sessão nesses arquivos está como o `courses.json` a tinha
quando o comando rodou. Uma marcação manda um `PATCH` para `/api/sessions/…`, e um host estático não
tem servidor para respondê-lo: a API só existe onde o Nitro roda. Um planner gerado conseguiria mostrar
uma semana; não conseguiria mantê-la.

**E o relógio também.** O `today` do lado do servidor da última seção rodou uma vez, no build:

```
ana@dev:~/vue/planner-nuxt$ grep -o '<li class="today"[^>]*><label[^>]*><input[^>]*>[^<]*' .output/public/index.html
<li class="today" data-v-a1b0f0de><label data-v-a1b0f0de><input type="checkbox" data-v-a1b0f0de> 21 October 2026, Statistics, 60 minutes 
```

O grep encontra o destaque no dia 21, o dia do build, gravado no arquivo. Aberta em qualquer dia
depois, a página é uma divergência de hidratação sem servidor nenhum envolvido, e em produção ela fica
errada, como a última seção mostrou.

A geração serve para páginas cujo conteúdo muda quando você faz deploy e não entre um deploy e outro:
a página `about` do planner, a descrição de um curso, documentação, um blog. A próxima seção mistura
os dois num projeto só, página por página.
