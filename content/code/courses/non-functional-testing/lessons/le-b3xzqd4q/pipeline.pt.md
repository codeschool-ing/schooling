---
title: O portão, e o job que o roda
version: 1
---

As duas metades viram um comando só, o `perf/gate.sh`, cujo código de saída é o veredito. Um
pipeline não precisa de mais nada dele: um passo que sai com código diferente de zero reprova o
job, e um job reprovado bloqueia o merge. Escreva com `nano perf/gate.sh`:

```schooling-example
{"language": "sh", "file": "boxoffice/perf/gate.sh", "parts": [{"code": "# boxoffice/perf/gate.sh\n# The performance gate. Three Lighthouse runs of one page, judged by their\n# medians against the budget; three k6 runs of the API, judged by their\n# thresholds. Exits 1 if either half fails. Run it from ~/boxoffice with the\n# box office running:  bash perf/gate.sh /fast.html\nset -u\npage=${1:?which page, for example /fast.html}\nexport CHROME_PATH=${CHROME_PATH:-$HOME/.cache/ms-playwright/chromium-1194/chrome-linux/chrome}\nmkdir -p perf/runs\nrm -f perf/runs/*.json\nfailed=0\n", "note": "Um argumento, a página. O `CHROME_PATH` mantém o valor que a aula 10 pôs no `~/.profile` e cai no mesmo caminho, porque o shell de um pipeline não lê o `~/.profile`. Os relatórios antigos saem primeiro, para uma execução que não consiga gravar o seu não ser julgada pelo da anterior."}, {"code": "echo \"== front end: $page, 3 Lighthouse runs\"\nfor i in 1 2 3; do\n  lighthouse \"http://127.0.0.1:8000$page\" --quiet --only-categories=performance \\\n    --output=json --output-path=\"perf/runs/lh-$i.json\" \\\n    --chrome-flags=\"--headless=new --no-sandbox\"\ndone\npython3 perf/budget.py perf/runs/lh-*.json || failed=1\n", "note": "O front-end: três execuções do Lighthouse e o `budget.py` nas três, que julga as medianas. O código de saída dele define o `failed`."}, {"code": "echo \"== back end: GET /shows/{id}, 3 k6 runs\"\ncrossed=0\nfor i in 1 2 3; do\n  k6 run --quiet --summary-export=\"perf/runs/k6-$i.json\" perf/api.js >/dev/null 2>&1\n  code=$?\n  p95=$(jq '.metrics.http_req_duration[\"p(95)\"] * 10 | round / 10' \"perf/runs/k6-$i.json\")\n  echo \"run $i: p95 $p95 ms, k6 exit $code\"\n  [ \"$code\" -ne 0 ] && crossed=$((crossed + 1))\ndone\nif [ \"$crossed\" -ge 2 ]; then\n  echo \"thresholds crossed in $crossed of 3 runs\"\n  failed=1\nfi\n", "note": "O back-end: três execuções do k6, cada uma julgada pelos próprios limites. O portão reprova quando duas ou mais cruzaram um limite, o que é o mesmo que perguntar se a execução mediana cruzou."}, {"code": "[ \"$failed\" -eq 0 ] && echo \"GATE: pass\" || echo \"GATE: fail\"\nexit \"$failed\"", "note": "Uma linha para a pessoa que lê o log, e o código de saída para o pipeline, que não lê mais nada."}]}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l11-gate\" aria-label=\"Como o gate.sh decide. No front-end, três execuções do Lighthouse na página alimentam o budget.py, que tira a mediana de cada número e a compara com o orçamento, reprovando em qualquer linha acima. No back-end, três execuções do k6 no GET /shows/{id}, cada uma julgada pelos próprios limites, o requisito de 200 ms e a linha de base com a tolerância; o back-end reprova quando duas ou mais cruzam. O portão sai com 0 só quando as duas metades passam, e com 1 caso contrário, e o pipeline não lê nada além desse código de saída.\"><defs><marker id=\"l11-gate-nf-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"30.0\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">front-end</text><rect x=\"114.0\" y=\"48.0\" width=\"112.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><rect x=\"122.0\" y=\"54.0\" width=\"112.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><rect x=\"130.0\" y=\"60.0\" width=\"112.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"186.0\" y=\"75.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">lighthouse ×3</text><path d=\"M244.0 75.0 L268.0 70.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-gate-nf-ah-paper-dim)\"></path><rect x=\"272.0\" y=\"52.0\" width=\"170.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"357.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">mediana de cada número</text><path d=\"M442.0 70.0 L478.0 70.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-gate-nf-ah-paper-dim)\"></path><rect x=\"482.0\" y=\"52.0\" width=\"110.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"537.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">acima do orçamento?</text><path d=\"M592.0 70.0 L622.0 105.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-gate-nf-ah-paper-dim)\"></path><text x=\"30.0\" y=\"170.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">back-end</text><rect x=\"114.0\" y=\"148.0\" width=\"112.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><rect x=\"122.0\" y=\"154.0\" width=\"112.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><rect x=\"130.0\" y=\"160.0\" width=\"112.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"186.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">k6 ×3</text><path d=\"M244.0 175.0 L268.0 170.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-gate-nf-ah-paper-dim)\"></path><rect x=\"272.0\" y=\"152.0\" width=\"170.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"357.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">cada execução contra os limites</text><path d=\"M442.0 170.0 L478.0 170.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-gate-nf-ah-paper-dim)\"></path><rect x=\"482.0\" y=\"152.0\" width=\"110.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"537.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">2 de 3 cruzaram?</text><path d=\"M592.0 170.0 L622.0 135.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-gate-nf-ah-paper-dim)\"></path><rect x=\"626.0\" y=\"96.0\" width=\"74.0\" height=\"48.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"663.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">exit 0</text><text x=\"663.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">exit 1</text><text x=\"360.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o pipeline lê o código de saída e nada mais</text></svg>", "caption": "O portão: medianas contra um orçamento de um lado, a maioria das execuções contra limites do outro, e um código de saída para os dois."}
```

