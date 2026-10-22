---
title: Stopping cleanly, and the memory it is given
version: 1
---

On a server the bookshop is stopped far more often than it crashes: every deployment replaces it,
every scale-down removes a copy, every machine restart stops everything. Each of those stops it the
same way. The process gets **SIGTERM**, a request to finish; if it is still running after a grace
period, it gets **SIGKILL**, which cannot be refused or handled. Docker's grace period is ten
seconds unless somebody changes it. A process that hears SIGTERM finishes the requests it is in the
middle of and closes its connections. One that does not hear it is killed mid-request ten seconds
later.

## A clean stop

```
ana@vm:~/bookshop$ time docker compose stop app
 Container bookshop-app-1 Stopping 
 Container bookshop-app-1 Stopped 

real	0m0.410s
user	0m0.050s
sys	0m0.031s
```

Well under a second. What the bookshop did in that time is in its log:

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

**`Commencing graceful shutdown. Waiting for active requests to complete`**, twice, because there are
two Tomcats: the API's on 8080 and the management server's on 8081. Each stopped accepting
connections, waited for the requests already running (there were none), and reported complete. Then
Spring closed the rest of the context in order, the entity manager first and the connection pool
last, so PostgreSQL saw its connections closed rather than dropped. Nothing in `application.properties`
asks for any of this: Spring Boot shuts its web server down gracefully by default, and allows each
phase of the shutdown up to 30 seconds (`spring.lifecycle.timeout-per-shutdown-phase`). Docker's ten
seconds are the shorter limit, which is why a deployment with slow requests raises Docker's side
too, with `stop_grace_period` in `compose.yaml`.

```
ana@vm:~/bookshop$ docker inspect --format '{{.State.ExitCode}}' bookshop-app-1
143
```

**143 is 128 + 15**, and 15 is SIGTERM's number: a Java process ended by SIGTERM exits with that code
after its shutdown hooks have run. It is the code of a normal stop, not of a failure.

## The same image, with one line written differently

The Dockerfile's last line is a JSON list, the **exec form**. Docker also accepts the **shell form**,
which looks the same without the brackets, and which many Dockerfiles use. As a detour, replace the
last line of the Dockerfile with this:

```dockerfile
ENTRYPOINT java -XX:MaxRAMPercentage=75 org.springframework.boot.loader.launch.JarLauncher
```

Rebuild the image and replace the container in one command, `--build`, and look at the processes:

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

The shell form runs the line through `/bin/sh -c`, so the container's first process, **PID 1**, is
the shell, and Java is its child. Stop it:

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

Ten seconds, no line about a shutdown, and **137, which is 128 + 9: SIGKILL**. Docker sent SIGTERM to
PID 1, as it always does, and the shell did not pass it on to Java. PID 1 is also special to Linux:
a signal it has no handler for is ignored rather than acted on, so the shell did not even exit.
Docker waited its ten seconds and killed the lot, and any request in progress would have been cut off
mid-answer. With the exec form there is no shell: Java is PID 1, and the JVM installs a handler for
SIGTERM.

Put the exec-form line back, exactly as it was, and rebuild:

```
ana@vm:~/bookshop$ docker compose up -d --build --wait 2>&1 | tail -n 3
 Container bookshop-app-1 Waiting 
 Container bookshop-db-1 Healthy 
 Container bookshop-app-1 Healthy 
```

## How much memory the heap may use

Without a `-Xmx`, the JVM sizes its heap from the memory it can see, and inside a container it sees
the container's limit rather than the machine's. The base image can show what it decides, without any
application, by printing its final flags. First with no limit at all:

