---
title: Quanto custa um worker
version: 1
---

**Cada worker é um processo Node e um navegador, e um navegador é vários processos.** Acrescentar um
worker acrescenta todos eles, e eles disputam os mesmos processadores e a mesma memória. A crença de
que mais workers é sempre mais rápido só vale enquanto a máquina tem algo a dar, e o jeito de achar
onde isso para é medir a sua suíte na sua máquina.

## Medir uma execução

O `/usr/bin/time -v` do GNU informa um tamanho residente máximo, mas é o do maior processo sozinho,
e uma execução de testes é uma árvore deles: o executor, a loja, cada worker e o navegador de cada
worker. O script abaixo roda um comando, soma a memória da árvore inteira cinco vezes por segundo e
guarda o maior total. O `time` do Bash informa o tempo de processador do comando e de tudo abaixo
dele. Salve-o como `measure.sh`:

```sh
#!/usr/bin/env bash
# Runs a command and reports what its whole process tree cost: the most
# memory it held at one moment, and the processor time it used.
report=$(mktemp)
TIMEFORMAT='%R %U %S'
{ time "$@" > /dev/null 2>&1; } 2> "$report" &
root=$!
peak=0
while kill -0 "$root" 2>/dev/null; do
  # Add up the resident memory of the command and everything below it.
  kb=$(ps -A -o pid=,ppid=,rss= | awk -v root="$root" '
    { parent[$1] = $2; rss[$1] = $3 }
    END {
      for (p in parent) {
        q = p
        while (q != root && q > 1) q = parent[q]
        if (q == root) total += rss[p]
      }
      print total + 0
    }')
  if [ "$kb" -gt "$peak" ]; then peak=$kb; fi
  sleep 0.2
done
wait "$root"
status=$?
read -r real user system < "$report"
rm -f "$report"
echo "exit $status  wall ${real}s  processor ${user}s user + ${system}s system  peak memory $((peak / 1024)) MB"
```

Duas coisas a saber antes de confiar nos números dele. A memória é a memória residente de cada
processo somada, e processos do navegador dividem algumas páginas, então o total **exagera** o que a
máquina perdeu; serve para comparar execuções numa mesma máquina, não para comprar memória. E uma
amostra a cada 200 milissegundos pode perder um pico que dure menos que isso.

## A curva

A suíte inteira é a coisa errada a medir aqui, porque a fase um-de-cada-vez da seção anterior põe um
piso que nenhuma quantidade de workers move. Só o projeto `parallel`, cada teste um grupo próprio
com `--fully-parallel`, e cada teste rodado quatro vezes com `--repeat-each 4` para haver trabalho
suficiente para dividir, de um worker a oito neste notebook de quatro processadores:

