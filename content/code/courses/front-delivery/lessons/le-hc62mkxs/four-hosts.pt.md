---
title: Quatro hosts, e o que cada um pede de você
version: 1
---

**Vercel, Netlify, Cloudflare Pages e GitHub Pages servem uma pasta de arquivos estáticos a partir de
uma CDN, por HTTPS, e para o planner qualquer um serve.** Onde eles diferem é em como a pasta chega até
eles, onde moram as regras deles, e o que fazem com um branch que não é o principal. Essas três
diferenças decidem qual arquivo de configuração fica no seu repositório, então vale conhecê-las antes de
escolher.

## Como o build chega até eles

Três deles **constroem por você**. Você conecta o repositório uma vez, pelo painel deles, e daí em
diante eles o observam: cada push passa por um checkout na máquina deles, `npm ci` e o comando de build
rodam, e a pasta de saída é publicada. Para um projeto Vite, a Vercel e o Cloudflare Pages oferecem um
preset que preenche `npm run build` e `dist` por você; a Netlify detecta os mesmos dois valores, ou os lê
de um arquivo que você commita.

**O GitHub Pages não constrói nada sozinho.** Ele publica um branch como está, ou o que um workflow do
GitHub Actions envia. Um projeto Vite precisa de build, então precisa do workflow, e a próxima seção
mostra o que a documentação do Vite oferece. Isso faz do GitHub Pages o mais trabalhoso de configurar e
aquele em que você consegue ler cada passo no seu próprio repositório.

Os quatro também aceitam uma pasta que você mesmo construiu. Vercel, Netlify e Cloudflare têm cada um uma
ferramenta de linha de comando para isso, e é assim que um pipeline de CI controlado por você publica
neles em vez de deixá-los construir.

## Onde moram as regras

Um host estático faz mais do que ligar um caminho a um arquivo: ele redireciona endereços antigos,
reescreve uns para outros e acrescenta cabeçalhos. A aula 4 escreve essas regras para o planner. O que
importa aqui é que cada host as lê de um lugar diferente:

| host | regras de redirecionamento e cabeçalhos |
|---|---|
| Vercel | `vercel.json`, na raiz do repositório |
| Netlify | `netlify.toml` na raiz, ou arquivos `_redirects` e `_headers` na pasta publicada |
| Cloudflare Pages | arquivos `_redirects` e `_headers` na pasta publicada |
| GitHub Pages | nenhum: sem redirecionamentos, sem reescritas, sem cabeçalhos que você possa definir |

O `_redirects` nasceu como formato da Netlify e o Cloudflare Pages lê o mesmo, então um arquivo escrito
para um funciona quase todo no outro. **O GitHub Pages não tem arquivo de regras nenhum**, e a aula 4
mostra o que isso custa a um app cujos endereços são caminhos de verdade.

## O que um branch ganha

**Vercel, Netlify e Cloudflare Pages constroem cada branch, ou cada pull request, num endereço próprio**,
para que quem revisa possa abrir a mudança antes do merge. Eles chamam isso de preview deployment ou
deploy preview, e a aula 3 é sobre isso. O branch principal, ou o branch que você chamar de produção, vai
para o endereço de verdade do site.

O GitHub Pages tem um site por repositório e publica uma coisa nele. Um preview de pull request é algo
que você mesmo monta, com um workflow e um segundo lugar para pô-lo.

## Onde cada um fica

| | Vercel | Netlify | Cloudflare Pages | GitHub Pages |
|---|---|---|---|---|
| constrói a partir do repositório | sim | sim | sim | só pelo Actions |
| arquivo de regras | `vercel.json` | `netlify.toml` ou `_redirects` | `_redirects`, `_headers` | nenhum |
| um preview por branch ou pull request | sim | sim | sim | não |
| um site na raiz do próprio endereço | sim | sim | sim | só para `<user>.github.io` ou um domínio próprio |
| um deploy pela linha de comando | `vercel` | `netlify deploy` | `wrangler pages deploy` | nenhum: pelo Actions |

**O guia do Vite agora lista o Cloudflare Workers antes do Cloudflare Pages**: o Workers é um produto mais
novo, que serve a mesma pasta e pode rodar código ao lado dela, e o Pages continua funcionando e é o que
a maioria dos tutoriais mostra. Produtos de hospedagem mudam assim, e esse é o assunto da última seção
desta aula.

Nada disso foi executado para este curso. A tabela é o que o guia de deploy do Vite e a documentação do
próprio Cloudflare diziam em outubro de 2026, e a próxima seção cita os passos.
