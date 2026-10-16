---
title: IX, descartabilidade
version: 1
---

Uma plataforma para processos o tempo todo: para implantar uma release nova, para tirar trabalho de uma
máquina que vai para manutenção, para reduzir a escala à noite. **Um processo descartável inicia rápido
e para com elegância**, para nada disso ser um evento que alguém perceba.

Parar é uma conversa com duas mensagens. O Docker, como o Kubernetes e quase toda plataforma, manda
primeiro **SIGTERM**, que quer dizer "termine e saia". Se o processo ainda estiver lá depois de um
período de tolerância, dez segundos por padrão no Docker e trinta no Kubernetes, ele manda **SIGKILL**,
que não pode ser capturado e encerra o processo onde ele estiver.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Duas linhas do tempo começando quando o Docker manda SIGTERM. Na primeira, o programa tem um handler: termina a requisição em andamento e sai depois de cerca de um segundo. Na segunda, o programa não tem handler e ignora o sinal; o Docker espera os dez segundos inteiros e então manda SIGKILL, cortando o que estava rodando.\"><defs><marker id=\"l4-sigterm-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"210\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><path d=\"M90 190 L690 190\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l4-sigterm-ah-wire)\"></path><text x=\"90\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0 s</text><text x=\"140\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1 s</text><text x=\"340\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">5 s</text><text x=\"590\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10 s</text><text x=\"26\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">handler</text><rect x=\"90\" y=\"44\" width=\"50\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"115\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">sai</text><text x=\"26\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">ignorado</text><rect x=\"90\" y=\"114\" width=\"500\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"340\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">esperando um processo que não vai parar</text><rect x=\"592\" y=\"114\" width=\"90\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"637\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">SIGKILL</text></svg>", "caption": "Com handler, parar leva o tempo do trabalho em andamento. Sem handler, leva o período de tolerância inteiro do Docker e termina com um kill.", "same": ["handler"]}
```

## O catálogo, que escuta

O catálogo instala um handler para SIGTERM: para de aceitar conexões novas, deixa as requisições em
andamento terminarem, sai. Pare as três cópias e cronometre:

```
ana@vm:~/lab/twelve$ time docker compose stop catalogue
 Container twelve-catalogue-2 Stopping 
 Container twelve-catalogue-1 Stopping 
 Container twelve-catalogue-3 Stopping 
 Container twelve-catalogue-3 Stopped 
 Container twelve-catalogue-2 Stopped 
 Container twelve-catalogue-1 Stopped 

real	0m0.855s
user	0m0.063s
sys	0m0.076s
ana@vm:~/lab/twelve$ docker compose logs catalogue | grep -E "SIGTERM|stopped"
catalogue-1  | 4ed40453cdac SIGTERM: finishing requests in progress, then exiting
catalogue-1  | 4ed40453cdac stopped
catalogue-2  | a3b89e5e7e5f SIGTERM: finishing requests in progress, then exiting
catalogue-2  | a3b89e5e7e5f stopped
catalogue-3  | 280702d81305 SIGTERM: finishing requests in progress, then exiting
catalogue-3  | 280702d81305 stopped
```

Menos de um segundo para três processos, e o log de cada um diz que viu o sinal e parou em ordem.

## Um programa que não escuta

Aqui está a mesma coisa com um processo Python sem handler, um programa de uma linha que dorme:

```
ana@vm:~/lab/twelve$ docker run -d --name sleeper python:3.12-slim python -c "import time; time.sleep(3600)"
696c76de8d517be8c237fd4bb78563e04a12c5d6551ce05d28515ad5eaacd98d
ana@vm:~/lab/twelve$ time docker stop sleeper
sleeper

real	0m10.209s
user	0m0.013s
sys	0m0.034s
ana@vm:~/lab/twelve$ docker inspect --format "{{.State.ExitCode}}" sleeper
137
```

**Dez segundos**, para um programa que não estava fazendo nada, e um código de saída 137, que a aula 1
explicou: 128 mais o sinal 9, SIGKILL. O processo era o primeiro processo do
contêiner, PID 1, e o kernel Linux dá um tratamento especial ao PID 1: um sinal para o qual ele não
tem handler não tem efeito nenhum, então o SIGTERM foi ignorado e o Docker esperou o período de
tolerância inteiro antes de matá-lo. Um servidor web que ignora o SIGTERM do mesmo jeito perde toda
requisição em andamento no fim desses dez segundos, em todo deploy.

Há três saídas, e qualquer uma basta: tratar o SIGTERM no programa, como o catálogo faz; rodar o
programa sob um pequeno processo init que repassa sinais, que o `docker run --init` acrescenta; ou
garantir que o programa que a imagem inicia é o que trata os sinais, e não um script de shell que o
iniciou e os engole.

## Iniciar rápido

A outra metade é a partida. Um processo que leva dois minutos para iniciar deixa todo deploy, toda
recuperação de uma queda e todo aumento de escala dois minutos mais lentos, e as partidas a frio da
aula 3 são o mesmo custo pago por uma função. Carregue o necessário sob demanda, não construa na
partida caches que podem ser construídos no primeiro uso, e **deixe o health check da plataforma, aula
19, dizer quando o processo está pronto**, em vez de a plataforma adivinhar.
