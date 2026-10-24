---
title: Um build só, ou um por ambiente
version: 1
---

**Um valor fixado no build quer dizer que um site com dois ambientes são dois builds**, e essa é uma
escolha com custo. O build de staging e o de produção do planner diferem numa variável, e por isso
diferem nos arquivos:

```
ana@dev:~/planner$ npm run build > /dev/null && ls dist/assets/*.js
dist/assets/index-sAFi8ckx.js
ana@dev:~/planner$ npm run build -- --mode staging > /dev/null && ls dist/assets/*.js
dist/assets/index-2shUX-Zw.js
```

Dois hashes diferentes. **O que foi conferido em staging não é, byte a byte, o que vai para produção**: a
produção é um segundo build do mesmo commit, feito depois, com outros valores. Quase sempre isso não tem
problema. De vez em quando é o incidente inteiro: uma dependência resolvida de outro jeito, uma variável
faltando num ambiente e não no outro, um build que funcionou na terça e falha na quinta.

## Construir uma vez e promover

A alternativa é construir uma vez e levar a mesma pasta de um ambiente para o seguinte, o que se chama
**promover** um build. Para isso funcionar, nada que difere entre ambientes pode estar dentro do pacote,
então precisa chegar por outro caminho: a página busca quando começa. Um arquivo pequeno ao lado do
`index.html`, gravado pelo deploy e não pelo build, guarda os valores:

```json
{ "title": "Study planner (staging)" }
```

e o app o lê antes de desenhar qualquer coisa. Isto é um padrão, não uma mudança no planner:

```typescript
const config = await fetch(`${import.meta.env.BASE_URL}config.json`).then((r) => r.json());
```

O deploy de cada ambiente copia o mesmo `dist/` e grava um `config.json` diferente ao lado.

| | um build por ambiente | um build só, promovido |
|---|---|---|
| onde mora um valor | no pacote | num arquivo buscado no início |
| o que chega à produção | um segundo build do mesmo commit | a pasta que foi testada |
| custo no início | nenhum | uma requisição a mais antes da primeira tela |
| um valor errado se corrige | construindo de novo | trocando um arquivo pequeno |
| o que os hosts fazem por padrão | Vercel, Netlify e Cloudflare Pages constroem cada ambiente separado | você monta, no seu próprio pipeline |

**Nenhum dos dois é um cofre de segredos.** O `config.json` é tão público quanto o pacote; ele é buscado
pelo mesmo navegador. A escolha é entre dois jeitos de publicar um valor, nunca entre publicar e não
publicar.

## O que este curso faz

O planner fica com um build por ambiente, porque é o que os três hosts com previews fazem por você e o
planner tem uma variável inofensiva. A pergunta vale ser feita de novo no dia em que um site tiver
muitas: quanto mais valores diferem entre ambientes, mais um build promovido economiza, e mais coisas um
segundo build tem para dar errado.