## Rodando o portão

Antes de rodar, ponha o índice de volta, para o back-end ser a versão que a linha de base
descreve:

```
ana@nft:~/boxoffice$ sqlite3 data/boxoffice.db "CREATE INDEX bookings_show ON bookings(show_id)"
```

**A página lenta da aula 10:**

```
ana@nft:~/boxoffice$ bash perf/gate.sh /; echo "exit $?"
== front end: /, 3 Lighthouse runs
largest-contentful-paint         13,052      2,500  OVER
cumulative-layout-shift           0.139        0.1  OVER
total-blocking-time               1,414        200  OVER
script bytes                        405     50,000  ok
image bytes                   2,431,680    200,000  OVER
total bytes                   2,435,280    400,000  OVER
total requests                        4         15  ok
3 runs, 5 over budget
== back end: GET /shows/{id}, 3 k6 runs
run 1: p95 2.1 ms, k6 exit 0
run 2: p95 12.5 ms, k6 exit 99
run 3: p95 11.4 ms, k6 exit 99
thresholds crossed in 2 of 3 runs
GATE: fail
exit 1
```

O front-end reprova nas mesmas cinco linhas de antes, agora julgadas pela mediana de três
execuções, e o portão sai com 1. **O back-end também reprovou, e não devia.** O índice estava lá,
o código era a versão que a linha de base descreve, e duas das três execuções ainda cruzaram o
limite de 9.8 ms, com 12.5 e 11.4 ms, enquanto a primeira rodou em 2.1. É a falsa reprovação da
seção anterior, pega numa máquina dividida com outro trabalho. Aqui a página reprovou de qualquer
jeito; sozinha, seria um job vermelho à toa. A linha de base veio de três execuções num minuto
mais tranquilo, e um portão que fizesse isso duas vezes por semana precisaria de uma linha de base
gravada de mais execuções, na máquina que o portão usa, ou de uma folga maior.

**A página corrigida:**

```
ana@nft:~/boxoffice$ bash perf/gate.sh /fast.html; echo "exit $?"
== front end: /fast.html, 3 Lighthouse runs
largest-contentful-paint            912      2,500  ok
cumulative-layout-shift               0        0.1  ok
total-blocking-time                   0        200  ok
script bytes                          0     50,000  ok
image bytes                      20,563    200,000  ok
total bytes                      23,466    400,000  ok
total requests                        3         15  ok
3 runs, 0 over budget
== back end: GET /shows/{id}, 3 k6 runs
run 1: p95 3.1 ms, k6 exit 0
run 2: p95 1.9 ms, k6 exit 0
run 3: p95 1.7 ms, k6 exit 0
GATE: pass
exit 0
```

Todas as linhas dentro do orçamento, três execuções do k6 dentro dos limites, saída 0.

