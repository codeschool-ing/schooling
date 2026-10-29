---
title: O prefixo que decide o que chega ao navegador
version: 1
---

**O Vite só põe uma variável no pacote se o nome dela começa com `VITE_`.** Todo o resto do ambiente e
dos arquivos `.env` fica de fora, peça o código o que pedir. O prefixo é uma cerca entre dois tipos de
valor que moram nos mesmos arquivos e no mesmo shell: os que são para a página, e os que são para a
máquina que a constrói, como um token de uma ferramenta de deploy ou a senha de um registry.

## Uma variável sem o prefixo

Ponha uma variável sem o prefixo no `.env.local`, e faça o planner imprimi-la, como uma linha de código
descuidada faria:

```
ana@dev:~/planner$ echo 'SUPPORT_TOKEN=tok-demo-not-a-real-secret' > .env.local
ana@dev:~/planner$ echo 'console.log("token:", import.meta.env.SUPPORT_TOKEN);' >> src/main.ts
ana@dev:~/planner$ npm run build > /dev/null
ana@dev:~/planner$ grep -o 'token:[^)]*' dist/assets/*.js
token:`,void 0
```

O valor nunca chegou ao pacote. O Vite viu `import.meta.env.SUPPORT_TOKEN`, não achou variável exposta
com esse nome e escreveu `void 0`, que em JavaScript quer dizer `undefined`. **O código pediu e o build
se recusou a entregar**, sem erro, porque uma variável ausente é algo normal para um código perguntar.

## Desligando a cerca

O prefixo é uma opção, `envPrefix` no `vite.config.ts`, e pode ser trocado por outra palavra. Não pode
ser removido. Defina-o como uma string vazia, o que exporia toda variável que o build enxerga, e o Vite
para:

```
ana@dev:~/planner$ echo 'export default { envPrefix: "" };' > vite.config.ts
ana@dev:~/planner$ npx vite build 2>&1 | head -2
error during build:
Error: envPrefix option contains value '', which could lead unexpected exposure of sensitive information.
```

A mensagem diz o motivo. Remova o arquivo de novo; o planner fica com o padrão do Vite:

```
ana@dev:~/planner$ rm vite.config.ts
```

## O que o prefixo não protege

O prefixo decide o que o build copia para o pacote. Não diz nada sobre se o valor deveria estar lá. Uma
variável chamada `VITE_` qualquer coisa é copiada **porque o nome dela diz isso**, e o nome é a única
coisa para a qual o Vite olha. A próxima seção mostra o que isso significa para a linha de código acima,
quando alguém a "conserta" do jeito óbvio.

Outras ferramentas de build usam a mesma ideia com outros nomes: `NEXT_PUBLIC_` no Next.js, `NG_APP_` em
algumas configurações de Angular, `PUBLIC_` no SvelteKit, `VITE_` em projetos Vue e React construídos com
o Vite. Seja qual for a palavra, ela marca um valor que você aceitou publicar.
