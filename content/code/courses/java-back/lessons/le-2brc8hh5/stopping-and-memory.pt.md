---
title: Parar de forma limpa, e a memória que ela recebe
version: 1
---

Num servidor, a livraria é parada muito mais vezes do que falha: cada implantação a substitui, cada
redução de escala remove uma cópia, cada reinício da máquina para tudo. Todas essas paradas acontecem
do mesmo jeito. O processo recebe **SIGTERM**, um pedido para terminar; se ainda estiver rodando
depois de um prazo de tolerância, recebe **SIGKILL**, que não pode ser recusado nem tratado. O prazo
do Docker é de dez segundos, a menos que alguém o mude. Um processo que ouve o SIGTERM termina as
requisições que tem em andamento e fecha as suas conexões. Um que não ouve é morto no meio de uma
requisição dez segundos depois.

## Uma parada limpa

```
ana@vm:~/bookshop$ time docker compose stop app
 Container bookshop-app-1 Stopping 
 Container bookshop-app-1 Stopped 

real	0m0.410s
user	0m0.050s
sys	0m0.031s
```

Bem menos de um segundo. O que a livraria fez nesse tempo está no log dela:

```
ana@vm:~/bookshop$ docker compose logs app | grep -E 'graceful|Shutdown'
app-1  | 2026-10-22T23:10:37.852Z  INFO 1 --- [bookshop] [ionShutdownHook] [] o.s.boot.tomcat.GracefulShutdown         : Commencing graceful shutdown. Waiting for active requests to complete
app-1  | 2026-10-22T23:10:37.856Z  INFO 1 --- [bookshop] [tomcat-shutdown] [] o.s.boot.tomcat.GracefulShutdown         : Graceful shutdown complete
app-1  | 2026-10-22T23:10:37.857Z  INFO 1 --- [bookshop] [ionShutdownHook] [] o.s.boot.tomcat.GracefulShutdown         : Commencing graceful shutdown. Waiting for active requests to complete
app-1  | 2026-10-22T23:10:37.858Z  INFO 1 --- [bookshop] [tomcat-shutdown] [] o.s.boot.tomcat.GracefulShutdown         : Graceful shutdown complete
app-1  | 2026-10-22T23:10:37.872Z  INFO 1 --- [bookshop] [ionShutdownHook] [] j.LocalContainerEntityManagerFactoryBean : Closing JPA EntityManagerFactory for persistence unit 'default'
app-1  | 2026-10-22T23:10:37.874Z  INFO 1 --- [bookshop] [ionShutdownHook] [] com.zaxxer.hikari.HikariDataSource       : bookshop-pool - Shutdown initiated...
app-1  | 2026-10-22T23:10:37.878Z  INFO 1 --- [bookshop] [ionShutdownHook] [] com.zaxxer.hikari.HikariDataSource       : bookshop-pool - Shutdown completed.
```

**`Commencing graceful shutdown. Waiting for active requests to complete`**, duas vezes, porque há
dois Tomcats: o da API, na 8080, e o do servidor de gerenciamento, na 8081. Cada um parou de aceitar
conexões, esperou as requisições que já estavam rodando (não havia nenhuma) e informou que terminou.
Depois o Spring fechou o resto do contexto em ordem, o entity manager primeiro e o pool de conexões
por último, para que o PostgreSQL visse as suas conexões fechadas, e não derrubadas. Nada no
`application.properties` pede nada disso: o Spring Boot desliga o servidor web de forma graciosa por
padrão, e dá a cada fase do desligamento até 30 segundos
(`spring.lifecycle.timeout-per-shutdown-phase`). Os dez segundos do Docker são o limite mais curto, e
é por isso que uma implantação com requisições lentas aumenta também o lado do Docker, com
`stop_grace_period` no `compose.yaml`.

```
ana@vm:~/bookshop$ docker inspect --format '{{.State.ExitCode}}' bookshop-app-1
143
```

**143 é 128 + 15**, e 15 é o número do SIGTERM: um processo Java encerrado por SIGTERM sai com esse
código depois que os seus ganchos de desligamento rodaram. É o código de uma parada normal, e não de
uma falha.

## A mesma imagem, com uma linha escrita de outro jeito

A última linha do Dockerfile é uma lista JSON, a **forma exec**. O Docker aceita também a **forma
shell**, que é a mesma coisa sem os colchetes, e que muitos Dockerfiles usam. Como desvio, substitua
a última linha do Dockerfile por esta:

