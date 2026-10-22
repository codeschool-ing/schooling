---
title: x
version: 1
---

```
*
!target/bookshop-0.1.0.jar
```

```schooling-example
{"language": "dockerfile", "file": "Dockerfile", "parts": [{"code": "FROM eclipse-temurin:25-jre-noble AS layers", "note": "The first of two **stages**. It starts from the same base as the final image and is given a name, `layers`, so the second stage can copy out of it. Nothing else of it reaches the image you run."}, {"code": "WORKDIR /build\nCOPY target/bookshop-0.1.0.jar app.jar\nRUN java -Djarmode=tools -jar app.jar extract --layers --launcher --destination extracted\n", "note": "Inside it, the jar is copied in and split with the command from the last section. `WORKDIR` creates `/build` and makes it the current directory for what follows. The jar never needs to be unpacked on your machine."}, {"code": "FROM eclipse-temurin:25-jre-noble", "note": "The second `FROM` starts again from a clean copy of the base. **This is the image that ships**: the JRE on Ubuntu 24.04, plus whatever the lines below add."}, {"code": "RUN useradd --system --uid 10001 bookshop\nUSER bookshop", "note": "A system user with a fixed number, and every instruction after `USER`, including the running application, is that user's. A process that breaks out of the bookshop finds itself an ordinary user inside the container, not root."}, {"code": "WORKDIR /app", "note": "The directory the application runs in, created owned by root and readable by all."}, {"code": "COPY --from=layers /build/extracted/dependencies/ ./\nCOPY --from=layers /build/extracted/spring-boot-loader/ ./\nCOPY --from=layers /build/extracted/snapshot-dependencies/ ./\nCOPY --from=layers /build/extracted/application/ ./", "note": "The four directories, in the order of how rarely they change. Each `COPY` is a layer of the image, and the trailing `./` merges all four into `/app`, which is the layout the launcher expects."}, {"code": "EXPOSE 8080 8081", "note": "Documentation, nothing more: it says which ports the process listens on. Publishing them is the job of whoever runs the container."}, {"code": "ENTRYPOINT [\"java\", \"-XX:MaxRAMPercentage=75\", \"org.springframework.boot.loader.launch.JarLauncher\"]", "note": "The **exec form**, a JSON list, so Docker starts `java` itself as the container's first process. `-XX:MaxRAMPercentage=75` sizes the heap from the container's memory limit, and `JarLauncher` is the class the manifest named, now found in the merged directory rather than inside a jar."}]}
```
