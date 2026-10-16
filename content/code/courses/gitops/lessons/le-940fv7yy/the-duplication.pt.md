---
title: Dois arquivos que são quase o mesmo arquivo
version: 1
---

**A aula 5 deixou staging e produção como dois arquivos completos**, e o diff entre eles mostrou o
que cada ambiente é. Ele não mostrou o que os dois compartilham, que é a maior parte de ambos:

```
ana@laptop:~/fleet$ wc -l apps/bulletin/*/bulletin.yaml
  46 apps/bulletin/production/bulletin.yaml
  46 apps/bulletin/staging/bulletin.yaml
  92 total
ana@laptop:~/fleet$ diff apps/bulletin/staging/bulletin.yaml apps/bulletin/production/bulletin.yaml | grep -c '^<'
5
```

Dois arquivos de 46 linhas cada, que diferem em 5 delas, e as outras 41 estão
escritas duas vezes. **Toda linha escrita duas vezes é uma linha que um dia vai ser mudada uma vez
só.** O caminho de uma probe, uma porta, um rótulo acrescentado ao Deployment no staging para um teste
e nunca levado adiante: cada um faz a produção diferir do staging de um jeito que ninguém escolheu, e
o diff que mostrava o release em trânsito na aula 5 se enche deles.

Duas ferramentas tiram a duplicação, por lados opostos:

- **O Kustomize** parte de YAML simples, uma **base**, e descreve cada ambiente como um conjunto de
  mudanças sobre ela, um **overlay**. Nada é template; cada arquivo da base é um manifesto válido
  sozinho. Ele vem embutido no `kubectl` e no Argo CD e no Flux.
- **O Helm** parte de templates com buracos, um **chart**, e preenche os buracos com valores dados por
  instalação. Ele também é um formato de pacote e um instalador: um chart tem versão e é publicado, e
  uma instalação é um **release** que o Helm acompanha e consegue reverter.

Esta aula converte o `bulletin` para o Kustomize, que serve bem à aplicação do próprio time, e depois
escreve um chart pequeno do Helm da mesma aplicação, que é como a maior parte do software de terceiros
chega.
