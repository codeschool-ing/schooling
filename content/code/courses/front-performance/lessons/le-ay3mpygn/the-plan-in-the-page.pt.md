---
title: O plano na página
version: 1
---

**A aula 6 deixou um achado sem insight nenhum: o plano inteiro está em toda página.** Código não é a única
coisa que uma página pode baixar sem usar, e o plano é o maior exemplo do planner. É a mesma pergunta desta
aula, feita aos dados: do que esta página precisa, e quando?

## O que custa

O `curl --compressed` pede gzip, como um navegador, e o `-w` imprime quantos bytes vieram pela rede. Com o
plano real, e com os cinco mil cursos da aula 3:

```
ana@dev:~/planner$ curl -s --compressed -o /dev/null -w '%{size_download} bytes\n' http://localhost:3000/courses/git
1318 bytes
ana@dev:~/planner$ node gen.ts 5000 && curl -s --compressed -o /dev/null -w '%{size_download} bytes\n' http://localhost:3000/courses/course-1
5000 courses
52966 bytes
```

**Cinquenta e três kilobytes, comprimidos, para uma página que desenha um curso e as duas sessões dele**, e
todo visitante interpreta tudo isso antes de a página responder. Com o plano real a mesma página tem 1,3
kilobyte.

## Três jeitos de arrumar

| arrumação | o que cada página manda | o que custa |
|---|---|---|
| **o plano inteiro em toda página**, como agora | tudo, toda vez | os bytes e a interpretação crescem com o catálogo, em toda página |
| **o plano como arquivo próprio**, buscado pelo script | nada; o script pede o `/courses.json` | uma ida e volta antes de a página responder, a janela morta da aula 4 de novo; mas o arquivo é buscado uma vez e, com os cabeçalhos da aula 9, fica no cache para toda página seguinte |
| **os dados de cada página**, e mais buscado na navegação | o curso e as sessões dele, numa página de curso | o servidor precisa saber do que cada página precisa, e o script precisa buscar isso a cada navegação, e juntar o que o visitante mudou |

O terceiro é o que os quatro frameworks da aula 2 fazem: os dados de uma página são carregados com a página,
e uma navegação dentro da aplicação pede ao servidor os dados da próxima página. O Next.js os manda como o
payload dos server components, o Nuxt e o SvelteKit como JSON da rota, e no Angular o próprio código da rota
os pede à API do servidor.

## A decisão, para o planner

**O planner mantém o plano inteiro na página.** O catálogo dele são três cursos, e a navegação dele, o
tratador de cliques do `mount`, desenha qualquer página a partir do plano que tem, sem requisição nenhuma, que
é o melhor tipo de navegação que existe. A arrumação está errada com cinco mil cursos, e a medida acima é como
saber quando esse ponto chega: quando os dados de uma página são maiores que a página, é hora de mandar a cada
página os seus.

Isso é uma decisão, não uma correção, e está escrita aqui porque uma decisão que ninguém escreveu parece, um
ano depois, exatamente um erro que ninguém notou.

Ponha o plano real de volta antes de seguir: o `npm run build` o copia para `dist/` de novo.
