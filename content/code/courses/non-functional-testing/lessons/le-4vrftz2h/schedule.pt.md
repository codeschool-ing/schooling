---
title: Num horário fixo, e pegando uma falha
version: 1
---

Uma sonda rodada uma vez é um teste. **Rodada num horário fixo, ela vira um monitor**, e o horário
decide quanto tempo uma queda pode durar antes que alguém saiba. O agendador mais simples é um laço
do shell. No segundo terminal, com o `observed.py` rodando de novo no primeiro:

```
ana@nft:~/monitor$ for i in 1 2 3; do python3 probe.py; sleep 5; done
16:33:06 PASS list=200/24ms show=200/19ms book=201/57ms
16:33:11 PASS list=200/19ms show=200/12ms book=201/55ms
16:33:16 PASS list=200/22ms show=200/12ms book=201/56ms
```

Três execuções, com cinco segundos entre elas, três aprovações. Um laço de verdade não tem `for` e
dorme por mais tempo:

```sh
while true; do python3 probe.py >> probe.log; sleep 60; done
```

**Esse laço morre junto com o terminal em que roda**, o que serve para uma tarde e não serve para
um monitor. Dois programas que vêm com o Ubuntu fazem melhor.

O `watch -n 60 python3 probe.py` reexecuta o comando a cada 60 segundos e redesenha a tela com a
última saída. É um jeito de olhar uma sonda enquanto você trabalha em outra coisa, não um monitor:
não guarda histórico, e também morre com o terminal. Ele não foi capturado aqui, porque desenha uma
tela inteira em vez de imprimir linhas.

O `cron` roda comandos num horário fixo sem terminal nenhum, e continua fazendo isso depois de
reinicializações. O `crontab -e` abre a sua própria agenda num editor; uma linha roda a sonda a cada
minuto e guarda todos os resultados:

```sh
* * * * * cd ~/monitor && python3 probe.py >> probe.log 2>&1
```

