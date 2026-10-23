---
title: Paredes feitas pelo systemd
version: 1
---

**O systemd consegue montar uma sandbox em volta de qualquer comando, com as mesmas opções que
oferece a todo serviço.** O `systemd-run` inicia o comando como um serviço temporário, e cada `-p`
acrescenta uma parede. As que esta aula usa respondem cada uma a uma das três tentativas do script,
mais duas que não custam nada:

| opção | a parede |
|---|---|
| `ProtectHome=tmpfs` | todo diretório home é trocado por um vazio; `BindReadOnlyPaths=` devolve o único arquivo que o programa pode ler |
| `ProtectSystem=strict` | o sistema de arquivos inteiro fica somente leitura, `/etc` inclusive |
| `PrivateNetwork=yes` | o programa ganha uma rede própria com só uma interface de loopback dentro |
| `PrivateTmp=yes` | um `/tmp` que ninguém mais divide |
| `NoNewPrivileges=yes` | nada que ele rode consegue ganhar direitos, por `sudo` ou por um programa set-user-id |

`--uid=ana` o roda como você, então as paredes são a única diferença em relação a você mesmo rodá-lo:

```
ana@web:~$ sudo systemd-run -q --wait --pipe --uid=ana -p ProtectHome=tmpfs -p BindReadOnlyPaths=/home/ana/relatorio.sh -p ProtectSystem=strict -p PrivateNetwork=yes -p PrivateTmp=yes -p NoNewPrivileges=yes bash /home/ana/relatorio.sh
formatting the report...
ls: cannot access '/home/ana/.ssh': No such file or directory
/home/ana/relatorio.sh: line 5: /etc/relatorio-was-here: Read-only file system
could not write to /etc
could not reach 192.168.60.66
done
```

**Cada tentativa falhou, e cada falha tem um motivo diferente.** O diretório SSH não está lá, porque
o home que o programa vê é um vazio com um único arquivo dentro. O `/etc` recusou o arquivo novo como
sistema de arquivos somente leitura. E a conexão com o `trap` nunca saiu, porque não há rede por onde
sair. O script ainda assim rodou até o fim e imprimiu `done`, e esse é o ponto: uma sandbox não
precisa saber o que um programa é, só o que ele pode tocar.

## Paredes com uma fresta

Nenhuma dessas opções é uma promessa diante de um programa projetado para escapar. São namespaces e
filtros no mesmo kernel em que o resto da máquina roda, e uma falha nesse kernel é uma falha em todas
as paredes de uma vez. É por isso que a última seção da aula 8 pôs os sensores de EDR de verdade fora
dos contêineres, e por isso um arquivo que pode ter sido **feito** para escapar vai para uma máquina
virtual. Para um programa que só não é confiável, ou para um serviço que você roda e quer limitar,
essas paredes são a proteção mais barata da máquina.
