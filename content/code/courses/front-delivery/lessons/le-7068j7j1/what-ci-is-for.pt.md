---
title: Para que serve a integração contínua
version: 1
---

**Integração contínua é uma máquina que roda as conferências do projeto em todo push, numa cópia limpa do
repositório, e diz passou ou falhou onde todo mundo vê.** O nome descreve o hábito que ela torna
possível: juntar mudanças pequenas ao branch principal com frequência, porque cada uma foi conferida antes
de chegar, em vez de juntar um mês de trabalho de uma vez e descobrir o que quebrou.

A imagem comum é a de que CI é "rodar os testes num servidor". Os testes fazem parte, e não são o motivo
de ele existir. O motivo são as palavras **limpa** e **toda**: uma máquina sem nada do seu estado local,
que ninguém pode pular, em toda mudança. O seu computador não é nem uma coisa nem outra. Ele tem arquivos
que você nunca commitou, um `node_modules` de três semanas atrás e variáveis de ambiente que você esqueceu
que definiu, e você roda as conferências quando lembra.

## O que o pipeline do planner faz

Quatro passos, cada um um comando que você já sabe rodar, na ordem que falha mais cedo:

1. **Instalar exatamente o que o lockfile diz**, com `npm ci`. A próxima seção é sobre por que não
   `npm install`.
2. **Conferir os tipos**, com `tsc`. Um erro de tipo é a falha mais barata de achar, então vem primeiro.
3. **Rodar os testes**, com o Vitest, que o planner ganha daqui a duas seções.
4. **Construir**, com `vite build`, o que prova que o que foi conferido pode virar a pasta que um host
   serve.

Cada passo para o pipeline quando falha, então um resultado vermelho cita a primeira coisa que deu errado,
e nada depois dela é desperdiçado.

## Onde ele fica

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Um branch é enviado e um pull request aberto. O CI roda quatro passos numa máquina limpa: npm ci, tsc, os testes e o build. Vermelho impede o merge; verde deixa passar para o main, e o host então constrói o main e o publica no endereço de verdade.\"><rect x=\"20\" y=\"70\" width=\"120\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"80\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">pull request</text><text x=\"80\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">de um branch</text><line x1=\"140\" y1=\"100\" x2=\"168\" y2=\"100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"168.0,100.0 160.6,103.1 160.6,96.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"170\" y=\"30\" width=\"250\" height=\"140\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"295\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">CI, numa máquina limpa</text><rect x=\"190\" y=\"65\" width=\"18\" height=\"18\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"199\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">1</text><text x=\"220\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">npm ci</text><rect x=\"190\" y=\"89\" width=\"18\" height=\"18\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"199\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">2</text><text x=\"220\" y=\"98\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">npx tsc</text><rect x=\"190\" y=\"113\" width=\"18\" height=\"18\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"199\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">3</text><text x=\"220\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">npm test</text><rect x=\"190\" y=\"137\" width=\"18\" height=\"18\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"199\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">4</text><text x=\"220\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">npx vite build</text><line x1=\"420\" y1=\"70\" x2=\"470\" y2=\"50\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"470.0,50.0 464.3,55.6 462.0,49.8\" fill=\"var(--amber)\"></polygon><text x=\"478\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">vermelho: sem merge</text><line x1=\"420\" y1=\"130\" x2=\"470\" y2=\"150\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"470.0,150.0 462.0,150.2 464.3,144.4\" fill=\"var(--phosphor)\"></polygon><rect x=\"472\" y=\"130\" width=\"90\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"517\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">main</text><line x1=\"562\" y1=\"150\" x2=\"590\" y2=\"150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"590.0,150.0 582.6,153.1 582.6,146.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"592\" y=\"125\" width=\"110\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"647\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o host constrói</text><text x=\"647\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">e publica</text><text x=\"470\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">verde: merge liberado</text></svg>", "caption": "As conferências rodam antes do merge, em todo pull request, então uma falha é um comentário num branch, e não um main quebrado.", "same": ["pull request"]}
```

**As conferências rodam no pull request, antes do merge**, e esse é o ponto: uma falha ali é um
comentário num branch, barato e restrito a quem fez a mudança. A mesma falha depois do merge é um branch
principal quebrado que todo mundo puxa. O build do host da aula 1 roda depois das conferências, ou ao lado
delas, e só o branch principal chega ao endereço de verdade.

## O que esta aula consegue rodar, e o que não consegue

Os quatro passos do pipeline rodam no seu computador, e as seções a seguir rodam cada um deles, inclusive
numa cópia limpa do repositório. O GitHub Actions em si, o serviço que os roda em todo push, precisa de
um repositório no GitHub e **não foi executado para este curso**; o arquivo de workflow é mostrado, cada
linha explicada, e marcado como tal.
