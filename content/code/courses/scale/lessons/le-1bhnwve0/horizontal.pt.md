---
title: Escala horizontal, mais cópias
version: 1
---

**A escala horizontal roda mais cópias do programa e divide o trabalho entre elas.** Ela precisa de
algo na frente para fazer a divisão, e precisa que as cópias sejam intercambiáveis: qualquer uma
tem de conseguir responder a qualquer pedido.

A bilheteria já tem a primeira peça. O `lb` é um nginx que manda cada pedido para um dos endereços
a que o Docker dá o nome `app`, e até agora havia um endereço. O Compose sobe mais cópias de um
serviço com `--scale`:

```
ana@lab:~/tickets$ docker compose up -d --scale app=3
 Container tickets-app-1 Running 
 Container tickets-lb-1 Running 
 Container tickets-db-1 Running 
 Container tickets-app-3 Creating 
 Container tickets-app-2 Creating 
 Container tickets-app-2 Created 
 Container tickets-app-3 Created 
 Container tickets-db-1 Waiting 
 Container tickets-db-1 Healthy 
 Container tickets-app-3 Starting 
 Container tickets-app-3 Started 
 Container tickets-app-2 Starting 
 Container tickets-app-2 Started 
ana@lab:~/tickets$ docker compose restart lb
 Container tickets-lb-1 Restarting 
 Container tickets-lb-1 Started 
ana@lab:~/tickets$ for i in 1 2 3 4 5 6; do curl -s localhost:8080/healthz; echo; done
{"host": "1734815cb5a4"}
{"host": "d79c69160da7"}
{"host": "8159e9da198f"}
{"host": "1734815cb5a4"}
{"host": "d79c69160da7"}
{"host": "8159e9da198f"}
```

Dois contêineres novos, `tickets-app-2` e `tickets-app-3`. O nginx procura o nome `app` quando sobe
e não depois, então ele é reiniciado para ver os três endereços. Depois, seis pedidos para
`/healthz`, e cada resposta nomeia o contêiner que a deu: três hosts diferentes, em rodízio. O
padrão do nginx é o **round robin**, cada pedido para a próxima cópia da lista.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"O desenho do laboratório. O load.py, no próprio laboratório, envia pedidos para a porta 8080, onde o contêiner lb, um nginx, passa cada um, na sua vez, para uma de três cópias do app, tickets-app-1, 2 e 3. As três cópias falam com um único contêiner de banco, db, que guarda os shows e os ingressos.\"><rect x=\"20\" y=\"100\" width=\"110\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"75\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">load.py</text><text x=\"75\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">no laboratório</text><path d=\"M130 125 L200 125\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M200 125 L193.7 128.0 L193.7 122.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><text x=\"165\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">:8080</text><rect x=\"200\" y=\"100\" width=\"100\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"250\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">lb</text><text x=\"250\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">nginx</text><path d=\"M300 125 L380 55\" stroke=\"var(--wire)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M380 55 L377.3 61.4 L373.3 56.9 Z\" fill=\"var(--wire)\" stroke=\"none\"></path><rect x=\"380\" y=\"30\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"455\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">tickets-app-1</text><text x=\"455\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">cpus: 1</text><path d=\"M530 55 L600 125\" stroke=\"var(--wire)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M600 125 L593.4 122.7 L597.7 118.4 Z\" fill=\"var(--wire)\" stroke=\"none\"></path><path d=\"M300 125 L380 125\" stroke=\"var(--wire)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M380 125 L373.7 128.0 L373.7 122.0 Z\" fill=\"var(--wire)\" stroke=\"none\"></path><rect x=\"380\" y=\"100\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"455\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">tickets-app-2</text><text x=\"455\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">cpus: 1</text><path d=\"M530 125 L600 125\" stroke=\"var(--wire)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M600 125 L593.7 128.0 L593.7 122.0 Z\" fill=\"var(--wire)\" stroke=\"none\"></path><path d=\"M300 125 L380 195\" stroke=\"var(--wire)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M380 195 L373.3 193.1 L377.3 188.6 Z\" fill=\"var(--wire)\" stroke=\"none\"></path><rect x=\"380\" y=\"170\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"455\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">tickets-app-3</text><text x=\"455\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">cpus: 1</text><path d=\"M530 195 L600 125\" stroke=\"var(--wire)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M600 125 L597.7 131.6 L593.4 127.3 Z\" fill=\"var(--wire)\" stroke=\"none\"></path><rect x=\"600\" y=\"95\" width=\"100\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></rect><text x=\"650\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">db</text><text x=\"650\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">PostgreSQL</text><text x=\"455\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">round robin: cada pedido para a próxima cópia</text></svg>", "caption": "Três cópias da bilheteria atrás de um balanceador de carga, e um banco atrás das três.", "same": ["PostgreSQL"]}
```

Agora o mesmo teste das duas últimas seções, com uma, duas e três cópias, cada uma limitada a um
processador:

```
ana@lab:~/tickets$ python3 load.py -m POST -c 16 -d 10 --events 100 'http://localhost:8080/events/{event}/tickets'
requests  1458 in 10.1 s = 144.8 per second
latency   p50 102.2 ms  p95 194.9 ms  p99 220.3 ms  max 341.4 ms
status    201: 1458
```

```
ana@lab:~/tickets$ python3 load.py -m POST -c 16 -d 10 --events 100 'http://localhost:8080/events/{event}/tickets'
requests  3056 in 10.0 s = 304.2 per second
latency   p50 41.9 ms  p95 122.7 ms  p99 174.2 ms  max 243.8 ms
status    201: 3056
```

```
ana@lab:~/tickets$ python3 load.py -m POST -c 16 -d 10 --events 100 'http://localhost:8080/events/{event}/tickets'
requests  4706 in 10.0 s = 469.9 per second
latency   p50 27.9 ms  p95 78.1 ms  p99 117.6 ms  max 326.3 ms
status    201: 4706
```

145, 304, 470: **cada cópia soma umas 150 vendas por segundo**, que é o que uma cópia fazia
sozinha. Essa é a forma que a escala horizontal promete, e nesta máquina ela cumpre até três
cópias, que usam três dos quatro processadores. Uma quarta cópia nos mesmos quatro processadores
só brigaria com as outras por eles; num sistema de verdade a quarta cópia vai para outra máquina, e
é aí que o teto da escala vertical deixa de valer.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 310\" role=\"img\" aria-label=\"Dois grupos de barras, ingressos vendidos por segundo com 16 trabalhadores em cem shows. Vertical: 143 com um processador, 314 com dois, 433 com quatro. Horizontal: 145 com uma cópia, 304 com duas, 470 com três, cada cópia limitada a um processador. Uma linha tracejada em 140 marca o que um único show vendeu, 138 com três cópias e 137 com uma.\"><path d=\"M40 240 L690 240\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"200\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">vertical: uma cópia, mais processadores</text><text x=\"520\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">horizontal: mais cópias, um processador cada</text><rect x=\"90\" y=\"185.546\" width=\"56\" height=\"54.45400000000001\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"118\" y=\"175.546\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">143</text><text x=\"118\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">1 cpu</text><rect x=\"170\" y=\"120.64199999999998\" width=\"56\" height=\"119.35800000000002\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"198\" y=\"110.64199999999998\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">314</text><text x=\"198\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">2 cpus</text><rect x=\"250\" y=\"75.38400000000001\" width=\"56\" height=\"164.61599999999999\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"278\" y=\"65.38400000000001\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">433</text><text x=\"278\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">4 cpus</text><rect x=\"410\" y=\"184.976\" width=\"56\" height=\"55.024\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"438\" y=\"174.976\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">145</text><text x=\"438\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">1 cópia</text><rect x=\"490\" y=\"124.40400000000001\" width=\"56\" height=\"115.59599999999999\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"518\" y=\"114.40400000000001\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">304</text><text x=\"518\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">2 cópias</text><rect x=\"570\" y=\"61.43800000000002\" width=\"56\" height=\"178.56199999999998\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"598\" y=\"51.43800000000002\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">470</text><text x=\"598\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">3 cópias</text><path d=\"M42 187.56 L88 187.56\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M148 187.56 L168 187.56\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M228 187.56 L248 187.56\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M308 187.56 L408 187.56\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M468 187.56 L488 187.56\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M548 187.56 L568 187.56\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M628 187.56 L688 187.56\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M200 292 L240 292\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"248\" y=\"292\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">um show sozinho: 137 a 138 por segundo, com uma cópia ou três</text></svg>", "caption": "As duas direções somam capacidade nesta máquina até os quatro processadores acabarem. Nenhuma move a linha tracejada, que é a linha de um show.", "same": ["1 cpu", "2 cpus", "4 cpus"]}
```

