---
title: O que é um ambiente de preview
version: 1
---

**Um preview é o site construído a partir do branch de um pull request e publicado num endereço próprio,
enquanto o site de verdade segue sem mudança.** Quem revisa abre um link em vez de fazer checkout do
branch, instalar e construir; uma designer vê a mudança num celular; um gerente de produto clica na tela
nova antes de alguém dizer que está pronta. É a revisão do que a mudança *faz*, ao lado da revisão do que o
código *diz*.

O erro comum é pensar num preview como um site de staging menor. Um site de staging é um lugar,
compartilhado, onde o branch principal chega antes da produção. **Um preview é um por pull request**,
criado quando o pull request abre, reconstruído a cada push nele, e jogado fora quando ele fecha. Dez pull
requests abertos são dez previews, lado a lado, nenhum atrapalhando os outros.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"O branch main é construído para o endereço de produção. Três pull requests abertos são construídos cada um num endereço próprio, lado a lado, sem tocar a produção nem uns aos outros. Quando um pull request fecha, o preview dele vai embora.\"><rect x=\"20\" y=\"30\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">main</text><line x1=\"170\" y1=\"52\" x2=\"300\" y2=\"52\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"300.0,52.0 292.6,55.1 292.6,48.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"302\" y=\"30\" width=\"398\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"320\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">planner.pages.dev</text><text x=\"690\" y=\"52\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">produção</text><rect x=\"20\" y=\"86\" width=\"150\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"30\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">PR #12</text><text x=\"160\" y=\"100\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fix-week</text><line x1=\"170\" y1=\"100\" x2=\"300\" y2=\"100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><polygon points=\"300.0,100.0 292.6,103.1 292.6,96.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"302\" y=\"86\" width=\"398\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"320\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">a1b2c3d4.planner.pages.dev</text><text x=\"690\" y=\"100\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">preview</text><rect x=\"20\" y=\"122\" width=\"150\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"30\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">PR #13</text><text x=\"160\" y=\"136\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">green-heading</text><line x1=\"170\" y1=\"136\" x2=\"300\" y2=\"136\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><polygon points=\"300.0,136.0 292.6,139.1 292.6,132.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"302\" y=\"122\" width=\"398\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"320\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">e5f6a7b8.planner.pages.dev</text><text x=\"690\" y=\"136\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">preview</text><rect x=\"20\" y=\"158\" width=\"150\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"30\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">PR #14</text><text x=\"160\" y=\"172\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">durations</text><line x1=\"170\" y1=\"172\" x2=\"300\" y2=\"172\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><polygon points=\"300.0,172.0 292.6,175.1 292.6,168.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"302\" y=\"158\" width=\"398\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"320\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">c9d0e1f2.planner.pages.dev</text><text x=\"690\" y=\"172\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">preview</text></svg>", "caption": "Um preview por pull request, cada um no próprio endereço; a produção só muda quando o main muda.", "same": ["preview"]}
```

## Como os hosts fazem

Vercel, Netlify e Cloudflare Pages constroem previews assim que o repositório está conectado, como a aula
1 disse, e cada um põe o endereço do preview no pull request, como comentário ou como o link de uma
conferência. Os endereços deles seguem um padrão:

| host | o endereço de um preview |
|---|---|
| Vercel | um endereço único por deploy em `.vercel.app`, mais um que segue o branch |
| Netlify | `deploy-preview-<number>--<site>.netlify.app`, o número do pull request |
| Cloudflare Pages | `<hash>.<project>.pages.dev` por deploy, e `<branch>.<project>.pages.dev` seguindo o branch |

Dois tipos de endereço aparecem aí, e a diferença importa. **Um endereço de deploy nunca muda o que
mostra**: é aquele build, para sempre, então um link num comentário de revisão continua mostrando o que
foi revisado. **Um endereço de branch segue o push mais recente**, e é o que se manda a alguém que precisa
ver o estado atual. Nenhum deles é o endereço de produção, e nenhum é executado aqui; são o que a
documentação dos hosts descreve.

## O que um preview não é

Não é um ambiente de testes com dados próprios. Os previews do planner leem o mesmo `courses.json` que o
branch carrega, o que está certo. Um app que fala com uma API precisa decidir com qual API um preview
fala, e a resposta nunca é a de produção: a aula 2 deu aos previews os valores de staging, e a última
seção desta aula diz por que essa decisão é de segurança.