**A página corrigida de novo, sem o índice:**

```
ana@nft:~/boxoffice$ sqlite3 data/boxoffice.db "DROP INDEX bookings_show"
ana@nft:~/boxoffice$ bash perf/gate.sh /fast.html; echo "exit $?"
== front end: /fast.html, 3 Lighthouse runs
largest-contentful-paint            911      2,500  ok
cumulative-layout-shift               0        0.1  ok
total-blocking-time                   0        200  ok
script bytes                          0     50,000  ok
image bytes                      20,563    200,000  ok
total bytes                      23,467    400,000  ok
total requests                        3         15  ok
3 runs, 0 over budget
== back end: GET /shows/{id}, 3 k6 runs
run 1: p95 23.1 ms, k6 exit 99
run 2: p95 16.8 ms, k6 exit 99
run 3: p95 21.9 ms, k6 exit 99
thresholds crossed in 3 of 3 runs
GATE: fail
exit 1
```

A página está boa e o portão reprova mesmo assim, porque o back-end regrediu. É o motivo para
fechar as duas metades num lugar só: uma entrega é lenta para os usuários seja qual for a metade
que ficou mais lenta.

## O job

Este é um workflow do GitHub Actions que roda o portão em cada pull request. **Ele não foi rodado
para este curso**: a bilheteria não é um repositório no GitHub, e a VM não tem runner. Ele aparece
inteiro porque é o último passo, e os comandos dele são os que estas aulas imprimem: as
instalações das aulas 5 e 10, a bilheteria da aula 1, o índice e o portão. O índice é criado com
o módulo `sqlite3` do Python e não com o programa `sqlite3`, que a imagem de um runner pode não
ter.

```yaml
# boxoffice/.github/workflows/performance.yml
# The performance gate on every pull request. The job fails when gate.sh exits
# non-zero, and a failed job blocks the merge where the branch is protected.
name: performance

on:
  pull_request:

jobs:
  gate:
    runs-on: ubuntu-24.04
    timeout-minutes: 20
    steps:
      - uses: actions/checkout@v5

      - uses: actions/setup-node@v5
        with:
          node-version: "24"

      - name: Install Lighthouse, Chromium and k6
        run: |
          sudo npm install -g lighthouse@13.5.0
          mkdir -p ~/browser && cd ~/browser && npm init -y
          npm install playwright@1.56.0 && npx playwright install --with-deps chromium
          curl -fsSLO https://github.com/grafana/k6/releases/download/v1.8.1/k6-v1.8.1-linux-amd64.tar.gz
          tar -xzf k6-v1.8.1-linux-amd64.tar.gz
          sudo install k6-v1.8.1-linux-amd64/k6 /usr/local/bin/

      - name: Start the box office
        run: |
          python3 seed.py
          python3 -c "import sqlite3; sqlite3.connect('data/boxoffice.db').execute('CREATE INDEX bookings_show ON bookings(show_id)')"
          python3 make_hero.py
          nohup python3 app.py > server.log 2>&1 &
          for i in $(seq 50); do curl -fs localhost:8000/health && break; sleep 0.2; done

      - name: Gate
        run: bash perf/gate.sh /fast.html

      - name: Keep the reports
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: performance-runs
          path: perf/runs/
```

Três coisas nele são decisões, não sintaxe:

- **Ele instala versões exatas**, as mesmas da VM, para o portão no runner medir com a ferramenta
  com que a linha de base foi medida.
- **Ele roda só a página corrigida.** A página lenta existe para mostrar uma reprovação; um
  repositório de verdade fecharia o portão nas páginas que entrega.
- **Ele guarda os relatórios mesmo quando o portão reprova** (`if: always()`), porque um job
  vermelho sem evidência manda alguém reproduzir à mão.

Um cuidado com a linha de base num pipeline. O `baseline.json` do repositório foi medido na sua
VM, e um runner do GitHub é outra máquina, com outros vizinhos. Grave a linha de base no runner que
o portão usa, rodando as mesmas três execuções do k6 lá uma vez, e faça commit desse arquivo.

Como os gatilhos, os jobs e os runners funcionam é assunto das aulas 5 e 6 de `testing-cicd`:
integração contínua em geral, e GitHub Actions e GitLab CI na prática. Esta aula acrescenta mais
uma checagem a esse pipeline, e o código de saída dela é tudo o que o pipeline precisa entender.
