---
title: Do push à página
version: 1
---

**Um front-end construído é uma pasta de arquivos, e publicá-lo é pôr essa pasta onde um navegador
possa pedi-la.** Para o app deste curso, e para a maioria dos apps de página única, é só isso. A pasta
tem uma página HTML, um ou mais scripts, folhas de estilo e os dados e imagens que o app lê. Nada disso
roda na máquina que serve. Roda no navegador de quem abre a página.

A imagem com que muita gente chega é a de um back-end: um deploy inicia um processo num servidor, e o
processo responde a cada requisição com algo que ele calcula. Um front-end estático não tem processo
assim. Todo o trabalho do servidor é achar um arquivo pelo caminho e devolvê-lo, e o programa que faz
isso foi escrito uma vez, por outra pessoa, e é o mesmo para todo site que ele serve.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"O caminho de um push até uma página. Um commit é enviado ao repositório. Uma máquina de build faz o checkout, roda npm ci e npm run build e grava a pasta dist, com index.html, um script, uma folha de estilo e courses.json. Só essa pasta sobe para o host, que a copia para servidores em muitas cidades. Um navegador pede cada arquivo à cópia mais próxima e roda o próprio app.\"><rect x=\"20\" y=\"40\" width=\"150\" height=\"130\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">repositório</text><text x=\"95\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">git push</text><rect x=\"190\" y=\"40\" width=\"150\" height=\"130\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"265\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">máquina de build</text><text x=\"265\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">npm ci</text><text x=\"265\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">npm run build</text><rect x=\"360\" y=\"40\" width=\"150\" height=\"130\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"435\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">dist/</text><text x=\"435\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">index.html</text><text x=\"435\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">assets/…js</text><text x=\"435\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">assets/…css</text><text x=\"435\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">courses.json</text><rect x=\"530\" y=\"40\" width=\"150\" height=\"130\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"605\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">host e CDN</text><line x1=\"170\" y1=\"105\" x2=\"190\" y2=\"105\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"190.0,105.0 182.6,108.1 182.6,101.9\" fill=\"var(--paper-dim)\"></polygon><line x1=\"340\" y1=\"105\" x2=\"360\" y2=\"105\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"360.0,105.0 352.6,108.1 352.6,101.9\" fill=\"var(--paper-dim)\"></polygon><line x1=\"510\" y1=\"105\" x2=\"530\" y2=\"105\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"530.0,105.0 522.6,108.1 522.6,101.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"560\" y=\"95\" width=\"22\" height=\"14\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><rect x=\"605\" y=\"120\" width=\"22\" height=\"14\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><rect x=\"650\" y=\"95\" width=\"22\" height=\"14\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><rect x=\"575\" y=\"145\" width=\"22\" height=\"14\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><rect x=\"635\" y=\"148\" width=\"22\" height=\"14\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"605\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">cópias em muitas cidades</text><line x1=\"605\" y1=\"172\" x2=\"605\" y2=\"200\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"605.0,200.0 601.9,192.6 608.1,192.6\" fill=\"var(--paper-dim)\"></polygon><rect x=\"530\" y=\"202\" width=\"150\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"605\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">o navegador roda</text><text x=\"20\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">você faz o primeiro passo;</text><text x=\"20\" y=\"216\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um host conectado faz os outros três</text></svg>", "caption": "Um front-end estático do push à página: o que vai para o ar é a pasta construída, e nada nela roda no host."}
```

## Os quatro passos, e quem faz cada um

1. **Você faz o push.** Um commit chega a um branch de um repositório no GitHub, no GitLab ou no
   Bitbucket. Tudo neste curso começa aí, e é por isso que o curso pede um repositório antes de
   qualquer outra coisa.
2. **Alguma coisa constrói.** Uma máquina que não é a sua faz o checkout do commit, instala as
   dependências a partir do lockfile e roda o comando de build, aqui `npm run build`. O build transforma
   TypeScript em JavaScript, junta os módulos em poucos arquivos e os grava em `dist/`. A aula 3 é sobre
   essa máquina.
3. **Os arquivos sobem.** O conteúdo de `dist/`, e nada mais, vai para o host. O código-fonte, o
   `node_modules` e o lockfile ficam para trás.
4. **O host responde.** Ele copia os arquivos para servidores em muitas cidades, a sua **CDN** (rede de
   distribuição de conteúdo), para que um leitor em Recife e outro em Lisboa recebam cada um de um lugar
   perto. Um pedido de `/assets/index-BVi82VJx.js` é respondido com esse arquivo, pela cópia mais
   próxima.

**O host faz os passos 2 a 4 por você** quando está conectado ao repositório, e é quase tudo o que os
quatro hosts desta aula vendem: eles observam um branch, constroem cada push e publicam o resultado. O
GitHub Pages é o diferente, porque só constrói por meio do GitHub Actions, num workflow escrito por
você; a seção sobre os passos de cada um mostra esse workflow.

## O que fica de fora

Alguns front-ends precisam, sim, de servidor: um que renderiza HTML a cada requisição, ou que responde
chamadas de API ao lado das páginas. Isso é renderização no servidor e funções, e as aulas 1 a 3 de
front-performance comparam essas opções. Tudo neste curso é o caso estático, porque é nele que cada uma
dessas abordagens ainda termina: uma pasta de arquivos construídos que alguém precisa servir.

## O que você terá no fim

Um app pequeno construído e servido no seu computador do jeito que um host o serve, a configuração que
cada um dos quatro hosts leria, e a única diferença entre eles que quebra um site no primeiro dia.
**Nenhum dos quatro é executado neste curso.** Cada um exige uma conta, e cada um muda as telas e o
plano gratuito no próprio ritmo. Os passos deles são citados da documentação de cada um e marcados como
não executados; o que você executa é tudo o que eles executariam por você.
