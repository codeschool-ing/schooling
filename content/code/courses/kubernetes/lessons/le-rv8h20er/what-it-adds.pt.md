---
title: O que um orquestrador acrescenta
version: 1
---

As três bordas das duas últimas seções têm uma coisa em comum: **cada uma é uma decisão que uma
pessoa toma numa máquina e que nada toma em várias.** Onde uma segunda cópia deve rodar? Qual cópia
recebe esta requisição? A nova já está pronta? Ainda existe uma loja, agora que o laptop sumiu? Um
orquestrador é um programa que toma essas decisões o tempo todo, para um grupo de máquinas tratado
como uma só.

## Estado desejado, e um laço que continua conferindo

A forma por baixo de todo o Kubernetes cabe numa frase. **Você escreve o que deveria ser verdade, e
um programa compara isso com o que é verdade e age sobre a diferença, de novo e de novo.** A Ana não
diz "suba três containers". Ela diz "deveria haver três cópias de `shop:1.1`, acessíveis por um
nome", e o cluster passa o resto da vida fazendo isso acontecer.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Um laço de três passos em volta de uma caixa chamada estado desejado: observar o que está rodando, comparar com o que foi escrito, agir sobre a diferença, e de volta a observar. Ao lado, o estado desejado da loja: três cópias de shop:1.1 sob um nome.\"><defs><marker id=\"loop-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"loop-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"40\" y=\"30\" width=\"170\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"125.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">observar</text><text x=\"125.0\" y=\"64.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o que está rodando</text><rect x=\"250\" y=\"170\" width=\"170\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"335.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">comparar</text><text x=\"335.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">com o que foi escrito</text><rect x=\"40\" y=\"170\" width=\"170\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"125.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">agir</text><text x=\"125.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sobre a diferença</text><path d=\"M210 56 L335 56 L335 168\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#loop-ah-paper-dim)\"></path><path d=\"M250 196 L212 196\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#loop-ah-paper-dim)\"></path><path d=\"M125 170 L125 84\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#loop-ah-paper-dim)\"></path><rect x=\"480\" y=\"60\" width=\"200\" height=\"90\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"580.0\" y=\"89.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">estado desejado</text><text x=\"580.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3 cópias de shop:1.1</text><text x=\"580.0\" y=\"121.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um nome: web</text><path d=\"M480 120 L424 190\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#loop-ah-amber)\"></path><text x=\"232\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">nunca para</text></svg>", "caption": "O laço nunca termina: uma cópia que some é uma diferença, e a volta seguinte a fecha."}
```

A diferença para o Compose não é o arquivo. O `compose.yaml` também descreve o que deveria rodar. A
diferença é que o Compose lê o arquivo quando alguém digita `docker compose up` e depois para de
olhar, enquanto o orquestrador nunca para. Uma cópia que some às três da manhã é uma diferença entre
a descrição e o mundo, e fechá-la é trabalho do laço, não de quem está de plantão.

## Cinco coisas que decorrem do laço

| o que você precisa | numa máquina com Compose | num cluster |
|---|---|---|
| uma cópia que cai volta | a política de reinício do daemon | o mesmo, mais uma substituta criada pelo plano de controle (lição 10) |
| uma máquina que morre | tudo o que estava nela some | as cópias dela sobem de novo nas máquinas que restam (lição 32) |
| várias cópias num endereço | um proxy que você acrescenta e configura | um Service na frente delas, mantido em dia (lição 15) |
| uma atualização sem intervalo | para, depois sobe: 12 de 300 recusadas | sobe, espera ficar pronta, depois para (lição 35) |
| mais cópias sob carga | um número que você edita | um controlador que o muda (lição 33) |

Cada linha diz a lição em que aquilo acontece num cluster de verdade, para que nenhuma precise ser
aceita aqui por confiança.

## O que custa

**Nada disso é de graça, e o preço é pago antes da primeira requisição.** Um cluster são várias
máquinas, um plano de controle que precisa ficar de pé para qualquer coisa mudar, uma rede entre as
cópias e um vocabulário de objetos que você agora precisa aprender, a partir da lição 2. Para um
serviço numa máquina, com uma atualização por semana e uma equipe de uma pessoa, é muito peso em
troca de doze requisições. A lição 3 pergunta quando o Kubernetes é excesso, e a lição 46 faz a
conta de rodar um por conta própria.
