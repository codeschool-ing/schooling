---
title: De onde vêm os valores num host
version: 1
---

**Num host que constrói por você, as variáveis vêm do painel dele, definidas por ambiente, e chegam ao
build como variáveis de ambiente comuns.** É por isso que o shell ganha de todo arquivo `.env`: um valor
digitado no painel passa por cima do que o repositório diz, sem ninguém editar arquivo nenhum. **Nada
nesta seção foi executado para este curso**; é o que a documentação de cada host descrevia em outubro de
2026.

## Por host

Os três hosts com previews deixam uma variável ter um valor para produção e outro para previews:

- **Vercel**: Project Settings, depois Environment Variables. Cada valor é marcado para Production,
  Preview, Development ou qualquer combinação. `npx vercel env pull` grava os valores de desenvolvimento
  num arquivo local, que é um arquivo `.local` pelo motivo que a última seção desta aula dá.
- **Netlify**: a configuração do site, em Environment variables, onde um valor pode mudar por **deploy
  context**: produção, deploy previews, branch deploys. Um valor que não é segredo pode morar no
  `netlify.toml`, onde é revisado junto com o código:

```toml
[context.deploy-preview.environment]
  VITE_TITLE = "Study planner (preview)"
```

- **Cloudflare Pages**: Settings do projeto, em Variables and Secrets, com um ambiente Production e um
  Preview.
- **GitHub Pages** não tem configuração própria para isso; quem constrói é o workflow, então é ele quem
  fornece os valores, a partir de **Settings, Secrets and variables, Actions** do repositório.

## Num workflow

O GitHub Actions guarda dois tipos de valor. **Variables** são configuração comum, lidas como
`vars.NAME`. **Secrets** são criptografados, lidos como `secrets.NAME`, e mascarados como `***` se um
passo imprimir um deles. Um passo recebe qualquer um dos dois pelo seu `env:`:

```yaml
      - name: Build
        run: npm run build
        env:
          VITE_TITLE: ${{ vars.SITE_TITLE }}
      - name: Deploy
        run: npx wrangler pages deploy dist
        env:
          CLOUDFLARE_API_TOKEN: ${{ secrets.CLOUDFLARE_API_TOKEN }}
```

Repare em qual passo recebe o quê. **O build recebe o título, que a página mostra. O deploy recebe o
token, que a página nunca pode ter.** O token não tem o prefixo `VITE_`, e é dado só ao passo que envia,
então não chega ao pacote por nenhum dos dois caminhos. É o prefixo e o cofre de segredos trabalhando
juntos, e é o formato que todo pipeline da aula 3 mantém.

Dois detalhes que o GitHub documenta e que surpreendem. Um workflow iniciado por um **pull request vindo
de um fork** não recebe os segredos do repositório, então o pull request de um estranho não consegue
imprimi-los; um preview que precisa de um segredo simplesmente falha ali. E o mascaramento só esconde um
segredo quando ele aparece exatamente como foi guardado: um segredo que um passo transforma, codifica ou
divide é impresso às claras.

## Previews ganham os próprios valores

Um build de preview é público no próprio endereço, e **um preview nunca deve ter um valor de produção que
importe**: nem a API de produção, nem uma chave com os limites de produção. Dê aos previews os valores de
staging, que é para isso que existem as configurações por ambiente acima. A aula 3 volta a isso, porque
um preview é o lugar mais fácil para dados de produção vazarem.