```dockerfile
ENTRYPOINT java -XX:MaxRAMPercentage=75 org.springframework.boot.loader.launch.JarLauncher
```

Reconstrua a imagem e substitua o contêiner num comando só, `--build`, e olhe os processos:

```
ana@vm:~/bookshop$ docker compose up -d --build --wait 2>&1 | tail -n 3
 Container bookshop-app-1 Waiting 
 Container bookshop-db-1 Healthy 
 Container bookshop-app-1 Healthy 
ana@vm:~/bookshop$ docker compose exec app ps -o pid,user,args
    PID USER     COMMAND
      1 bookshop /bin/sh -c java -XX:MaxRAMPercentage=75 org.springframework.boot.loader.launch.JarLauncher
      7 bookshop java -XX:MaxRAMPercentage=75 org.springframework.boot.loader.launch.JarLauncher
     72 bookshop ps -o pid,user,args
```

A forma shell executa a linha por meio de `/bin/sh -c`, então o primeiro processo do contêiner, o
**PID 1**, é o shell, e o Java é filho dele. Pare-o:

```
ana@vm:~/bookshop$ time docker compose stop app
 Container bookshop-app-1 Stopping 
 Container bookshop-app-1 Stopped 

real	0m10.335s
user	0m0.058s
sys	0m0.016s
ana@vm:~/bookshop$ docker compose logs app | grep -E 'graceful|Shutdown'
ana@vm:~/bookshop$ docker inspect --format '{{.State.ExitCode}}' bookshop-app-1
137
```

Dez segundos, nenhuma linha sobre desligamento, e **137, que é 128 + 9: SIGKILL**. O Docker mandou o
SIGTERM para o PID 1, como sempre faz, e o shell não o repassou ao Java. O PID 1 também é especial
para o Linux: um sinal para o qual ele não tem tratador é ignorado em vez de produzir efeito, então o
shell nem sequer terminou. O Docker esperou os seus dez segundos e matou tudo, e qualquer requisição
em andamento teria sido cortada no meio da resposta. Com a forma exec não há shell: o Java é o PID 1,
e a JVM instala um tratador para o SIGTERM.

Volte a linha na forma exec, exatamente como era, e reconstrua:

```
ana@vm:~/bookshop$ docker compose up -d --build --wait 2>&1 | tail -n 3
 Container bookshop-app-1 Waiting 
 Container bookshop-db-1 Healthy 
 Container bookshop-app-1 Healthy 
```

## Quanta memória o heap pode usar

Sem um `-Xmx`, a JVM dimensiona o heap a partir da memória que enxerga, e dentro de um contêiner ela
enxerga o limite do contêiner, e não o da máquina. A imagem base consegue mostrar o que ela decide,
sem aplicação nenhuma, imprimindo as suas flags finais. Primeiro sem limite algum:

```
ana@vm:~/bookshop$ docker run --rm eclipse-temurin:25-jre-noble java -XX:+PrintFlagsFinal -version | grep -E ' MaxHeapSize | UseG1GC | UseSerialGC '
openjdk version "25.0.4.1" 2026-08-18 LTS
OpenJDK Runtime Environment Temurin-25.0.4.1+1 (build 25.0.4.1+1-LTS)
OpenJDK 64-Bit Server VM Temurin-25.0.4.1+1 (build 25.0.4.1+1-LTS, mixed mode, sharing)
   size_t MaxHeapSize                              = 4219469824                                {product} {ergonomic}
     bool UseG1GC                                  = true                                      {product} {ergonomic}
     bool UseSerialGC                              = false                                     {product} {default}
```

**4219469824 bytes, uns 3,9 GiB**: um quarto desta máquina de 15 GB, porque o `MaxRAMPercentage`
padrão é 25. Agora com o limite de 1 GB que o `compose.yaml` dá à livraria:

```
ana@vm:~/bookshop$ docker run --rm --memory=1g eclipse-temurin:25-jre-noble java -XX:+PrintFlagsFinal -version | grep -E ' MaxHeapSize | UseG1GC | UseSerialGC '
openjdk version "25.0.4.1" 2026-08-18 LTS
OpenJDK Runtime Environment Temurin-25.0.4.1+1 (build 25.0.4.1+1-LTS)
OpenJDK 64-Bit Server VM Temurin-25.0.4.1+1 (build 25.0.4.1+1-LTS, mixed mode, sharing)
   size_t MaxHeapSize                              = 268435456                                 {product} {ergonomic}
     bool UseG1GC                                  = false                                     {product} {default}
     bool UseSerialGC                              = true                                      {product} {ergonomic}
```

