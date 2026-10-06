---
title: Um rollback que ninguém rodou não funciona
version: 1
---

O caminho de volta só é usado em dias ruins, o que faz dele o caminho menos exercitado de todo o
pipeline. Aqui estão duas coisas sobre o `rollback.sh` fáceis de não ver até importarem.

## Voltar duas vezes vai para a frente

```
ana@laptop:~/shipquote$ ops/rollback.sh production
smoke: http://127.0.0.1:8300 is up and running 1.6.0
ana@laptop:~/shipquote$ readlink ~/envs/production/current ~/envs/production/previous
releases/shipquote-1.6.0
releases/shipquote-1.5.0
ana@laptop:~/shipquote$ ops/rollback.sh production
smoke: http://127.0.0.1:8300 is up and running 1.5.0
```

O `rollback.sh` troca `current` e `previous`, então um segundo rollback desfaz o primeiro: a
produção está **no 1.6.0 de novo**, o release com o bug. Alguém que roda duas vezes no susto, ou duas
pessoas que rodam uma vez cada, põem o bug de volta na frente dos clientes. O script só lembra um
passo para trás, e não faz ideia de qual dos dois releases era o bom.

## Na primeira vez não há para onde voltar

```
ana@laptop:~/shipquote$ ops/deploy.sh staging dist/shipquote-1.6.1.tar.gz
smoke: http://127.0.0.1:8200 is up and running 1.6.1
ana@laptop:~/shipquote$ ops/rollback.sh staging; echo "exit $?"
rollback: staging has no previous release
exit 1
ana@laptop:~/shipquote$ ls ~/envs/staging/releases
shipquote-1.6.1
```

O primeiro deploy num ambiente não deixa `previous`, e o script avisa e sai com 1. Esse é o
comportamento correto, e também uma surpresa para quem esperava um caminho de volta: a homologação
foi implantada uma vez só, então não há nada atrás dela.

## Ensaie

As duas surpresas são baratas de descobrir num dia calmo e caras durante um incidente. Equipes que
confiam no rollback fazem três coisas:

- **Rodam na homologação com frequência**, como parte de um release, não só quando algo quebra. Um
  rollback que rodou semana passada é um rollback que funciona.
- **Sabem para onde ele vai voltar antes de rodar.** O `readlink ~/envs/production/previous` responde
  isso no laboratório; uma ferramenta de deploy de verdade mostra a versão anterior e a idade dela.
- **Escrevem quem decide.** Uma pessoa decide o rollback, uma pessoa roda, todo o resto observa. Duas
  pessoas consertando o mesmo incidente em paralelo é como o rollback duplo acima acontece.
