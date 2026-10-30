---
title: Um valor fixado na hora do build
version: 1
---

Desde a aula 10 o planner acha o servidor com uma linha do `src/api.ts`:

```ts
const BASE = process.env.EXPO_PUBLIC_API_URL ?? "http://localhost:8008";
```

**O `process.env.EXPO_PUBLIC_…` não é lido quando o app roda.** Um celular não tem variáveis de ambiente para
um app; o Metro troca a expressão pelo valor da variável, como texto, quando constrói o bundle. Procure o
endereço no bundle de release exportado há pouco, e depois construa um com a variável definida:

```
ana@dev:~/planner$ grep -a -o 'http://localhost:8008' dist-release/_expo/static/js/android/*
http://localhost:8008
ana@dev:~/planner$ EXPO_PUBLIC_API_URL=https://planner.example.org npx expo export --platform android --output-dir dist-env > /dev/null 2>&1
ana@dev:~/planner$ grep -a -o 'https://planner.example.org\|http://localhost:8008' dist-env/_expo/static/js/android/*
https://planner.example.org
```

**O primeiro release leva `http://localhost:8008`**, o valor de reserva, porque a variável não estava
definida no terminal que o construiu. Num celular, `localhost` é o próprio celular, onde nenhum servidor
roda, então toda requisição falha, e o development build do próprio desenvolvedor, iniciado num terminal que
tinha a variável, funciona perfeitamente. **O segundo leva `https://planner.example.org` e nenhum valor de
reserva**: o valor foi fixado, e o `??` sumiu junto com o caminho que não podia mais acontecer.

Esse é o bug mais comum desta aula inteira: um release construído em outra máquina, um servidor de build ou
o laptop de um colega, sem a variável. Três hábitos o evitam:

- **Nunca deixe o valor de reserva funcionar em nada além da sua própria máquina.** O `localhost` parece
  inofensivo e é exatamente o que deixa o bug silencioso.
- **Escreva os valores do release onde o release é construído**, no ambiente do serviço de build, que a
  aula 20 mostra para o EAS Build, e não num terminal que alguém precisa lembrar de preparar.
- **Lembre que é público.** O `EXPO_PUBLIC_` quer dizer o que diz: o valor é texto dentro do app, legível
  por qualquer um que o desempacote, como o `grep` acabou de fazer. Um endereço tudo bem. Um segredo nunca
  vai aí.

As três exportações podem ir embora: `rm -rf dist-dev dist-release dist-env`.
