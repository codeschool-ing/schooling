---
title: O mesmo app, construído de dois jeitos
version: 1
---

**Tudo neste curso até aqui rodou como development build ou bundle de desenvolvimento.** Esse é o app que
um desenvolvedor vê, e ele difere do que as pessoas instalam de jeitos fáceis de esquecer:

| | desenvolvimento | release |
|---|---|---|
| JavaScript | texto, servido pelo Metro, recarregado ao salvar | bytecode do Hermes, dentro do app |
| `__DEV__` | `true` | `false`, e o código sob `if (__DEV__)` é removido |
| avisos e conferências | ligados: LogBox, avisos de props e de keys, invariantes extras | desligados |
| nomes | como foram escritos | minificados, nas partes que o minificador pode renomear |
| velocidade | mais lento, de propósito | tão rápido quanto vai ser |

**Um bug que só aparece em release quase sempre é uma de quatro coisas.** É uma conferência que só existia em
desenvolvimento e escondia um erro; um valor fixado na hora do build que era diferente na máquina que
construiu o release; código que dependia de um nome que o minificador mudou; ou dados que o release
encontra e o desenvolvimento nunca encontrou. Esta aula mostra a segunda e a quarta de verdade, já que são
as comuns.

O `npx expo export` constrói o mesmo bundle que um build poria no app, e o `--dev` constrói o de
desenvolvimento. Exporte os dois para Android e compare:

```
ana@dev:~/planner$ npx expo export --platform android --dev --output-dir dist-dev > /dev/null 2>&1
ana@dev:~/planner$ npx expo export --platform android --output-dir dist-release > /dev/null 2>&1
ana@dev:~/planner$ du -h dist-dev/_expo/static/js/android/* dist-release/_expo/static/js/android/*
8.3M	dist-dev/_expo/static/js/android/index-d41d8cd98f00b204e9800998ecf8427e.js
3.7M	dist-release/_expo/static/js/android/index-b1b560afedabb7d4252211b95eff52e0.hbc
ana@dev:~/planner$ grep -a -c 'Text strings must be rendered within a <Text>' dist-dev/_expo/static/js/android/* dist-release/_expo/static/js/android/*
dist-dev/_expo/static/js/android/index-d41d8cd98f00b204e9800998ecf8427e.js:1
dist-release/_expo/static/js/android/index-b1b560afedabb7d4252211b95eff52e0.hbc:0
```

**8,3 megabytes de texto JavaScript contra 3,7 de bytecode.** O bundle de desenvolvimento leva o código dos
avisos, do Fast Refresh e do depurador; o de release é minificado e compilado. E a frase que a aula 4
encontrou, *Text strings must be rendered within a `<Text>` component*, está no bundle de desenvolvimento
uma vez e no de release nenhuma: a conferência que a produz é só de desenvolvimento. Um erro que ela teria
pegado simplesmente está lá, no release, fazendo o que quer que faça.
