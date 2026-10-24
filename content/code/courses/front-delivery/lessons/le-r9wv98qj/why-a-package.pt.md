---
title: Por que o design system vira um pacote
version: 1
---

**No dia em que um segundo produto precisa dos tokens e componentes do planner, eles precisam morar num
lugar de que os dois possam depender, com uma versão que diga qual estado deles cada um tem.** Até esse
dia, um design system dentro do seu único produto está bem. Depois dele, há três jeitos de compartilhá-lo,
e só um mantém um design system só.

## Três jeitos de compartilhar

| | como | o que acontece em um ano |
|---|---|---|
| **copiar** a pasta para o segundo app | `cp -r` | dois design systems que começaram iguais; um conserto num nunca chega ao outro |
| **um monorepo**, com os dois apps e a biblioteca num repositório | os workspaces do npm ligam a biblioteca a cada app | todo app usa sempre o commit mais recente da biblioteca, e uma mudança nela é testada contra todos ao mesmo tempo |
| **um pacote publicado** com versão | a biblioteca é publicada num registry; cada app instala uma versão | cada app passa para uma versão nova quando escolher, e a versão diz o que mudou |

**Copiar é o padrão e a armadilha.** Não custa nada no primeiro dia, e cada dia depois custa um pouco, sem
ninguém ver, até dois botões que deviam ser iguais não serem.

**Um monorepo** é uma escolha forte quando uma equipe cuida de todos os apps: a mudança num componente é
um pull request só que atualiza a biblioteca e toda tela que a usa, e o CI os testa juntos. O npm aceita
isso com **workspaces**, uma lista `workspaces` no `package.json` da raiz que liga cada pacote ao
`node_modules` dos outros. O custo é que todo app está sempre na biblioteca mais nova, estivesse pronto ou
não.

**Um pacote publicado** é o que esta aula monta, e aquilo em que a maioria das organizações com várias
equipes acaba: a biblioteca tem o próprio repositório e as próprias versões, e cada produto atualiza no
próprio ritmo. O preço é o assunto do resto da aula: versões que querem dizer algo, um registry para
publicar, e a disciplina de dizer o que cada versão mudou.

## O segundo produto

Imagine que a escola por trás do planner quer um segundo app, para professores, com a mesma cara. É o caso
que esta aula atende: os tokens, a escala tipográfica, os temas e os três componentes vão para um pacote
chamado `@planner/ui`, o planner o instala como qualquer outra dependência, e o app dos professores poderia
instalar a mesma versão amanhã.