Os cinco campos são minuto, hora, dia do mês, mês e dia da semana, e `*` quer dizer todos, então
esta linha quer dizer todo minuto de todo dia. O `crontab -l` lista o que está instalado. **A
máquina em que estas transcrições foram gravadas não tem `cron`**, então essa linha não foi
executada aqui; numa VM Ubuntu ele já vem instalado e rodando. Um minuto é a menor granularidade do
cron, e é o intervalo comum para uma verificação de produção: frequente o bastante para pegar uma
queda em minutos, raro o bastante para a sonda ser uma fração pequena do tráfego.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l23-interval\" aria-label=\"Uma linha do tempo de oito minutos com uma verificação a cada minuto, desenhada como um ponto. As três primeiras passam. Uma queda começa logo depois da terceira verificação, mostrada como uma faixa sombreada até o fim. A quarta verificação, quase um minuto depois, é a primeira a falhar; a quinta falha também, e só então, com duas falhas seguidas, alguém é avisado. Entre o início da queda e o aviso à pessoa passam quase dois intervalos.\"><defs><marker id=\"l23-interval-nf-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l23-interval-nf-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"238.0\" y=\"70.0\" width=\"412.0\" height=\"100.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"244.0\" y=\"82.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">a queda começa</text><path d=\"M50.0 120.0 L650.0 120.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><circle cx=\"70.0\" cy=\"120.0\" r=\"7\" fill=\"var(--phosphor)\"></circle><text x=\"70.0\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0:00</text><text x=\"70.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">passa</text><circle cx=\"150.0\" cy=\"120.0\" r=\"7\" fill=\"var(--phosphor)\"></circle><text x=\"150.0\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1:00</text><text x=\"150.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">passa</text><circle cx=\"230.0\" cy=\"120.0\" r=\"7\" fill=\"var(--phosphor)\"></circle><text x=\"230.0\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">2:00</text><text x=\"230.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">passa</text><circle cx=\"310.0\" cy=\"120.0\" r=\"7\" fill=\"var(--amber)\"></circle><text x=\"310.0\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">3:00</text><text x=\"310.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">falha</text><circle cx=\"390.0\" cy=\"120.0\" r=\"7\" fill=\"var(--amber)\"></circle><text x=\"390.0\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">4:00</text><text x=\"390.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">falha</text><circle cx=\"470.0\" cy=\"120.0\" r=\"7\" fill=\"var(--amber)\"></circle><text x=\"470.0\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">5:00</text><text x=\"470.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">falha</text><circle cx=\"550.0\" cy=\"120.0\" r=\"7\" fill=\"var(--amber)\"></circle><text x=\"550.0\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">6:00</text><text x=\"550.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">falha</text><circle cx=\"630.0\" cy=\"120.0\" r=\"7\" fill=\"var(--amber)\"></circle><text x=\"630.0\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">7:00</text><text x=\"630.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">falha</text><path d=\"M238.0 198.0 L306.0 198.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l23-interval-nf-ah-paper-dim)\"></path><text x=\"274.0\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">até um intervalo</text><path d=\"M238.0 228.0 L386.0 228.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l23-interval-nf-ah-amber)\"></path><text x=\"398.0\" y=\"228.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">duas seguidas: alguém é avisado</text></svg>", "caption": "Verificando a cada minuto, uma queda é vista primeiro com até um minuto de atraso, e confirmada um minuto depois."}
```

A figura é a aritmética de um horário. Uma falha que começa logo depois de uma verificação só é
vista na próxima, então **o intervalo é o pior atraso possível até a primeira verificação
reprovada**. E ninguém aciona uma pessoa por uma verificação reprovada, por um motivo a que a
próxima seção e a aula 24 voltam: uma falha isolada pode ser a rede entre a sonda e o servidor, e
não o servidor. Exigir duas falhas seguidas dobra o atraso e elimina a maior parte dos alarmes
falsos.

## Uma falha que não é uma queda

Parar o servidor é a falha fácil. A difícil é a bilheteria que ainda responde, certo, e devagar
demais. O `slow.py` é o `observed.py` com o provedor de pagamento numa tarde ruim: 900 ms por
chamada em vez de 40. Crie-o em `~/boxoffice`; como o `observed.py`, ele não muda nada no `app.py` e
só troca um número depois de importá-lo:

```python
# boxoffice/slow.py
# observed.py with a payment provider having a bad afternoon: 900 ms a call.
import app, observed

app.PAYMENT_SECONDS = 0.9
observed.serve()
```

Pare o `observed.py`, suba `python3 slow.py > slow.log` no lugar dele, e rode a sonda:

```
ana@nft:~/monitor$ python3 probe.py; echo "exit $?"
16:33:23 FAIL list=200/23ms show=200/15ms book=201/916ms -- book: 916 ms is over 500 ms (request 9e7fba65765e4940)
exit 1
```

A listagem e o espetáculo estão tão rápidos quanto antes. **A reserva respondeu 201 e reservou o
assento, e a sonda reprovou mesmo assim**, porque levou 916 ms contra um limite de 500. Todo código
de status que o servidor devolveu foi um sucesso, então um alerta de 5xx não diria nada; as métricas
da aula 22 só mostrariam isso como um percentil de duração que alguém estivesse olhando. Buscar no
log do servidor qualquer coisa acima de 500 ms acha a mesma requisição, pelo id que a sonda
imprimiu:

```
ana@nft:~/boxoffice$ jq -c 'select(.ms > 500)' slow.log
{"ts":"2026-10-10T19:33:23.401+00:00","level":"info","request_id":"9e7fba65765e4940","method":"POST","route":"/bookings","path":"/bookings","status":201,"ms":915.3}
```

O tempo do próprio servidor para aquela reserva foi de 915.3 ms, e 900 deles foram o pagamento. Uma
sonda e um log que compartilham um id fazem disso uma busca de uma linha. Pare o `slow.py` e volte
para `python3 observed.py > requests.log` quando terminar.
