---
title: Uma página pesada, e o que o relatório aponta
version: 1
---

**Três cursos fazem uma página que ninguém consegue deixar lenta. Cinco mil conseguem.** O `gen.ts` da
aula 3 escreve um plano de qualquer tamanho em `dist/`, e o `server.ts` o lê a cada requisição, então a
página inicial de um catálogo grande está a um comando de distância. Meça:

```
ana@dev:~/planner$ node gen.ts 5000 && npm run lighthouse -- http://localhost:3000/ >/dev/null && node tools/report.ts report.report.json
5000 courses
performance 75, throttling simulate
  FCP  4.3 s    weight 10
  LCP  4.3 s    weight 25
  TBT  10 ms    weight 30
  CLS  0        weight 25
  SI   4.3 s    weight 10
  insight: Use efficient cache lifetimes, Est savings of 18 KiB
  insight: Document request latency, Est savings of 414 KiB
  insight: Network dependency tree
  insight: Render-blocking requests, Est savings of 300 ms
  request /                            done at    39 ms, 633040 B
  request /assets/index-C9VFYfGa.js    done at    63 ms, 17819 B
  request /assets/index-CGM1waBA.css   done at    63 ms, 538 B
  request /favicon.svg                 done at   102 ms, 9695 B
```

**Setenta e cinco, e o LCP passa de quatro segundos.** A página inicial mostra cem cursos e uma linha
dizendo quantos mais existem, desde a aula 5, então a página que a pessoa vê é pequena. O que não é
pequeno é a resposta: a primeira requisição tem mais de seiscentos kilobytes.

## Lendo os insights

O primeiro insight é o que importa aqui. **Document request latency** trata da primeira requisição, o
HTML, que todo o resto espera, e a economia estimada dele é em kilobytes: no relatório HTML ele é uma
lista de três itens, e o que falha é *No compression applied*.

O tamanho tem duas causas, e as duas são aulas que você já leu:

- **o plano está na página.** O planner que hidrata, da aula 4, embute o plano inteiro como JSON para o
  script não buscá-lo de novo, e com cinco mil cursos o plano é a maior parte da página;
- **nada é comprimido.** O `server.ts` manda cada byte como está, e HTML e JSON são texto, que se
  comprime muito bem.

O `curl` mostra quanto. O primeiro número é a página como o `server.ts` a manda, o segundo são os
mesmos bytes passados pelo `gzip`, a compressão que todo navegador entende:

```
ana@dev:~/planner$ curl -s http://localhost:3000/ | wc -c
632855
ana@dev:~/planner$ curl -s http://localhost:3000/ | gzip | wc -c
54053
```

**A mesma página, com um doze avos do tamanho.** Nomes como `course-4182` se repetem milhares de
vezes, e repetição é o que a compressão tira.

Os outros insights são menores e pertencem a outras aulas: uma folha de estilo que bloqueia a primeira
pintura (aula 7), arquivos mandados sem tempo de cache (aula 9), e a corrente de requisições. A seção
"O que o relatório ainda diz" volta a eles. Antes, uma dúvida sobre os quatro segundos.
