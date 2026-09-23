---
title: Git Flow: branches de develop, release e hotfix
version: 1
---

O Git Flow foi descrito em 2010 para um tipo específico de software: **produtos entregues como versões
numeradas**, em que a versão 1.1 é preparada, testada e lançada como uma unidade, e a versão 1.0
continua recebendo correções enquanto isso. Software de computador, apps de celular esperando a
revisão de uma loja, bibliotecas.

## As faixas

- **`main`** tem só versões lançadas. Todo commit nele é uma release, e recebe tag.
- **`develop`** é onde o trabalho terminado se junta para a próxima release.
- Branches **`feature/…`** começam no `develop` e voltam para ele.
- Branches **`release/…`** começam no `develop` quando uma versão está sendo preparada: só entram
  correções, depois ele entra no `main`, recebe a tag e volta para o `develop`.
- Branches **`hotfix/…`** começam no `main` para uma correção urgente numa versão lançada, e entram no
  `main` e no `develop`.

Aqui está um pequeno app de pedidos mantido assim: duas funcionalidades, uma release 1.1 e um hotfix
1.1.1:

```
ana@vm:~/app$ git branch
* develop
  main
ana@vm:~/app$ git log --oneline --graph --all
*   59d24ca Merge branch 'hotfix/1.1.1' into develop
|\  
* \   28f0220 Merge branch 'release/1.1' into develop
|\ \  
| | | *   aea0ad6 Merge branch 'hotfix/1.1.1'
| | | |\  
| | | |/  
| | |/|   
| | * | e0d054e Refuse pickup times before we open
| | |/  
| | *   c912762 Merge branch 'release/1.1'
| | |\  
| | |/  
| |/|   
| * | f641244 Prepare release 1.1
|/ /  
* |   e601e60 Merge branch 'feature/pickup' into develop
|\ \  
| * | 8d10f6a Let customers choose a pickup time
|/ /  
* |   086b150 Merge branch 'feature/basket' into develop
|\ \  
| |/  
|/|   
| * e6d8bcd Add a basket
|/  
* 3e9c870 Start the ordering app
ana@vm:~/app$ git tag
v1.0
v1.1
v1.1.1
```

São seis branches de trabalho, três releases, e **seis commits de merge para duas funcionalidades,
uma release e uma correção**. Tudo é rastreável: cada tag marca exatamente o que foi entregue, e o `main` nunca tem
nada que não foi lançado. O custo é igualmente visível: toda release e todo hotfix entram duas vezes,
o gráfico dá trabalho para ler, e quem desenvolve tem de lembrar de qual branch cada tipo de mudança
parte.

## Quando serve, e quando não

Serve quando **existem versões de verdade**: quando clientes rodam a 1.1 enquanto a 1.2 é preparada, e
uma correção na 1.1 não pode esperar as funcionalidades da 1.2. É pesado para um site ou uma aplicação
web publicada muitas vezes por dia, em que não existe *versão 1.1* em sentido nenhum — só o que está
rodando agora. A maioria das equipes web que adotaram o Git Flow nos anos 2010 já passou para uma das
duas formas mais simples, e o artigo que o descreveu ganhou uma nota em 2020 dizendo exatamente isso.

A lição que vale guardar não são as faixas. É a pergunta que elas respondem: **como o seu software
chega a quem o usa?** Um fluxo que combina com a resposta parece leve; um que não combina parece
cerimônia.
