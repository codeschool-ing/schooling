---
title: O React Compiler, e por que esta aula ainda importa
version: 1
---

**O React Compiler 1.0 faz boa parte do que o `useMemo` e o `useCallback` fazem, automaticamente, no
build.** Ele lê os seus componentes, descobre quais valores podem ser mantidos entre renderizações e
insere o cache sozinho. O time do React o lançou como estável no fim de 2025, e no npm hoje ele é o
`babel-plugin-react-compiler` na versão 1.0.0; a versão do `@vitejs/plugin-react` que este curso
fixou na aula 1 o lista como acompanhante opcional. A aula 21 o liga no planejador e mede o que ele
muda.

Isso levanta uma pergunta justa: por que aprender os hooks que ele escreve por você?

- **Porque ele depende das regras.** O compilador supõe que os seus componentes são puros e seguem as
  regras dos hooks. Um componente que muta as props ou lê um ref durante a renderização é um que ele
  pula ou erra, então tudo das aulas 2 a 6 agora também é o que mantém o compilador funcionando.
- **Porque o código existente está cheio deles.** A maior parte do código React que um emprego vai
  entregar a você foi escrita antes do compilador, e o `useMemo` e o `useCallback` estão nele, alguns
  necessários, outros não. Distinguir uns dos outros é a habilidade desta aula.
- **Porque o `useRef` não é opcional.** O compilador guarda valores; ele não foca um título nem guarda
  o id de um timer. Refs e hooks próprios são projeto, não otimização, e ficam.

Então a ordem do trabalho é a mesma com ele ou sem ele: escreva componentes puros que seguem as
regras, use um ref quando algo precisa ser lembrado sem ser desenhado, extraia um hook próprio quando
um componente carrega duas preocupações, e memorize só onde a identidade importa ou uma medição
manda, o que então o compilador faz por você na maioria dos lugares.
