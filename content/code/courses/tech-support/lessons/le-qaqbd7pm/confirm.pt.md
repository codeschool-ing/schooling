---
title: Confirmar: a mesma checagem, do lado do usuário
version: 1
---

O último passo repete o primeiro, no mesmo computador, com o mesmo comando:

```
ana@pc1:~$ getent hosts intranet; curl -sS -m 10 http://intranet/
10.30.0.31      intranet
intranet: welcome
```

O `pc1` agora acha `10.30.0.31` e a página responde. Confirmar tem três partes, e o comando é só a primeira:

- **A checagem do passo 1 passa.** Não uma checagem diferente e mais fácil: a mesma.
- **O usuário vê.** A Carla abre a intranet no próprio navegador. O defeito era dela, e a confirmação
  também; um chamado fechado sem isso muitas vezes é reaberto na manhã seguinte.
- **A causa fica anotada**: qual linha, o que dizia e por que estava errada. A mesma linha velha pode estar
  em outros computadores configurados na mesma época, e o chamado é onde o próximo técnico vai olhar,
  aula 5.
