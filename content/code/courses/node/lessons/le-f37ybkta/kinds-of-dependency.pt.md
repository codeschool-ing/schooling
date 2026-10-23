---
title: Do que a produção precisa, e do que só você precisa
version: 1
---

**Uma dependência ou é algo que o servidor roda, ou é algo que só quem trabalha nele roda.** O npm
guarda os dois em campos separados, e essa separação é o que permite a uma instalação de produção
deixar o segundo tipo de fora:

| campo | o que vai nele | instalado em produção? |
|---|---|---|
| `dependencies` | o que o código importa quando roda: o Express | sim |
| `devDependencies` | ferramentas para trabalhar nele: um formatador, um linter, um auxiliar de testes | não |
| `peerDependencies` | para uma biblioteca: "eu funciono com a cópia de X que você tiver" | um servidor raramente declara uma |
| `optionalDependencies` | algo usado se instalar, pulado se falhar | sim, se der |

A única ferramenta de desenvolvimento do projeto é o **Prettier**, que formata o código para que
ninguém discuta espaços. Ele não tem dependências próprias, o que o torna um exemplo limpo:

```
ana@dev:~/server/links$ npm install --save-dev --save-exact prettier@3.9.10

added 1 package, and audited 67 packages in 373ms

29 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
ana@dev:~/server/links$ npm pkg get dependencies devDependencies
{
  "dependencies": {
    "express": "^5.3.0"
  },
  "devDependencies": {
    "prettier": "3.9.10"
  }
}
```

O `--save-dev` o pôs em `devDependencies`. **O `--save-exact` registrou `3.9.10` sem circunflexo**, o
que é certo para um formatador: uma versão minor nova pode formatar o mesmo arquivo de outro jeito, e
um arquivo reformatado num pull request que não mudou mais nada é ruído. Para uma biblioteca que o
servidor importa, o circunflexo com o lockfile é o arranjo comum; para uma ferramenta cuja saída é
comparada byte a byte, a versão exata é o certo.

## O que a produção instala

O `--omit=dev` instala, ou lista, sem a metade de desenvolvimento:

```
ana@dev:~/server/links$ npm ls --omit=dev
links@0.1.0 /home/ana/server/links
└── express@5.3.0
```

A árvore de produção tem o Express e não o Prettier. **Um servidor posto em produção com as
ferramentas de desenvolvimento dentro** carrega código que nunca roda, e cada pacote que ele carrega é
mais um que um alerta de segurança pode citar; a seção sobre o `npm ci` instala uma cópia de produção
desse jeito.

Um pacote no campo errado falha na outra direção também. Algo que o seu código importa, posto em
`devDependencies` por engano, funciona no seu notebook, onde tudo está instalado, e falha em produção
com `ERR_MODULE_NOT_FOUND` na primeira requisição que chegar ao import. Esse é mais um motivo para a
regra da aula 3 importar: com as declarações `import` no topo de cada arquivo, o pacote ausente para o
servidor na inicialização em vez de às três da manhã.
