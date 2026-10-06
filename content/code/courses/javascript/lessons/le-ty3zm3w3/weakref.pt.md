---
title: WeakRef e FinalizationRegistry
version: 1
---

Esta aula usou `WeakRef` para olhar as decisões do coletor. Ele também é uma ferramenta que programas
podem usar, junto com o **`FinalizationRegistry`**, que roda um callback algum tempo depois de um
objeto registrado ser coletado:

```javascript
const registry = new FinalizationRegistry((label) => console.log("collected:", label));

(function () {
  const cover = { image: new Array(100_000).fill(0) };
  registry.register(cover, "the cover of Iracema");
})();

console.log("cover dropped");
setTimeout(() => globalThis.gc(), 0);
setTimeout(() => console.log("done"), 100);
```

```
ana@dev:~/js$ node --expose-gc finalization.js
cover dropped
collected: the cover of Iracema
done
```

A capa só era alcançável dentro da função, então depois que a função retornou ela era lixo, e depois
da coleta **o callback do registro rodou com o rótulo que recebeu**. Ele não pode receber o próprio
objeto, já que o objeto não existe mais.

## Por que eles vêm por último

Esses dois existem para trabalhos raros, como liberar um recurso guardado fora do JavaScript quando o
objeto que o representa sumiu. **A própria especificação avisa para não depender deles**, por motivos
que o laboratório escondeu chamando `gc()` à mão:

- **quando a coleta acontece é escolha do motor**, e pode ser muito depois ou, para um programa que
  termina antes, nunca. Não há garantia de que um callback de finalização rode;
- código que se comporta diferente conforme um objeto já foi ou não coletado se comporta diferente de
  uma execução para outra e de um motor para outro, que é o tipo de bug mais difícil de achar.

Então a ordem de preferência é a ordem desta aula: **largue as referências na hora certa (limpe o
temporizador, remova o listener, limite o cache)**; use um `WeakMap` ou `WeakSet` (aula 5) quando os
dados devem seguir a vida de um objeto; e recorra a `WeakRef` e `FinalizationRegistry` só quando
nenhum desses consegue expressar o que você precisa.
