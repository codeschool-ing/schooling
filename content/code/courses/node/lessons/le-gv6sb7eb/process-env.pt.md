---
title: process.env
version: 1
---

**Todo processo começa com uma lista de nomes e valores dada por quem o iniciou, o ambiente, e o Node
a entrega a você como `process.env`.** O seu shell tem uma, e todo programa que ele inicia herda uma
cópia. É o jeito mais antigo de dizer algo a um programa sem mudar o código dele, e em servidores ainda
é o principal.

```
ana@dev:~/server/links$ node -p 'process.env.HOME'
/home/ana
ana@dev:~/server/links$ PORT=4000 node -p 'process.env.PORT'
4000
ana@dev:~/server/links$ echo "the shell: [$PORT]"
the shell: []
ana@dev:~/server/links$ node -p 'process.env.NOTHING'
undefined
ana@dev:~/server/links$ EMPTY= node -p 'JSON.stringify(process.env.EMPTY)'
""
ana@dev:~/server/links$ DEBUG=false node -p 'process.env.DEBUG ? "truthy" : "falsy"'
truthy
ana@dev:~/server/links$ export REGION=sa-east
ana@dev:~/server/links$ node -p 'process.env.REGION'
sa-east
```

As linhas dessa transcrição mostram os quatro fatos que importam:

- **Um nome definido antes do comando fica só no ambiente daquele programa**: `PORT=4000 node …` não
  muda o do próprio shell.
- **Um nome que ninguém definiu é `undefined`**, e um nome definido como nada é `""`. Os dois são
  diferentes, e o programa precisa decidir o que cada um significa.
- **Todo valor é uma string.** `DEBUG=false` chega como as cinco letras `"false"`, que são verdadeiras,
  então `if (process.env.DEBUG)` dá verdadeiro. A seção sobre ler a configuração transforma strings nos
  tipos de que o programa precisa, uma vez só.
- **O `export` põe um nome no ambiente do shell**, e todo programa iniciado por esse shell depois disso
  o enxerga, até o shell fechar.

Um processo pode mudar o próprio `process.env`, e os filhos dele herdam a mudança, mas nada do que ele
faz chega ao shell que o iniciou: o ambiente é copiado para baixo, nunca de volta para cima.