**268435456 bytes, 256 MiB**, um quarto do limite. A JVM leu o limite e acreditou nele; até escolheu
outro coletor de lixo, o serial, para uma máquina que agora julga pequena demais para o G1. Para uma
aplicação Spring Boot com Hibernate, 256 MiB de heap num contêiner de 1 GiB deixam três quartos da
memória sem uso enquanto o heap fica curto. O `-XX:MaxRAMPercentage=75` do Dockerfile aumenta a
fração:

```
ana@vm:~/bookshop$ docker run --rm --memory=1g eclipse-temurin:25-jre-noble java -XX:MaxRAMPercentage=75 -XX:+PrintFlagsFinal -version | grep -E ' MaxHeapSize '
openjdk version "25.0.4.1" 2026-08-18 LTS
OpenJDK Runtime Environment Temurin-25.0.4.1+1 (build 25.0.4.1+1-LTS)
OpenJDK 64-Bit Server VM Temurin-25.0.4.1+1 (build 25.0.4.1+1-LTS, mixed mode, sharing)
   size_t MaxHeapSize                              = 805306368                                 {product} {ergonomic}
```

**805306368 bytes, 768 MiB.** Não 100%, porque o heap não é tudo o que a JVM usa: os metadados das
classes, a pilha de cada thread, o código que o JIT compila e os buffers de rede vivem fora dele, e
um processo que passa do limite do contêiner é morto pelo kernel, sem desligamento nenhum. Deixar um
quarto do limite para tudo isso é um ponto de partida comum, e os números que dizem se ele está certo
são as métricas da aula 22. A livraria em execução, vista de fora e de dentro:

```
ana@vm:~/bookshop$ docker stats --no-stream --format '{{.Name}}  {{.MemUsage}}' bookshop-app-1
bookshop-app-1  296.5MiB / 1GiB
ana@vm:~/bookshop$ curl -s '127.0.0.1:8081/actuator/metrics/jvm.memory.max?tag=area:heap' | python3 -m json.tool
{
    "availableTags": [
        {
            "tag": "id",
            "values": [
                "Survivor Space",
                "Eden Space",
                "Tenured Gen"
            ]
        }
    ],
    "baseUnit": "bytes",
    "description": "The maximum amount of memory in bytes that can be used for memory management",
    "measurements": [
        {
            "statistic": "VALUE",
            "value": 778502144.0
        }
    ],
    "name": "jvm.memory.max"
}
```

O `docker stats` mostra o que o contêiner usa contra o seu limite. O `jvm.memory.max` do actuator
para o heap é de 778502144 bytes, 742,4 MiB: o heap de 768 MiB menos um dos dois pequenos espaços
sobreviventes da geração jovem, que o coletor serial sempre mantém vazio e não conta.

Quando terminar, pare tudo. O `-v` apaga também o volume, e com ele o banco:

```
ana@vm:~/bookshop$ docker compose down -v
 Container bookshop-app-1 Stopping 
 Container bookshop-app-1 Stopped 
 Container bookshop-app-1 Removing 
 Container bookshop-app-1 Removed 
 Container bookshop-db-1 Stopping 
 Container bookshop-db-1 Stopped 
 Container bookshop-db-1 Removing 
 Container bookshop-db-1 Removed 
 Volume bookshop_db-data Removing 
 Network bookshop_default Removing 
 Volume bookshop_db-data Removed 
 Network bookshop_default Removed 
```

## Para onde ela vai daqui

O que esta aula produziu é o que toda plataforma de implantação recebe: uma imagem, e a configuração
de que ela precisa como variáveis de ambiente. A imagem vai em seguida para um **registro**, sob uma
tag que nomeia a versão em vez de `latest` (aulas 15 e 16 do curso `docker`). Um pipeline a
constrói e a envia a cada commit (aula 26 do `docker`, e a aula 5 de `testing-cicd` para o pipeline
em si). Do registro, uma **plataforma** a executa: um serviço gerenciado que roda contêineres, ou o
Kubernetes, ou o Docker puro num servidor, que a aula 27 do `docker` compara. Todas pedem à livraria
as mesmas quatro coisas que esta aula e a aula 22 prepararam: a configuração pelo ambiente, um limite
de memória para se dimensionar, o SIGTERM antes de ser parada e uma resposta de readiness antes de
receber tráfego.