## O que torna as cópias intercambiáveis

A bilheteria escalou tão limpo por um motivo: **ela não guarda nada entre um pedido e outro**. Todo
fato de que precisa, quantos lugares restam num show e quais foram vendidos, mora no banco. Um
pedido pode ir para qualquer cópia porque nenhuma cópia sabe algo que as outras não saibam. Essa
propriedade se chama ser **sem estado** (*stateless*), e é o preço de entrada da escala horizontal.

É fácil perdê-la sem querer. Três coisas que parecem inofensivas e a quebram:

- **Uma sessão guardada na memória.** Um usuário entra, a cópia que respondeu se lembra dele, e o
  próximo pedido vai para outra cópia que não se lembra. As saídas são mandar cada usuário sempre
  para a mesma cópia, as **sessões grudadas** (*sticky sessions*), o que faz a falha de uma cópia
  deslogar todo mundo que ela segurava; ou guardar as sessões onde toda cópia consiga lê-las, no
  banco ou num cache como o Redis.
- **Um contador numa variável.** "Ingressos vendidos hoje" contado no programa conta um terço das
  vendas em cada uma de três cópias.
- **Um arquivo gravado no disco local.** Uma foto enviada e salva por uma cópia é um 404 nas outras
  duas.

## O que custa

A escala horizontal moveu o limite do tamanho de uma máquina para o número de máquinas, e pagou por
isso com peças novas. **O balanceador de carga é um componente novo**, e com um só ele é um novo
ponto único de falha; sistemas de verdade rodam dois. **As cópias precisam ser implantadas
juntas**, com a mesma configuração. E no momento em que as cópias deixam de ser independentes,
porque todas querem a mesma coisa, a escala para. A próxima seção vende todos os ingressos de um
único show.
