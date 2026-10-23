---
title: Instalando o Storybook
version: 1
---

**O Storybook são quatro pacotes no projeto, fixados como todo o resto, e dois arquivos de configuração
numa pasta chamada `.storybook`.** O comando de configuração dele, `npm create storybook`, faz perguntas e
grava arquivos de exemplo; instalar os pacotes à mão é mais curto para um projeto deste tamanho e não deixa
nada que você não escolheu.

```
ana@dev:~/planner$ npm install --save-dev --save-exact storybook@10.6.3 @storybook/html-vite@10.6.3 @storybook/addon-docs@10.6.3 @storybook/addon-a11y@10.6.3 2>&1 | tail -3
  run `npm fund` for details

found 0 vulnerabilities
```

**Storybook 10.6.3**, em quatro partes: o programa em si; `@storybook/html-vite`, o framework para
componentes que devolvem DOM puro, construídos com o Vite; e dois addons, um para páginas de documentação e
um que roda o axe em cada story. Um projeto em React, Angular, Vue ou Svelte instala o pacote do framework
dele em vez do `html-vite`, e todo o resto desta aula é igual.

## Dois arquivos

O `main.ts` diz onde estão as stories e o que o Storybook carrega:

```typescript
// .storybook/main.ts
import type { StorybookConfig } from "@storybook/html-vite";

const config: StorybookConfig = {
  framework: "@storybook/html-vite",
  stories: ["../src/**/*.stories.ts"],
  addons: ["@storybook/addon-docs", "@storybook/addon-a11y"],
  core: { disableTelemetry: true },
};

export default config;
```

`disableTelemetry` impede o Storybook de mandar dados de uso para quem o faz, o que ele faz por padrão e
diz na documentação. Mandar ou não é escolha sua; o curso desliga para nada nestas aulas falar com um
servidor que você não pediu.

O `preview.ts` prepara o quadro em que cada story é desenhada. Por enquanto ele só carrega a folha de
estilo do planner, para uma story parecer como parece no app; a seção sobre temas acrescenta coisas a ele:

```typescript
// .storybook/preview.ts
import type { Preview } from "@storybook/html-vite";
import "../src/style.css";

const preview: Preview = {
  tags: ["autodocs"],
};

export default preview;
```

Acrescente dois scripts, um para rodar a oficina enquanto você trabalha e outro para construí-la:

```
ana@dev:~/planner$ npm pkg set scripts.storybook="storybook dev -p 6006" scripts.build-storybook="storybook build"
```

`npm run storybook` a inicia na porta 6006 e abre uma aba do navegador; ele imprime um quadro, *Storybook
ready!*, com o endereço, `http://127.0.0.1:6006/`. Ainda não há stories, então não há nada para mostrar; a
próxima seção escreve a primeira.

Duas pastas que ele grava não devem ir para o commit: o build estático, `storybook-static`, e os
resultados que o Playwright deixa na seção sobre testes. Acrescente-as ao `.gitignore` agora:

```
ana@dev:~/planner$ printf 'storybook-static\ntest-results\nplaywright-report\n' >> .gitignore
```
