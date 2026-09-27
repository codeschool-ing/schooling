---
title: A armadilha do seu lado: comigo funciona
version: 1
---

A técnica conecta no computador do Bruno, o `pc1`, e imprime uma página de teste:

```
ana@pc1:~$ lpstat -d; echo "a test page" | lp
system default destination: office
request id is office-3 (0 file(s))
```

A impressora padrão do sistema é `office`, e a página de teste foi aceita ali. A tentação é parar aqui e
responder *"imprimi do seu computador e funcionou"*, o que diz ao Bruno que ele está errado sobre algo que
ele viu falhar.

O teste rodou **como `ana`**, a técnica, e não como o Bruno. No mesmo computador, duas pessoas podem ter
configurações diferentes, permissões diferentes, arquivos diferentes e padrões diferentes. **Reproduza
como o usuário, ou você reproduziu o problema de outra pessoa**: é o primeiro passo da aula 1, aplicado a
*quem*, não só a *onde*.
