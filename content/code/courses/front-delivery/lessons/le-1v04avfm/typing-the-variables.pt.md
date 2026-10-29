---
title: Tipando as variáveis, para uma com erro de digitação falhar o build
version: 1
---

**Por padrão, o TypeScript deixa você ler qualquer nome de `import.meta.env`, e um nome digitado errado
é simplesmente `undefined`.** É o pior tipo de erro para uma configuração: nada falha, o valor padrão
assume em silêncio, e um site de staging começa a se chamar de produção. Os tipos do Vite permitem um
modo mais estrito em que só existem as variáveis que você declara, e um erro de digitação para o build.

## O erro, sem conferência

Troque duas letras no `env.ts` e construa o modo de staging:

```
ana@dev:~/planner$ sed -i 's/VITE_TITLE/VITE_TITEL/' src/env.ts
ana@dev:~/planner$ npm run build -- --mode staging 2>&1 | tail -1
✓ built in 85ms
ana@dev:~/planner$ grep -o 'Study planner[^`]*' dist/assets/*.js
Study planner
```

O build deu certo, e o título de staging sumiu: `VITE_TITEL` não está definida em lugar nenhum, então o
`??` caiu no padrão, e nada disse uma palavra.

## Declarando as variáveis

O arquivo de tipos do próprio Vite declara `import.meta.env` com uma assinatura de índice, um coringa que
aceita qualquer nome, a menos que o projeto opte por sair dela. Optar por sair e listar a única variável
do planner é um arquivo curto:

```typescript
// src/vite-env.d.ts
interface ViteTypeOptions {
  strictImportMetaEnv: unknown;
}

interface ImportMetaEnv {
  readonly VITE_TITLE?: string;
}
```

`ViteTypeOptions` com `strictImportMetaEnv` dentro é o interruptor, e ele é escrito como declaração, e
não como opção, porque muda tipos, não comportamento. `ImportMetaEnv` então lista o que existe:
`VITE_TITLE`, opcional e string. O arquivo não precisa de import, porque as duas interfaces são globais
e os tipos do Vite as deixam abertas para serem estendidas.

**O nome importa.** Chamado `env.d.ts`, ao lado de `env.ts`, o arquivo seria lido como as declarações
*do* `env.ts` e pulado, e o build continuaria aceitando o erro de digitação sem uma palavra.
`vite-env.d.ts` é o nome que os próprios templates do Vite usaram para ele, e não colide com nada.

Construa a versão com o erro de novo:

```
ana@dev:~/planner$ npm run build -- --mode staging

> planner@0.0.0 build
> tsc && vite build --mode staging

src/env.ts(2,38): error TS2551: Property 'VITE_TITEL' does not exist on type 'ImportMetaEnv'. Did you mean 'VITE_TITLE'?
```

**O erro agora é um erro de tipo**, com o arquivo, a linha e o nome, e o `tsc` para o build antes de o
Vite rodar. Acerte o nome e o build passa:

```
ana@dev:~/planner$ git checkout src/env.ts
Updated 1 path from the index
ana@dev:~/planner$ npm run build -- --mode staging 2>&1 | tail -1
✓ built in 198ms
ana@dev:~/planner$ grep -o 'Study planner[^`]*' dist/assets/*.js
Study planner (staging)
ana@dev:~/planner$ git add src/vite-env.d.ts
ana@dev:~/planner$ git commit -qm "Declare the variables the planner reads"
```

Daqui em diante, **acrescentar uma variável quer dizer acrescentar uma linha ao `vite-env.d.ts`**. A aula
9 acrescenta o endereço de um servidor GraphQL e a aula 11 o nome de uma versão, e cada um entra neste
arquivo antes de qualquer código lê-lo.
