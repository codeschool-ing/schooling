---
title: Olhando dentro de um container distroless
version: 1
---

**A primeira coisa que quase todo mundo tenta com um container que se comporta mal é um shell lá
dentro.** No `shelf` não há nenhum, de propósito, desde a aula 14:

```
ana@vm:~$ docker exec web sh
OCI runtime exec failed: exec failed: unable to start container process: exec: "sh": executable file not found in $PATH
```

Isso não é o beco sem saída que parece. **Quase tudo para que um shell seria usado dá para fazer de
fora**, e fazer de fora deixa a imagem tão pequena quanto era.

## Cinco jeitos de entrar que não precisam de shell

```
ana@vm:~$ docker top web -o pid,user,args
PID                 USER                COMMAND
11464               65532               /shelf
ana@vm:~$ docker diff web
ana@vm:~$ docker cp web:/shelf ./shelf-from-container && ls -l shelf-from-container
-rwxr-xr-x 1 ana ana 14735361 Oct  6 17:41 shelf-from-container
ana@vm:~$ docker run --rm --network container:web alpine:3.22 wget -qO- localhost:8080/health
ok
ana@vm:~$ docker run --rm --pid container:web alpine:3.22 ps -o pid,user,args
PID   USER     COMMAND
    1 65532    /shelf
   19 root     ps -o pid,user,args
```

Cada um responde à sua pergunta:

- **`docker top`** lista os processos do container, a partir do host: `/shelf`, como UID 65532.
- **`docker diff`** lista o que o container mudou na camada gravável, acrescentado (`A`), alterado (`C`)
  ou apagado (`D`). Nada, aqui, que é o que um programa que não escreve deve mostrar e o que um
  container só leitura (aula 21) garante.
- **`docker cp`** copia um arquivo para fora de um container, ou para dentro, rodando ou parado. A Ana
  pega o próprio binário, para comparar com o que ela construiu.
- **Um segundo container no mesmo namespace de rede**, `--network container:web`, enxerga o `localhost`
  do primeiro. Um container Alpine traz o `wget` e pede o `/health` ao `shelf` exatamente como os
  vizinhos do `shelf` pediriam.
- **Um segundo container no mesmo namespace de processos**, `--pid container:web`, enxerga os processos
  do primeiro: o `/shelf` como processo 1, e o `ps` emprestado ao lado.

Os dois últimos são o truque útil: **traga as ferramentas num container próprio, e junte-o aos
namespaces daquele que você está olhando.** A aula 4 mostrou que um container é um conjunto de
namespaces; essas flags compartilham um deles de propósito. O container de depuração vai embora quando
termina, e a imagem de produção nunca precisou carregar `wget` nem `ps`.

O `docker debug`, um comando do Docker Desktop, empacota a mesma ideia com uma caixa de ferramentas já
dentro. Ele não estava disponível no laboratório; as duas flags acima são a base dele, e existem em
todo Docker Engine.
