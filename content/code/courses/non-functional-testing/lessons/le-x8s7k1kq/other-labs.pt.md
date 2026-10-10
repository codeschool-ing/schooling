---
title: Throttling, a variação entre execuções, e os outros laboratórios
version: 1
---

A página lenta levou 13.1 s para pintar a imagem, numa VM que a buscou em `127.0.0.1` em poucos
milissegundos. **O Lighthouse não informou o que aconteceu nesta máquina; informou o que teria
acontecido num celular lento numa rede móvel.** Essa tradução se chama throttling
(estrangulamento), e é a primeira coisa a saber sobre qualquer número do Lighthouse.

## Throttling simulado

Os ajustes estão em todo relatório:

```
ana@nft:~/boxoffice$ jq -c '.configSettings | [.formFactor, .throttlingMethod, .throttling]' slow.json
["mobile","simulate",{"rttMs":150,"throughputKbps":1638.4,"requestLatencyMs":562.5,"downloadThroughputKbps":1474.5600000000002,"uploadThroughputKbps":675,"cpuSlowdownMultiplier":4}]
```

Um formato de celular, e uma rede de 150 ms de ida e volta a cerca de 1,6 megabit por segundo, com
um processador quatro vezes mais lento que o que roda o teste: um celular intermediário num 4G
ruim. `simulate` é o método padrão, e ele não deixa nada mais lento enquanto a página carrega.
**O Lighthouse carrega a página na velocidade total, grava cada requisição e cada tarefa, e depois
calcula quanto o mesmo carregamento teria levado com esses ajustes.** É por isso que `long-tasks`
imprimiu 2,000 ms para um laço de 500: a tarefa gravada foi multiplicada pelo
`cpuSlowdownMultiplier`. E 2.431.680 bytes a 1,6 megabit por segundo dão cerca de doze segundos
antes de a imagem poder ser pintada, o que é a maior parte dos 13.1 s.

Os outros métodos são `devtools`, que deixa a rede e o processador do navegador mais lentos de
verdade durante o carregamento, e `provided`, que não aplica nada e informa o que esta máquina
fez:

```
ana@nft:~/boxoffice$ lighthouse http://127.0.0.1:8000/ --quiet --only-categories=performance --output=json --chrome-flags="--headless=new --no-sandbox" --throttling-method=provided --output-path=raw.json
ana@nft:~/boxoffice$ jq -f metrics.jq raw.json
{
  "score": 0.9,
  "FCP": "2.3 s",
  "LCP": "2.3 s",
  "TBT": "0 ms",
  "CLS": "0.139",
  "Speed Index": "2.3 s"
}
```

**Nota 0.9 para a página que tirou 0.37**, porque uma imagem de 2,4 MB não custa nada por
loopback. O TBT é 0 ms: no carregamento real, o laço da lista terminou antes de qualquer pintura,
e o TBT só conta a partir da primeira pintura. O CLS não muda, porque o movimento é medido no
carregamento real seja qual for o método. FCP e LCP são 2.3 s, o que esta máquina levou e não
descreve visitante nenhum. Fique com o padrão, a menos que esteja reproduzindo um aparelho
específico, e quando comparar duas execuções, compare execuções feitas com os mesmos ajustes.

## Por que a nota muda entre execuções

Rode o mesmo comando cinco vezes, na mesma página, na mesma máquina:

```
ana@nft:~/boxoffice$ for i in 1 2 3 4 5; do lighthouse http://127.0.0.1:8000/ --quiet --only-categories=performance --output=json --chrome-flags="--headless=new --no-sandbox" --output-path=run.json; jq -r '[.categories.performance.score, .audits["largest-contentful-paint"].displayValue, .audits["total-blocking-time"].displayValue, .audits["cumulative-layout-shift"].displayValue] | @tsv' run.json; done
0.37	13.1 s	1,420 ms	0.139
0.39	13.1 s	1,420 ms	0.139
0.37	12.9 s	1,420 ms	0.139
0.37	12.9 s	1,420 ms	0.139
0.37	13.1 s	1,420 ms	0.139
```

Aqui a variação é pequena: a nota entre 0.37 e 0.39 e o LCP entre 12.9 s e 13.1 s, enquanto TBT
e CLS imprimiram o mesmo valor cinco vezes. A simulação é parte do motivo, já que a maior parte do
cálculo é aritmética de rede, que não muda entre carregamentos por loopback. A parte do
processador muda: as tarefas que o Lighthouse multiplica por quatro são as que ele mediu, e uma
máquina ocupada com outra coisa mede tarefas mais longas. Uma página buscada pela internet soma a
variação da rede e do servidor, e a variação de um site real é maior que a desta.

Então uma execução é uma amostra. **Um número que decide alguma coisa, uma comparação entre duas
versões ou um passa e reprova, vem de várias execuções e da mediana delas.** A própria documentação
do Lighthouse recomenda cinco. A aula 11 põe isso no portão dela.

## WebPageTest

O **WebPageTest** é um serviço online, hoje mantido pela Catchpoint, que carrega uma página em
navegadores e aparelhos reais em lugares reais: um celular em São Paulo, um desktop em Frankfurt,
numa rede moldada a um perfil que você escolhe. Ele não foi rodado para este curso, porque precisa
de uma página alcançável pela internet e a bilheteria só responde na sua VM. O que ele acrescenta
ao Lighthouse é a vista de um carregamento como ele aconteceu:

- **a tira de quadros** (*filmstrip*), capturas de tela tiradas em intervalos curtos durante o
  carregamento, para você ver a página em branco, depois o título, depois a imagem, e apontar o
  quadro em que o banner empurrou tudo para baixo;
- **a cascata** (*waterfall*), uma barra por requisição num eixo de tempo comum, dividida em
  consulta DNS, conexão, TLS, espera pelo primeiro byte e download. Um script que bloqueia a
  renderização aparece como uma barra pela qual a primeira pintura precisa esperar; uma imagem
  pesada, como uma barra comprida;
- **visitas repetidas e várias execuções**, a primeira visita com o cache vazio e uma segunda com
  ele cheio, e a execução mediana separada para você.

Ele responde "o que um visitante naquela cidade, naquele aparelho, vê", o que um laboratório na sua
própria máquina não responde, e custa uma página de verdade na internet.

## As ferramentas de desenvolvedor do próprio Chrome

O navegador do seu computador tem o mesmo motor. Com a bilheteria aberta para o seu desktop
(`BOXOFFICE_HOST=0.0.0.0 python3 app.py`, como a aula 1 explica), abra a página no Chrome e depois
as ferramentas de desenvolvedor com `F12`:

- o **painel Lighthouse** roda as mesmas auditorias da linha de comando e desenha o relatório
  HTML, com os mesmos ajustes de throttling para escolher;
- o **painel Performance** grava um carregamento ou uma interação como uma linha do tempo: cada
  tarefa da thread principal, com as tarefas longas marcadas em vermelho, os deslocamentos de
  layout e o elemento do LCP. É o único lugar desta aula onde o INP pode ser medido num
  laboratório, porque você está ali para clicar, e ele mostra as interações e quanto cada uma
  levou.

**Nenhum dos dois foi capturado aqui**, já que a VM não tem desktop. São as ferramentas para usar
enquanto se corrige uma página; a linha de comando é a que se usa quando a checagem tem de rodar
sem você. Lembre de iniciar a bilheteria de novo com o `python3 app.py` simples depois.
