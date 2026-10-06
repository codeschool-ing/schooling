---
title: Instalando a ferramenta de linha de comando
version: 1
---

A aula 1 disse que uma aula precisaria de uma ferramenta de linha de comando, e é esta. O Tailwind é um programa que lê o seu HTML, encontra os nomes de classe nele e escreve uma folha de estilos com uma regra para cada um. Ele roda em **Node.js**, o runtime de JavaScript que também roda a maior parte das ferramentas de build da web.

**Instale o Node.js** a partir de nodejs.org, na versão marcada como LTS, de suporte de longo prazo. Depois, num terminal, `node --version` deve imprimir um número de versão. No Linux e no macOS, um gerenciador de versões como o `nvm` é o caminho de costume, e o Windows tem um instalador.

**Instale o Tailwind na pasta do site.** Na pasta do seu site, o mesmo comando em todo sistema:

```bash
npm install tailwindcss@4.3.3 @tailwindcss/cli@4.3.3
```

O `npm` é o gerenciador de pacotes do Node, e baixa os dois pacotes para uma pasta `node_modules` ao lado dos seus arquivos. Fixar a versão com `@4.3.3` é o que este curso usou na gravação; sem isso você recebe a mais recente. Esta aula não cita o que o `npm install` imprime, porque isso depende da rede no dia.

**Escreva uma folha de entrada**, `input.css`, com uma linha:

```css
@import "tailwindcss";
```

**Rode o build.** O `npx` roda um comando de um pacote instalado. Aqui ele é rodado a partir de `~/site` no primeiro exemplo, uma página com o cartão acima; `--cwd first` faz da pasta `first` o lugar de onde ele lê e onde escreve:

```
ana@laptop:~/site$ npx @tailwindcss/cli --cwd first -i input.css -o out.css --silent
```

Ele não imprimiu nada, porque `--silent` pede que ele só fale de erros. Escreveu `first/out.css`, e a página aponta para esse arquivo com um `<link rel="stylesheet" href="out.css">` comum. Enquanto você trabalha, acrescente **`--watch`**, e o comando continua rodando e refaz o build toda vez que você salva um arquivo.
