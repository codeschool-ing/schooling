---
title: Planos gratuitos, e como escolher
version: 1
---

**Os quatro hosts servem de graça um site como o planner, e os quatro podem mudar isso no próprio
ritmo.** Um plano gratuito é uma decisão de negócio de outra pessoa, e ela é revista: limites mudam,
recursos passam para planos pagos, produtos são renomeados ou substituídos. É por isso que este curso não
cita limites nem preços. Um número escrito aqui em outubro de 2026 estaria errado em algum lugar antes de
você o ler.

**O passo a passo de pôr um projeto num plano gratuito, com domínio, é a aula 15 de
portfolio-project**, e é essa aula que você segue quando publicar o planner, ou qualquer outra coisa,
para as pessoas verem. Ela diz o que conferir nas páginas atuais do próprio provedor antes de confiar num
plano gratuito: se ele dorme, se ele expira, se ele pede cartão, onde ficam os seus dados e como você
sai. Esta seção acrescenta só o que é particular a um front-end estático.

## O que um site estático gasta

Um site estático não tem processo para manter rodando, então os limites que um back-end encontra
primeiro (memória, horas no ar, um servidor que dorme) não se aplicam. O que um host estático conta, em
vez disso, é:

- **banda**: quantos bytes saem da CDN dele num mês. O planner tem poucos kilobytes e nunca chega perto;
  um site cheio de imagens ou vídeos grandes pode chegar.
- **minutos de build**: quanto tempo as máquinas dele passam rodando o seu build. Com previews ligados,
  cada push em cada branch é um build, e é por isso que a aula 3 roda as conferências antes do deploy, e
  não depois.
- **quantos sites, membros ou deploys** uma conta pode ter.
- **para que o plano gratuito pode ser usado.** Leia os termos, não a página de preços. A Vercel já
  descreveu o plano gratuito dela como sendo para projetos pessoais e não comerciais; o GitHub escreveu
  que o Pages não serve para tocar um negócio online. Um portfólio cabe nos quatro; uma loja é outra
  conversa.

## Escolhendo

Para o app deste curso, a escolha é sobre como você quer trabalhar, não sobre o que o host consegue
fazer:

| se você quer | escolha |
|---|---|
| cada passo no seu próprio repositório, e nenhuma segunda conta | GitHub Pages, com o workflow de duas seções atrás |
| um preview para cada pull request, sem workflow para escrever | Vercel, Netlify ou Cloudflare Pages |
| que o mesmo arquivo `_redirects` funcione em dois hosts | Netlify ou Cloudflare Pages |
| construir no seu próprio CI e enviar o resultado | qualquer um dos três com ferramenta de linha de comando |

## Deixe a saída aberta

**O projeto é portátil enquanto as regras do host morarem no repositório.** `dist/` é a mesma pasta em
todo host; o que prende um site a um deles é configuração digitada num painel: um redirecionamento, uma
variável de ambiente, uma opção de build. Cada uma dessas é um fato sobre o seu site que mora só no banco
de dados de outra pessoa, onde ninguém revisa e ninguém vê mudar.

Então a regra para o resto deste curso é a que os quatro hosts tornam possível: **o que pode ser um
arquivo no repositório é um arquivo no repositório**. `netlify.toml`, `vercel.json`, `_redirects`, o
workflow do GitHub Pages. A aula 2 é sobre a única coisa que não deve ser: um segredo.