```
ana@laptop:~/quitanda$ bash measure.sh npx playwright test --config turns.config.js --project parallel --fully-parallel --repeat-each 4 --workers 1
exit 0  wall 55.241s  processor 19.023s user + 5.056s system  peak memory 924 MB
ana@laptop:~/quitanda$ bash measure.sh npx playwright test --config turns.config.js --project parallel --fully-parallel --repeat-each 4 --workers 2
exit 0  wall 33.222s  processor 23.981s user + 5.579s system  peak memory 1480 MB
ana@laptop:~/quitanda$ bash measure.sh npx playwright test --config turns.config.js --project parallel --fully-parallel --repeat-each 4 --workers 3
exit 0  wall 26.121s  processor 27.515s user + 6.036s system  peak memory 2035 MB
ana@laptop:~/quitanda$ bash measure.sh npx playwright test --config turns.config.js --project parallel --fully-parallel --repeat-each 4 --workers 4
exit 0  wall 23.682s  processor 29.239s user + 6.826s system  peak memory 2573 MB
ana@laptop:~/quitanda$ bash measure.sh npx playwright test --config turns.config.js --project parallel --fully-parallel --repeat-each 4 --workers 6
exit 0  wall 23.327s  processor 35.685s user + 7.789s system  peak memory 3573 MB
ana@laptop:~/quitanda$ bash measure.sh npx playwright test --config turns.config.js --project parallel --fully-parallel --repeat-each 4 --workers 8
exit 0  wall 24.603s  processor 43.104s user + 9.083s system  peak memory 4476 MB
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Dois gráficos de barras sobre as quantidades de workers 1, 2, 3, 4, 6, 8. Tempo de relógio em segundos: 55.2, 33.2, 26.1, 23.7, 23.3, 24.6. Pico de memória em MB: 924, 1480, 2035, 2573, 3573, 4476. Uma linha marca quatro workers, os quatro processadores da máquina.\"><text x=\"30.0\" y=\"28.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">tempo de relógio, segundos</text><line x1=\"30\" y1=\"240\" x2=\"330\" y2=\"240\" stroke=\"var(--wire)\"></line><rect x=\"40.0\" y=\"67.3\" width=\"30.0\" height=\"172.7\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"55.0\" y=\"61.3\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">55.2</text><text x=\"55.0\" y=\"256.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1</text><rect x=\"90.0\" y=\"136.1\" width=\"30.0\" height=\"103.9\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"105.0\" y=\"130.1\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">33.2</text><text x=\"105.0\" y=\"256.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">2</text><rect x=\"140.0\" y=\"158.3\" width=\"30.0\" height=\"81.7\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"155.0\" y=\"152.3\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">26.1</text><text x=\"155.0\" y=\"256.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">3</text><rect x=\"190.0\" y=\"166.0\" width=\"30.0\" height=\"74.0\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"205.0\" y=\"160.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">23.7</text><text x=\"205.0\" y=\"256.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">4</text><line x1=\"235.0\" y1=\"44\" x2=\"235.0\" y2=\"240\" stroke=\"var(--paper-dim)\" stroke-dasharray=\"3 3\"></line><text x=\"239.0\" y=\"52.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">4 processadores</text><rect x=\"240.0\" y=\"167.1\" width=\"30.0\" height=\"72.9\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"255.0\" y=\"161.1\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">23.3</text><text x=\"255.0\" y=\"256.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">6</text><rect x=\"290.0\" y=\"163.1\" width=\"30.0\" height=\"76.9\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"305.0\" y=\"157.1\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">24.6</text><text x=\"305.0\" y=\"256.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">8</text><text x=\"180.0\" y=\"276.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">workers</text><text x=\"390.0\" y=\"28.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">pico de memória, MB</text><line x1=\"390\" y1=\"240\" x2=\"690\" y2=\"240\" stroke=\"var(--wire)\"></line><rect x=\"400.0\" y=\"204.3\" width=\"30.0\" height=\"35.7\" rx=\"2\" fill=\"var(--amber)\"></rect><text x=\"415.0\" y=\"198.3\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">924</text><text x=\"415.0\" y=\"256.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1</text><rect x=\"450.0\" y=\"182.9\" width=\"30.0\" height=\"57.1\" rx=\"2\" fill=\"var(--amber)\"></rect><text x=\"465.0\" y=\"176.9\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1480</text><text x=\"465.0\" y=\"256.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">2</text><rect x=\"500.0\" y=\"161.5\" width=\"30.0\" height=\"78.5\" rx=\"2\" fill=\"var(--amber)\"></rect><text x=\"515.0\" y=\"155.5\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">2035</text><text x=\"515.0\" y=\"256.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">3</text><rect x=\"550.0\" y=\"140.7\" width=\"30.0\" height=\"99.3\" rx=\"2\" fill=\"var(--amber)\"></rect><text x=\"565.0\" y=\"134.7\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">2573</text><text x=\"565.0\" y=\"256.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">4</text><line x1=\"595.0\" y1=\"44\" x2=\"595.0\" y2=\"240\" stroke=\"var(--paper-dim)\" stroke-dasharray=\"3 3\"></line><text x=\"599.0\" y=\"52.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">4 processadores</text><rect x=\"600.0\" y=\"102.1\" width=\"30.0\" height=\"137.9\" rx=\"2\" fill=\"var(--amber)\"></rect><text x=\"615.0\" y=\"96.1\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">3573</text><text x=\"615.0\" y=\"256.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">6</text><rect x=\"650.0\" y=\"67.3\" width=\"30.0\" height=\"172.7\" rx=\"2\" fill=\"var(--amber)\"></rect><text x=\"665.0\" y=\"61.3\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">4476</text><text x=\"665.0\" y=\"256.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">8</text><text x=\"540.0\" y=\"276.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">workers</text></svg>", "caption": "Os mesmos 120 testes com seis quantidades de workers num notebook de quatro processadores, uma execução de cada. A memória cresce a cada worker; o tempo para de cair.", "same": ["workers"]}
```

O tempo de relógio cai rápido no começo, de 55,2 segundos com um worker para 33,2 com dois e 26,1
com três, e depois cada vez menos: 23,7 com quatro, 23,3 com seis e 24,6 com oito, mais lento que
quatro. A memória não se estabiliza nunca. Cada worker acrescentou cerca de meio gigabyte, de 924 MB
com um para 4476 MB com oito, quase cinco vezes mais, para quase nenhum ganho depois do quarto. **A
quantidade mais rápida não foi a que custou menos**, e a curva diz onde parar: por volta de quatro,
o número de processadores.

## Por que, passando dos processadores, piora

Um teste aqui passa a maior parte do tempo esperando: a loja responder, uma página desenhar, uma
asserção ver o que espera. **Enquanto um worker espera, outro pode usar o processador**, e é por
isso que o segundo worker tirou tanto do tempo de relógio.

Passando do número de processadores, isso acaba. Quatro navegadores desenhando ao mesmo tempo já
ocupam quatro processadores, e um quinto worker precisa esperar a vez enquanto segura a memória
dele. Cada worker também custa uma partida, um processo Node e um navegador abertos e fechados, que
não compra nada quando o worker depois espera na fila, e o sistema operacional gasta tempo
alternando entre eles. Isso aparece no tempo de processador, que conta o trabalho feito e não a espera: os mesmos 120
testes levaram 36,1 segundos de processador com quatro workers e 52,2 com oito, numa execução que
terminou 0,9 segundo mais tarde.

O padrão do Playwright, metade dos processadores, fica abaixo desse ponto em qualquer máquina. A
documentação dele vai além para o CI e recomenda um worker só, por estabilidade e
reprodutibilidade, em máquinas que muitas vezes têm menos processadores que um notebook e os
dividem com outras tarefas.

**Meça, depois escolha.** O número certo é a menor quantidade a partir da qual o tempo de relógio
para de cair, na máquina em que a suíte de fato roda, escrito na configuração ou no comando do CI
para toda execução usá-lo. Todas as execuções aqui foram headless, o padrão do Playwright; a aula 17
cronometrou o que uma janela acrescenta.
