---
title: Medindo o pipeline
version: 1
---

Um orçamento de tempo só serve se alguém sabe quanto dele está sendo gasto. **O pipeline já se
mede**: cada linha que ele imprime termina nos segundos que aquele estágio levou, e cada push devolve
essas linhas a quem fez o push. O que ele não diz é para onde vão os segundos dentro de um estágio, e
esse é o número que diz o que mudar quando um estágio fica lento.

### Dentro do estágio de teste

O estágio de teste faz três coisas: cria um ambiente virtual, instala nele os pacotes fixados e roda
o pytest. Cronometre cada uma no clone limpo da seção anterior, começando sem ambiente, do jeito que
toda execução do servidor começa:

```
ana@vm:~/linkbox$ cd /tmp/linkbox-run && rm -rf .venv
ana@vm:/tmp/linkbox-run$ time uv venv -q .venv

real	0m0.028s
user	0m0.008s
sys	0m0.009s
ana@vm:/tmp/linkbox-run$ time uv pip install -q -r requirements.txt -r requirements-dev.txt

real	0m0.073s
user	0m0.018s
sys	0m0.054s
ana@vm:/tmp/linkbox-run$ time .venv/bin/python -m pytest -q
...                                                                      [100%]
3 passed in 0.43s

real	0m1.062s
user	0m0.845s
sys	0m0.202s
ana@vm:/tmp/linkbox-run$ time docker build -q -t linkbox:dev .
sha256:700b22e3ef4bc00d17c40627b168f793b0dc439b6dedb98bcc2dc5a4d60fe1e7

real	0m0.495s
user	0m0.110s
sys	0m0.142s
ana@vm:/tmp/linkbox-run$ cd ~/linkbox && rm -rf /tmp/linkbox-run
```

O `time` imprime três números, e `real` é o que uma pessoa espera.

**A maior parte do estágio de teste são os testes.** Criar o ambiente levou 0,028 segundo e instalar
nele os pacotes fixados, 0,073. O pytest diz que os três testes rodaram em 0,43 segundo, e a linha
`real` em volta, 1,062, soma o Python subindo e importando o Flask e o próprio pytest. A instalação só
é rápida assim porque o `uv` guarda um cache de todo pacote que já baixou, em `~/.cache/uv`, e os liga
a partir dali. Num runner hospedado que começa de uma máquina vazia, a mesma linha baixa todos os
pacotes de novo a cada execução. Salvar o cache e restaurá-lo entre execuções é para isso que servem
os recursos de cache do GitHub Actions e do GitLab CI.

O build com cache, 0,495 segundo, é o mesmo tipo de número: o Docker achou cada camada já construída
para exatamente esses arquivos e as reaproveitou. A seção da execução noturna desta aula constrói a
mesma imagem sem cache, e a diferença entre as duas é o custo de cada linha do `Dockerfile` que o
cache estava escondendo.

### O que vigiar

Uma execução sozinha diz pouco. O que importa é **a tendência por estágio**, porque pipelines ficam
lentos um segundo de cada vez e ninguém decide isso. Três hábitos mantêm o orçamento honesto:

- **Olhe o tempo de cada estágio, em cada execução, não só o total.** Um total que cresce um minuto é
  um estágio que cresceu um minuto, e o estágio é o que alguém consegue consertar.
- **Guarde os números.** O servidor do linkbox guarda o log de cada estágio em `~/ci/runs/N`, mas não
  as linhas de tempo, que vão para o terminal de quem fez o push e somem quando ele fecha. Salvá-las é
  mais uma linha no hook, e é o que permite responder "quando o estágio de teste passou a levar um
  minuto?". A CI hospedada guarda uma duração por job e por passo, pelo prazo que a documentação dela
  informa.
- **Decida o que acontece no limite antes de chegar nele.** Quando um push passa do orçamento, algo
  vai para a lista noturna, ou fica mais rápido, ou é dividido para ler só o que mudou. Um time que
  não decidiu isso antes decide do pior jeito, marcando um estágio como "pode falhar".

### Quão exatos são os números

O pipeline mede com o `SECONDS` do bash, um número inteiro de segundos desde que o shell começou. A
diferença entre duas leituras pode errar um segundo para qualquer lado, então "passed in 0s" quer
dizer "em menos de mais ou menos um segundo", e duas execuções do mesmo estágio podem diferir em um ou
dois segundos sem nada mudar. **Isso é preciso o bastante para um orçamento medido em minutos**, e é
por isso que os tempos deste curso são citados como foram impressos, não em milissegundos. Quando um
estágio precisa de um estudo mais fino, o instrumento é o `time` nas partes dele, como acima.

Cada número também depende da máquina. Todo tempo deste curso foi gravado num mesmo laptop, e os seus
vão ser outros. O que deve bater é o formato: qual estágio domina, e quão longe o build com cache fica
do build limpo.
