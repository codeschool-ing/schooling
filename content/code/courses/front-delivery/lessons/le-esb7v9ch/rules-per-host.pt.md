---
title: As regras do planner, para cada host
version: 1
---

**O planner precisa de duas regras onde quer que seja servido: endereços antigos `/courses/` redirecionam
para `/course/`, e todo outro caminho é respondido com o `index.html`.** Cada host as recebe no próprio
arquivo e na própria sintaxe, e um não recebe nenhuma. **Nenhum destes arquivos foi executado no seu host
para este curso**; o primeiro é o que o `host.mjs` rodou nas duas últimas seções, e os outros seguem a
documentação de cada host.

## Netlify

O `public/_redirects` exatamente como está, copiado para `dist/` pelo build:

```
# public/_redirects
/courses/* /course/:splat 301
/* /index.html 200
```

A Netlify só aplica uma regra quando nenhum arquivo bate com o caminho, então `/*` nunca engole um script
de verdade. As mesmas duas regras podem morar no `netlify.toml`, como tabelas `[[redirects]]`, se você
preferir um arquivo só para todas as configurações da Netlify.

## Cloudflare Pages

O mesmo formato `_redirects`, com duas diferenças que importam aqui. Um site **sem `404.html` na raiz** é
tratado como app de página única por padrão: a documentação da Cloudflare diz que qualquer caminho que não
é arquivo é respondido com a página raiz. Então o planner só precisa da primeira linha lá. E a
documentação dela diz que redirecionamentos valem **havendo arquivo ou não**, o oposto da regra da
Netlify; uma linha ampla como `/*` é o tipo de regra que essa diferença transforma em problema, o que é
mais um motivo para deixar a segunda linha de fora na Cloudflare.

## Vercel

O `vercel.json` na raiz do repositório, na sintaxe da própria Vercel. `:id` é um parâmetro com nome, e
`permanent: true` pede um redirecionamento permanente:

```json
{
  "redirects": [{ "source": "/courses/:id", "destination": "/course/:id", "permanent": true }],
  "rewrites": [{ "source": "/(.*)", "destination": "/index.html" }]
}
```

A Vercel confere os arquivos do deploy antes de aplicar reescritas, então a regra que pega tudo deixa os
scripts de verdade em paz, como a da Netlify.

## GitHub Pages

Sem arquivo de regras, então sem redirecionamento para os endereços antigos e sem reescrita. O workflow
da aula 1 ganha um passo depois do build, a cópia `404.html` da seção anterior:

```yaml
      - name: Serve the app for unknown paths
        run: cp dist/index.html dist/404.html
```

Os links antigos `/courses/` só podem ser redirecionados pelo próprio app, no navegador: umas poucas
linhas no `main.ts` que reconhecem o formato antigo e chamam `history.replaceState` com o novo. Isso
funciona para pessoas e não faz nada pelos buscadores, que veem o 404.

## Escolhendo, de novo

| | endereços antigos | links profundos |
|---|---|---|
| Netlify | um 301 | uma reescrita, status 200 |
| Cloudflare Pages | um 301 | o comportamento padrão de página única, status 200 |
| Vercel | um 308 | uma reescrita, status 200 |
| GitHub Pages | só no código do próprio app | `404.html`, status 404 |

É a última seção da aula 1 vista do outro lado: **os arquivos são portáteis, as regras não**, e um app com
caminhos de verdade é o tipo de app cujas regras mais importam.
