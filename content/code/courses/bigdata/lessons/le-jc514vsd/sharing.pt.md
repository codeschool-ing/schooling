---
title: Duas aplicações, um cluster
version: 1
---

**Um cluster é compartilhado, e o gerenciador decide quem recebe o quê.** A Ana inicia as trinta
tarefas de dois segundos, e alguns segundos depois um colega submete um job pequeno de seis
tarefas. A página do master, oito segundos depois que o segundo job foi submetido, e então o que
cada job imprimiu ao terminar:

```
ana@lab:~/big$ curl -s localhost:8080/json/ | jq -c '.activeapps[] | {name, cores, state}'
{"name":"tasks 6x2.0","cores":0,"state":"WAITING"}
{"name":"tasks 30x2.0","cores":3,"state":"RUNNING"}
ana@lab:~/big$ spark-submit tasks.py 30 2
WARNING: Using incubator modules: jdk.incubator.vector
30 tasks of 2 s: answer 435, 23.0 s
ana@lab:~/big$ spark-submit tasks.py 6 2
WARNING: Using incubator modules: jdk.incubator.vector
16:41:09 WARN Utils: Service 'SparkUI' could not bind on port 4040. Attempting port 4041.
16:41:28 WARN TaskSchedulerImpl: Initial job has not accepted any resources; check your cluster UI to ensure that workers are registered and have sufficient resources
6 tasks of 2 s: answer 15, 26.0 s
```

**O segundo job está `WAITING` com zero núcleos.** O primeiro pegou os três ao iniciar, como uma
aplicação no modo standalone faz por padrão, e o master distribui núcleos por ordem de chegada.
Sozinhas, seis tarefas de dois segundos levariam uns seis segundos; o job levou 26, quase todos na
fila. Nada falhou, e o único sinal que o colega recebeu foi o aviso que a aula 1 mostrou na seção 06,
`Initial job has not accepted any resources`. O outro aviso é inofensivo: o primeiro driver já
ocupava a porta 4040 com a sua página, então o segundo pegou a 4041.

O `spark.cores.max` limita quantos núcleos uma aplicação pode pegar. O mesmo par de jobs, com o
primeiro limitado a dois:

```
ana@lab:~/big$ curl -s localhost:8080/json/ | jq -c '.activeapps[] | {name, cores, state}'
{"name":"tasks 6x2.0","cores":1,"state":"RUNNING"}
{"name":"tasks 30x2.0","cores":2,"state":"RUNNING"}
ana@lab:~/big$ spark-submit --conf spark.cores.max=2 tasks.py 30 2
WARNING: Using incubator modules: jdk.incubator.vector
30 tasks of 2 s: answer 435, 32.7 s
ana@lab:~/big$ spark-submit tasks.py 6 2
WARNING: Using incubator modules: jdk.incubator.vector
16:41:51 WARN Utils: Service 'SparkUI' could not bind on port 4040. Attempting port 4041.
6 tasks of 2 s: answer 15, 14.2 s
```

**Agora os dois rodam juntos.** O job pequeno ficou com o terceiro núcleo e terminou em 14 segundos
em vez de 26. O grande pagou por isso: dois núcleos em vez de três, quinze ondas em vez de dez, 33
segundos em vez de 23. Um limite é uma decisão sobre quem espera, e alguém sempre espera.

## Como os gerenciadores diferem

O master standalone conhece uma política, quem chega primeiro leva, mais os limites que cada
aplicação impõe a si mesma. Isso basta para um cluster com uma equipe e alguns jobs por dia, e não
para um cluster que muitas equipes dividem. Os outros gerenciadores têm mais:

- **O YARN** divide o cluster em *filas*, cada uma com uma fatia garantida, então a fila dos
  analistas mantém 30% do cluster por mais que a carga noturna peça. A aula 12 roda um.
- **O Kubernetes** dá a cada namespace uma cota e agenda os executores como pods, então o Spark
  divide o cluster com tudo o mais que roda ali. Aula 13.
- **A alocação dinâmica**, uma configuração do Spark e não de um gerenciador, deixa uma aplicação
  devolver executores que não está usando e pedir mais quando as tarefas se acumulam. Um job que
  segura três núcleos durante um longo trecho ocioso é o problema que ela resolve, e a aula 14 põe
  preço nisso.

Dentro de uma aplicação também há escolha: **jobs do mesmo driver rodam em ordem de chegada**, a
menos que o `spark.scheduler.mode` seja `FAIR`, que deixa uma consulta curta de uma thread passar à
frente de uma longa de outra. Isso importa para um notebook ou um servidor que roda muitas
consultas pequenas numa aplicação de vida longa, e não muda como os núcleos se dividem entre
aplicações.
