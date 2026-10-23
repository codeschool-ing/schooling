---
title: Uma divergência, feita de propósito
version: 1
---

**24 de outubro de 2026 é um sábado, e a pessoa em São Paulo ouviu que é sexta.** O servidor estava
certo e o navegador errado, e a versão do navegador é a que ficou na tela, porque o script desenhou
por cima da página do servidor quando os dois discordaram. Dois bugs se encontraram aqui, e vale
separá-los, porque cada um é comum sozinho.

## Por que o navegador disse sexta

`new Date("2026-10-24")` não quer dizer "o dia 24 de outubro" para o JavaScript. Uma data escrita como
`YYYY-MM-DD` é lida como **meia-noite em UTC** daquele dia. O `toLocaleDateString` então mostra esse
instante no fuso de quem lê. Em UTC, onde o servidor rodava, meia-noite do dia 24 é dia 24. Em São
Paulo, três horas atrás, o mesmo instante é 21:00 do dia 23, uma sexta-feira.

Então a mesma função, com a mesma entrada, dá respostas diferentes em dois computadores, e a diferença
não está no código. **Tudo o que depende de onde ou de quando roda é uma divergência esperando para
acontecer**: o fuso horário, a língua, a hora atual, um número aleatório, a largura da janela, se
alguém está logado.

## Por que uma divergência importa

No planner o script percebeu, avisou e redesenhou. A pessoa viu o *Sat* do servidor ser trocado por
*Fri* alguns milissegundos depois, o que é uma piscada e uma resposta errada. Cada um dos quatro
frameworks da aula 2 confere a mesma coisa enquanto hidrata e avisa sobre uma divergência enquanto
você desenvolve; o que cada um faz com ela em produção difere, e já mudou entre versões, então é
assunto do curso de cada framework e não algo em que confiar.

O que é comum é a regra: **o servidor e o navegador têm de calcular o mesmo HTML a partir dos mesmos
dados**. Uma diferença nunca é um recurso da hidratação; é um bug da página, e o único bom lugar para
achá-lo é um teste que abre a página com um fuso e uma língua diferentes dos do servidor, que é
exatamente o que o `hydrate.ts` fez.

## A correção

Uma data de calendário não tem fuso horário, então mostre-a como uma. `timeZone: "UTC"` manda o
`toLocaleDateString` mostrar o instante em UTC, o fuso em que a data foi lida, em todo computador. No
`src/view.ts`, mude a linha que define `day`:

```typescript
const day = (date: string) => `${new Date(date).toLocaleDateString("en-GB", { weekday: "short", timeZone: "UTC" })} ${date}`;
```

Faça o build de novo, reinicie o `server.ts` com `TZ=UTC`, e abra a página de São Paulo mais uma vez:

```
ana@dev:~/planner$ node tools/hydrate.ts http://localhost:3000/courses/git
painted at 108 ms, taken over by the script at 76 ms
Sat 2026-10-24 · 25 min Mark done
Tue 2026-10-27 · 40 min Mark done
```

**Nenhum aviso, e sábado dos dois lados.** O mesmo erro em `mondayOf` teria posto uma sessão na semana
errada, e nunca pôs, porque a aula 1 escreveu o `planner.ts` para fazer a sua aritmética de datas em
UTC desde o começo. O comentário da aula 1 acima de `mondayOf` diz por quê: uma data é um dia de
calendário.
