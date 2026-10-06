---
title: Um container sem Docker
version: 1
---

**A especificação de runtime precisa de duas coisas para iniciar um container: um diretório para
usar como sistema de arquivos raiz e um `config.json` que descreva o processo.** Juntos, eles se
chamam **bundle**. O Docker monta um para cada container que inicia e o entrega ao runc. A Ana pode
montar um sozinha e deixar o Docker de fora da partida.

## O sistema de arquivos

O `docker export` grava os arquivos de um container como um arquivo tar; o `docker create` cria um
container sem iniciá-lo, só para ter o que exportar. A Ana desempacota o resultado em
`bundle/rootfs`:

```
ana@vm:~$ mkdir -p bundle/rootfs
ana@vm:~$ docker export $(docker create alpine:3.22) | tar -x -C bundle/rootfs
ana@vm:~$ ls bundle/rootfs
bin
dev
etc
home
lib
media
mnt
opt
proc
root
run
sbin
srv
sys
tmp
usr
var
```

Esse é o diretório raiz do Alpine, desempacotado da camada da etapa anterior. A parte do Docker
termina aqui.

## A configuração

O `runc spec` grava um `config.json` padrão. O `--rootless` o ajusta para um usuário comum, que é o
caso da Ana: não há `sudo` em nenhum ponto desta etapa.

```
ana@vm:~$ cd bundle && runc spec --rootless && ls
config.json
rootfs
ana@vm:~/bundle$ jq '{ociVersion, process: {terminal: .process.terminal, args: .process.args, cwd: .process.cwd}, root, hostname}' config.json
{
  "ociVersion": "1.3.0",
  "process": {
    "terminal": true,
    "args": [
      "sh"
    ],
    "cwd": "/"
  },
  "root": {
    "path": "rootfs",
    "readonly": true
  },
  "hostname": "runc"
}
```

A configuração responde às mesmas perguntas que a configuração da imagem da etapa anterior
respondia, nos termos do runtime: que processo rodar (`args`, aqui `sh`), em que diretório, com que
sistema de arquivos como raiz (`rootfs`, montado somente leitura), com que nome de máquina (`runc`).
E ela lista as paredes:

```
ana@vm:~/bundle$ jq -c '.linux.namespaces' config.json
[{"type":"pid"},{"type":"ipc"},{"type":"uts"},{"type":"mount"},{"type":"user"}]
```

**Cinco namespaces: processos, comunicação entre processos, nome de máquina, montagens e usuários.**
Cada linha é uma parede da aula 1, pedida pelo nome. Não há namespace de `network` no padrão
rootless, então este container compartilharia a rede da Ana. A aula 4 olha cada tipo.

## Rodando

O processo padrão é um shell interativo ligado a um terminal. A Ana o troca por um comando que
imprime três coisas e termina, desliga o terminal e roda o bundle:

```
ana@vm:~/bundle$ jq '.process.terminal = false | .process.args = ["sh", "-c", "hostname; cat /etc/alpine-release; ps"]' config.json > c.json && mv c.json config.json
ana@vm:~/bundle$ runc --root /tmp/runc-ana run demo
runc
3.22.6
PID   USER     TIME  COMMAND
    1 root      0:00 ps
ana@vm:~/bundle$ echo $?
0
```

**Um container, iniciado sem Docker nenhum envolvido.** Ele imprimiu o nome de máquina do
`config.json`, `runc`, e não o da máquina da Ana; a versão do Alpine, do próprio sistema de arquivos;
e uma lista de processos com exatamente uma entrada, o PID 1, porque ele tem o próprio namespace de
processos. O `ps` informa o usuário como `root`, embora a Ana o tenha iniciado como ela mesma: o
namespace de usuários mapeia a conta comum dela para root lá dentro, e do lado de fora continua
sendo só a Ana. A aula 21 volta a esse mapeamento, porque ele é uma das paredes mais fortes que
existem.

## O que o Docker acrescenta por cima

Se o runc consegue iniciar um container, para que serve o Docker? Para tudo em volta da partida:

| o Docker | o runc sozinho |
| --- | --- |
| baixa imagens de um registry e confere os digests delas | tem um diretório e mais nada |
| monta o sistema de arquivos raiz a partir de camadas, compartilhando-as entre containers | usa o diretório que receber |
| escreve o `config.json` a partir das opções do `docker run` | lê um `config.json` que outro escreveu |
| cria redes, publica portas, conecta volumes | inicia um processo em namespaces |
| guarda o registro dos containers, dos logs e dos estados deles | esquece o container quando ele termina |
| responde a uma API que outras ferramentas chamam | tem uma linha de comando |

**O runtime é a peça menor e aquela em que todo o resto se apoia.** Docker, containerd, Podman e
Kubernetes são todos, no fim, jeitos de escrever aquele `config.json`.
