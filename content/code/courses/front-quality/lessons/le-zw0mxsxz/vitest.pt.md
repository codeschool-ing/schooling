---
title: O Vitest, instalado e fixado
version: 1
---

**O Vitest é um executor de testes construído sobre o Vite: ele lê a configuração do próprio
projeto, entende TypeScript e imports do jeito que o app entende, e não precisa de mais nada para
começar.** É esse o motivo para escolhê-lo num projeto Vite. O Jest era o padrão antes dele, e a
seção sobre o Jest, perto do fim desta aula, mostra o que é preciso para rodar os mesmos testes lá.

Ele entra como dependência de desenvolvimento, na versão com que este curso foi gravado, a 5.0.5:

```
ana@dev:~/planner$ npm install --save-exact -D vitest@5.0.5

added 20 packages, and audited 39 packages in 3s

found 0 vulnerabilities
```

O `-D` o registra em `devDependencies`, porque o site publicado nunca precisa dele. Um script faz o
`npm test` rodar a suíte inteira uma vez e parar:

```
ana@dev:~/planner$ npm pkg set scripts.test="vitest run"
ana@dev:~/planner$ npm pkg get scripts
{
  "dev": "vite",
  "build": "tsc && vite build",
  "preview": "vite preview",
  "test": "vitest run"
}
```

O `vitest run` roda todos os testes e sai, que é o que você quer antes de um commit e o que um job de
CI roda. O `npx vitest` sem o `run` fica aberto, observa os arquivos, e roda de novo os testes que
uma mudança afeta cada vez que você salva; é o jeito de trabalhar enquanto escreve testes, e a tela
dele é o mesmo relatório que você vê abaixo, redesenhado.

## Onde ele procura

**Um arquivo de teste é qualquer arquivo cujo nome termina em `.test.ts`**, ou `.spec.ts`, em
qualquer lugar fora de `node_modules`. Este curso deixa cada um ao lado do arquivo que testa: o
`src/planner.test.ts` junto do `src/planner.ts`. Nada precisa ser registrado, e sem nenhum arquivo de
teste ainda não há nada para rodar:

```
ana@dev:~/planner$ npm test; echo "exit code $?"

> planner@0.0.0 test
> vitest run


 RUN  v5.0.5 /home/ana/planner

No test files found, exiting with code 1

include: **/*.{test,spec}.?(c|m)[jt]s?(x)
exclude:  **/node_modules/**, **/.git/**

exit code 1
```

Código de saída 1, e uma mensagem dizendo isso. **Uma execução de testes que não achou testes
falha**, e esse é o padrão certo: um erro de digitação no nome de um arquivo não deve parecer uma
suíte verde.