```
ana@vm:~/bookshop$ docker run --rm eclipse-temurin:25-jre-noble java -XX:+PrintFlagsFinal -version | grep -E ' MaxHeapSize | UseG1GC | UseSerialGC '
openjdk version "25.0.4.1" 2026-08-18 LTS
OpenJDK Runtime Environment Temurin-25.0.4.1+1 (build 25.0.4.1+1-LTS)
OpenJDK 64-Bit Server VM Temurin-25.0.4.1+1 (build 25.0.4.1+1-LTS, mixed mode, sharing)
   size_t MaxHeapSize                              = 4219469824                                {product} {ergonomic}
     bool UseG1GC                                  = true                                      {product} {ergonomic}
     bool UseSerialGC                              = false                                     {product} {default}
```

**4219469824 bytes, about 3.9 GiB**: a quarter of this 15 GB machine, because the default
`MaxRAMPercentage` is 25. Now with the 1 GB limit that `compose.yaml` gives the bookshop:

```
ana@vm:~/bookshop$ docker run --rm --memory=1g eclipse-temurin:25-jre-noble java -XX:+PrintFlagsFinal -version | grep -E ' MaxHeapSize | UseG1GC | UseSerialGC '
openjdk version "25.0.4.1" 2026-08-18 LTS
OpenJDK Runtime Environment Temurin-25.0.4.1+1 (build 25.0.4.1+1-LTS)
OpenJDK 64-Bit Server VM Temurin-25.0.4.1+1 (build 25.0.4.1+1-LTS, mixed mode, sharing)
   size_t MaxHeapSize                              = 268435456                                 {product} {ergonomic}
     bool UseG1GC                                  = false                                     {product} {default}
     bool UseSerialGC                              = true                                      {product} {ergonomic}
```

**268435456 bytes, 256 MiB**, a quarter of the limit. The JVM read the limit and believed it; it even
chose a different garbage collector, the serial one, for a machine it now judges too small for G1.
For a Spring Boot application with Hibernate, 256 MiB of heap in a 1 GiB container leaves three
quarters of the memory unused while the heap runs short. The Dockerfile's `-XX:MaxRAMPercentage=75`
raises the share:

```
ana@vm:~/bookshop$ docker run --rm --memory=1g eclipse-temurin:25-jre-noble java -XX:MaxRAMPercentage=75 -XX:+PrintFlagsFinal -version | grep -E ' MaxHeapSize '
openjdk version "25.0.4.1" 2026-08-18 LTS
OpenJDK Runtime Environment Temurin-25.0.4.1+1 (build 25.0.4.1+1-LTS)
OpenJDK 64-Bit Server VM Temurin-25.0.4.1+1 (build 25.0.4.1+1-LTS, mixed mode, sharing)
   size_t MaxHeapSize                              = 805306368                                 {product} {ergonomic}
```

**805306368 bytes, 768 MiB.** Not 100%, because the heap is not all the JVM uses: the classes'
metadata, every thread's stack, the code the JIT compiles and the network buffers all live outside
it, and a process that goes over the container's limit is killed by the kernel, with no shutdown at
all. A quarter of the limit left for all of that is a common starting point, and the numbers that
tell you whether it is right are lesson 22's metrics. The running bookshop, from outside and from
inside:

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

`docker stats` shows what the container is using against its limit. The actuator's `jvm.memory.max`
for the heap is 778502144 bytes, 742.4 MiB: the 768 MiB heap minus one of the two small survivor
spaces of the young generation, which the serial collector always keeps empty and does not count.

When you are done, stop everything. `-v` deletes the volume too, and with it the database:

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

## Where it goes from here

What this lesson produced is the thing every deployment platform takes in: an image, and the
configuration it needs as environment variables. The image goes to a **registry** next, under a tag
that names the version rather than `latest` (`docker` lessons 15 and 16). A pipeline builds and
pushes it on every commit (`docker` lesson 26, and `testing-cicd` lesson 5 for the pipeline itself).
From the registry a **platform** runs it: a managed service that runs containers, or Kubernetes, or
plain Docker on a server, which `docker` lesson 27 compares. Every one of them asks the same four
things of the bookshop that this lesson and lesson 22 prepared: the configuration from the
environment, a memory limit to size itself by, SIGTERM before it is stopped, and a readiness answer
before it is sent traffic.
