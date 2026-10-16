---
title: O caminho pavimentado: o jeito suportado, feito o jeito mais fácil
version: 1
---

Um **caminho pavimentado** (*golden path*) é o jeito suportado de fazer uma tarefa comum, construído
para que segui-lo dê menos trabalho do que qualquer alternativa. O nome *golden path* é do Spotify;
outras empresas falam em *paved road*. Criar um serviço novo, fazer o deploy, dar a ele um banco de
dados: cada coisa pode ter um caminho, e o time que segue um recebe pronta a parte chata.

A leitura errada mais comum é que o caminho pavimentado é o único jeito permitido. Ele é uma
recomendação com uma promessa de suporte junto. **Um time pode sair do caminho, e quando sai é dono
do que constrói lá fora**: o pipeline, os alertas, as atualizações e a noite em que um deles quebra.
O caminho vence por ser mais barato de seguir, e o preço de sair é pago pelo time que sai, e não
imposto por alguém.

## O template de serviço da Coreto

A resposta da Rafaela aos dias perdidos no começo de cada serviço novo foi um template. Um time que
cria um serviço parte dele, e o resultado já vem com:

- um pipeline de build e testes que roda a cada mudança;
- deploys em staging e em produção, com rollback;
- logs estruturados, as métricas padrão e um painel;
- alertas encaminhados ao time dono do serviço, e não à Plataforma;
- um health check e uma página de runbook com as seções que um engenheiro de plantão procura;
- atualizações de dependências propostas automaticamente quando o próprio template é atualizado.

Nada disso interessa ao Checkout ou ao Catálogo, e tudo isso é necessário. Esse é o teste do que
pertence a um caminho. A aula 8 traçou a linha de Geoffrey Moore entre o trabalho essencial (*core*),
que diferencia uma empresa, e o trabalho de contexto, que precisa ser bem feito e não diferencia
ninguém. **Um caminho pavimentado é onde uma organização faz seu trabalho de contexto uma vez só**,
para que cada time alinhado ao fluxo não precise refazê-lo sozinho.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 340\" role=\"img\" aria-label=\"Duas pilhas de seis camadas. À esquerda, um serviço no caminho pavimentado: só a camada de cima, o código do próprio serviço, pertence ao time do serviço; o pipeline, os deploys, os logs e métricas, os alertas e as atualizações pertencem à Plataforma. À direita, um serviço fora do caminho: as seis camadas pertencem ao time do serviço.\"><text x=\"195\" y=\"30\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"15\" font-weight=\"600\" fill=\"var(--phosphor)\">No caminho pavimentado</text><text x=\"525\" y=\"30\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"15\" font-weight=\"600\" fill=\"var(--amber)\">Fora do caminho</text><rect x=\"60\" y=\"50\" width=\"270\" height=\"34\" rx=\"3\" fill=\"var(--amber)\"></rect><text x=\"195\" y=\"72\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--ink)\">o código do próprio serviço</text><rect x=\"60\" y=\"90\" width=\"270\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"195\" y=\"112\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">pipeline de build e testes</text><rect x=\"60\" y=\"130\" width=\"270\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"195\" y=\"152\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">deploys e rollback</text><rect x=\"60\" y=\"170\" width=\"270\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"195\" y=\"192\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">logs, métricas e um painel</text><rect x=\"60\" y=\"210\" width=\"270\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"195\" y=\"232\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">alertas para o time dono</text><rect x=\"60\" y=\"250\" width=\"270\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"195\" y=\"272\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">atualizações de tudo isso</text><rect x=\"390\" y=\"50\" width=\"270\" height=\"34\" rx=\"3\" fill=\"var(--amber)\"></rect><text x=\"525\" y=\"72\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--ink)\">o código do próprio serviço</text><rect x=\"390\" y=\"90\" width=\"270\" height=\"34\" rx=\"3\" fill=\"var(--amber)\"></rect><text x=\"525\" y=\"112\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--ink)\">pipeline de build e testes</text><rect x=\"390\" y=\"130\" width=\"270\" height=\"34\" rx=\"3\" fill=\"var(--amber)\"></rect><text x=\"525\" y=\"152\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--ink)\">deploys e rollback</text><rect x=\"390\" y=\"170\" width=\"270\" height=\"34\" rx=\"3\" fill=\"var(--amber)\"></rect><text x=\"525\" y=\"192\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--ink)\">logs, métricas e um painel</text><rect x=\"390\" y=\"210\" width=\"270\" height=\"34\" rx=\"3\" fill=\"var(--amber)\"></rect><text x=\"525\" y=\"232\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--ink)\">alertas para o time dono</text><rect x=\"390\" y=\"250\" width=\"270\" height=\"34\" rx=\"3\" fill=\"var(--amber)\"></rect><text x=\"525\" y=\"272\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--ink)\">atualizações de tudo isso</text><rect x=\"60\" y=\"306\" width=\"14\" height=\"14\" fill=\"var(--amber)\"></rect><text x=\"82\" y=\"318\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">construído e operado pelo time do serviço</text><rect x=\"390\" y=\"306\" width=\"14\" height=\"14\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"412\" y=\"318\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">construído e operado pela Plataforma</text></svg>", "caption": "Onde cai a linha de responsabilidade. No caminho, o time do serviço é dono de uma camada e a Plataforma do resto; fora dele, o time é dono das seis, inclusive das atualizações que ninguém planeja."}
```

## O caminho precisa continuar pavimentado

Um template copiado uma vez e nunca mais tocado é uma fotografia. Um ano depois, os serviços criados
a partir dele rodam várias versões do pipeline, e a promessa de que a Plataforma é dona dessas
camadas virou falsa sem ninguém perceber. **A última camada da figura é a que torna um caminho
pavimentado**: quando a Plataforma melhora o pipeline ou corrige a biblioteca de logs, cada serviço
no caminho recebe a mudança como uma atualização proposta, e o time a revisa em vez de reconstruí-la.

É também por isso que o template deixa coisas de fora de propósito. Cada opção que ele carrega é uma
opção que a Plataforma precisa manter funcionando em todas as atualizações futuras. A regra da
Rafaela era que um recurso entrava no template quando mais de um time tinha precisado dele, e ficava
de fora enquanto só um tinha.

## Sair de parte do caminho

Um caminho do tipo tudo ou nada empurra os times inteiramente para fora na primeira vez que uma peça
não serve. O template da Coreto deixa um time trocar uma camada e manter o resto: Pagamentos, que tem
exigências próprias de auditoria para alertas, troca o encaminhamento de alertas e continua com o
pipeline, os deploys e as atualizações. **Um time que sai de uma camada é dono dessa camada e de mais
nada.**

Algum trabalho pertence inteiramente ao lado de fora, e tudo bem. Os jobs noturnos do time de Dados
não atendem requisições, então um health check e métricas de requisição não significam nada para
eles; forçá-los num template de serviço web lhes daria configuração para manter e nenhum benefício.
Um caminho é para o caso comum. O caso incomum é onde o julgamento do time vale mais que um padrão.

| | no caminho | fora do caminho |
|---|---|---|
| quem constrói as camadas chatas | a Plataforma, uma vez | o time, a cada vez |
| quem as mantém funcionando nas atualizações | a Plataforma | o time |
| quem é acordado quando o pipeline quebra | a Plataforma | o time |
| quem decide | o time, ao escolher o caminho | o time, ao escolher sair dele |
