---
title: O que um serviço rodando diz e o código dele não diz
version: 1
---

Uma imagem comum de análise dinâmica é a de uma análise estática feita mais tarde: os mesmos bugs,
achados por uma segunda ferramenta, alguns minutos adiante no pipeline. **As duas leem coisas
diferentes, e por isso acham defeitos diferentes.** Um analisador estático lê os arquivos do
repositório. Um analisador dinâmico não lê nenhum deles. Ele sobe o serviço, manda requisições como
um navegador mandaria e julga o que volta.

Essa diferença decide todo o resto desta aula: o que o DAST acha, em que ponto do pipeline ele pode
rodar, do que ele precisa para rodar e o que ele nunca vai ver.

### O que só o serviço rodando pode contar

Alguns defeitos não estão escritos em linha nenhuma. O linkbox da aula 3 responde à página inicial,
como a próxima seção captura, com um cabeçalho que diz `Server: gunicorn` e sem nenhum dos cabeçalhos
que um navegador usa para proteger a página. Três coisas nessa resposta vêm de fora do `app.py`. O
cabeçalho `Server` é acrescentado pelo servidor que o Dockerfile inicia, que não é código escrito
pelo projeto. Os cabeçalhos que **faltam** faltam porque nenhuma linha os define, e uma ausência não
é algo que um padrão sobre código-fonte encontre bem: o Bandit e o Semgrep, como a aula 3 os
configurou, não levantam nada sobre isso. E o fato de o serviço responder pelo gunicorn, e não pelo
servidor de debug do Flask, é uma propriedade da imagem, decidida em outro arquivo e em outra
linguagem.

**O DAST lê a coisa implantada, então vê o que a implantação acrescentou e o que ela deixou de
fora.** Cabeçalhos, flags de cookie, páginas de erro, redirecionamentos, o que o servidor diz de si
mesmo, se uma página de debug está acessível. Tudo isso pode estar certo no código e errado no
serviço rodando, ou o contrário.

### O que só o código pode contar

O scanner vê o que alcança, e só isso. Na aula 3, o Bandit apontou o SQL da busca porque leu a linha
que juntava o texto digitado à consulta. Um scanner dinâmico só acharia esse defeito mandando à busca
a entrada certa e reconhecendo a falha, e a varredura que esta aula roda não manda nada feito para
provocar uma. Uma rota que o scanner nunca acha, um desvio que depende de um valor específico, um
endpoint atrás de um token: para o DAST, nada disso existe.

E quando ele acha algo, **um achado dinâmico não tem número de linha**. Ele cita uma URL, a
requisição que mandou e a parte da resposta que disparou a regra. Achar o código responsável é
trabalho seu, barato num serviço de um arquivo curto e caro num de quatrocentos arquivos.

| | análise estática (aula 3) | análise dinâmica (esta aula) |
|---|---|---|
| o que lê | os arquivos-fonte | respostas HTTP de uma instância rodando |
| precisa de | o repositório | uma imagem construída, iniciada onde possa ser alcançada |
| vê | cada linha, alcançada ou não | só as páginas e os parâmetros que acha |
| acha bem | código sujeito a injeção, chamadas perigosas, segredos no código | cabeçalhos ausentes, flags de cookie, banners de servidor, páginas de erro, configuração |
| não vê | como o serviço é implantado e o que o servidor acrescenta | código que nunca alcança, e qual linha é a culpada |
| um achado cita | um arquivo e uma linha | uma URL e a evidência na resposta |
| os falsos positivos dela | um padrão que bateu com código seguro | uma heurística que leu mal uma resposta |

### Onde cada uma roda

A análise estática só precisa do checkout, então roda cedo, em todo push, antes de a imagem existir.
A análise dinâmica precisa de alguém com quem conversar: a imagem construída, um contêiner iniciado,
o serviço pronto para responder. **Ela só pode rodar depois do build, contra uma instância feita
para ela**, e a figura põe as duas no mesmo pipeline.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"sp-l04-reads\" aria-label=\"Análise estática e dinâmica postas no mesmo pipeline. Os arquivos-fonte viram uma imagem, que roda como serviço no staging. A análise estática lê cada linha dos arquivos e não vê o servidor, os cabeçalhos nem a configuração. A análise dinâmica manda requisições ao serviço rodando e lê as respostas, e não vê código que nunca alcança nem qual linha é a culpada.\"><defs><marker id=\"sp-l04-reads-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"sp-l04-reads-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"37.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">análise estática</text><text x=\"120.0\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">lê cada linha</text><rect x=\"480\" y=\"20\" width=\"220\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"590.0\" y=\"37.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">análise dinâmica</text><text x=\"590.0\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">manda requisições, lê respostas</text><rect x=\"20\" y=\"110\" width=\"150\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">arquivos-fonte</text><text x=\"95.0\" y=\"147.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o repositório</text><rect x=\"210\" y=\"110\" width=\"110\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"265.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">build</text><text x=\"265.0\" y=\"147.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ci/build.sh</text><rect x=\"360\" y=\"110\" width=\"150\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"435.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">imagem</text><text x=\"435.0\" y=\"147.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">linkbox:&lt;commit&gt;</text><rect x=\"550\" y=\"110\" width=\"150\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"625.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">serviço rodando</text><text x=\"625.0\" y=\"147.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">no staging</text><path d=\"M170 138 L208 138\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l04-reads-ah-paper-dim)\"></path><path d=\"M320 138 L358 138\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l04-reads-ah-paper-dim)\"></path><path d=\"M510 138 L548 138\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l04-reads-ah-paper-dim)\"></path><path d=\"M95 70 L95 108\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l04-reads-ah-phosphor)\"></path><path d=\"M600 70 L600 108\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l04-reads-ah-phosphor)\"></path><path d=\"M650 108 L650 70\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l04-reads-ah-phosphor)\"></path><text x=\"588\" y=\"89\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">requisições</text><text x=\"662\" y=\"89\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">respostas</text><rect x=\"20\" y=\"195\" width=\"300\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"170.0\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">não vê</text><text x=\"170.0\" y=\"229.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o servidor, os cabeçalhos, a configuração</text><rect x=\"400\" y=\"195\" width=\"300\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"550.0\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">não vê</text><text x=\"550.0\" y=\"229.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">código que não alcança, a linha culpada</text><line x1=\"95\" y1=\"166\" x2=\"95\" y2=\"195\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><line x1=\"625\" y1=\"166\" x2=\"625\" y2=\"195\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line></svg>", "caption": "A análise estática lê os arquivos antes de qualquer build; a dinâmica precisa do serviço construído e rodando, e pergunta a ele de fora.", "same": ["build"]}
```

A instância contra a qual ela roda é o assunto da próxima seção, porque é ali que se cometem quase
todos os erros com DAST. Apontada para um servidor de testes compartilhado, uma varredura relata o
estado que outra pessoa deixou ali. Apontada para produção, uma varredura passiva é inofensiva, e o
outro tipo, que a última seção desta aula explica, não é.

### Por que este pipeline precisa das duas

Os defeitos com que o linkbox foi entregue se dividem certinho entre as duas. O SQL da busca e o
servidor de debug eram linhas, e a aula 3 os achou lendo. Os cabeçalhos são uma ausência em toda
resposta, e esta aula os acha perguntando. Nenhuma das duas ferramentas teria achado os da outra. Um
time que roda uma só e dá o trabalho por feito decidiu, sem dizer, qual metade dos próprios defeitos
aceita não conhecer.
