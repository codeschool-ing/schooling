---
title: Configurando o daemon, e quando o Engine basta
version: 2
---

**O `dockerd` lê a configuração de um arquivo JSON, `/etc/docker/daemon.json`, quando inicia.** Cada
ajuste ali é um padrão para a máquina inteira: de onde vêm as imagens, como os logs dos containers
são guardados, que endereços as redes recebem. O arquivo não existe até alguém escrevê-lo, e um motor
sem arquivo roda com os padrões embutidos.

O arquivo do laboratório tem um ajuste só, e ele é o motivo de o laboratório conseguir baixar imagens:

```
ana@vm:~$ cat /etc/docker/daemon.json
{
  "registry-mirrors": ["https://mirror.gcr.io"]
}
```

O **`registry-mirrors`** faz o daemon buscar as imagens do Docker Hub primeiro em outro servidor. Os
pulls anônimos do laboratório no Docker Hub eram respondidos com `429 Too Many Requests`, o limite de
requisições do Docker Hub, então o laboratório baixa pelo `mirror.gcr.io`, um cache público do Docker
Hub mantido pelo Google. Os nomes, as tags e os digests das imagens continuam sendo os do Docker Hub;
só o servidor que manda os bytes muda. Empresas usam o mesmo ajuste para apontar todas as máquinas
para um cache próprio. A sua máquina começa sem arquivo e não precisa de um; se o `429` da última
seção da aula 5 chegar até você, essas três linhas e um restart são o caminho para contorná-lo.

Uma mudança no arquivo vale quando o daemon reinicia, `sudo systemctl restart docker` numa máquina com
systemd, e um arquivo com erro de JSON impede o daemon de iniciar. É o jeito mais comum de quebrar uma
instalação que funcionava, então confira o arquivo com `jq . /etc/docker/daemon.json` antes de
reiniciar.

## O que o daemon informa sobre si mesmo

```
ana@vm:~$ docker info | grep -E "^ (Server Version|Storage Driver|Logging Driver|Cgroup Driver|Cgroup Version|Docker Root Dir):"
WARNING: Support for cgroup v1 is deprecated and planned to be removed by no later than May 2029 (https://github.com/moby/moby/issues/51111)
 Server Version: 29.8.2
 Storage Driver: overlayfs
 Logging Driver: json-file
 Cgroup Driver: cgroupfs
 Cgroup Version: 1
 Docker Root Dir: /var/lib/docker
ana@vm:~$ docker info --format "{{.RegistryConfig.Mirrors}}"
[https://mirror.gcr.io/]
```

Cada linha é uma decisão que alguém pode mudar, e cada uma tem a sua aula:

- **`Storage Driver: overlayfs`** é como as camadas das imagens e as camadas de escrita dos
  containers são guardadas, o empilhamento que a aula 4 desmontou.
- **`Logging Driver: json-file`** quer dizer que a saída de cada container é guardada como um arquivo
  de linhas JSON nesta máquina, que é o que o `docker logs` lê. Por padrão esses arquivos crescem sem
  limite, e a aula 18 define um.
- **`Cgroup Driver` e `Cgroup Version`** são os limites da aula 4. O `WARNING` acima deles é o daemon
  avisando que o suporte ao cgroup v1, que a máquina do laboratório usa, está obsoleto; uma
  distribuição atual usa o v2 e não imprime aviso nenhum.
- **`Docker Root Dir: /var/lib/docker`** é onde tudo isso mora no disco.

```
ana@vm:~$ sudo du -sh /var/lib/docker
24M	/var/lib/docker
```

24M, porque o laboratório só tem a `alpine:3.22` baixada. Numa máquina que constrói imagens há alguns
meses, esse diretório costuma ter dezenas de gigabytes, e a aula 22 mostra como ver o que ocupa o
espaço e recuperá-lo com segurança. Nunca apague arquivos lá dentro à mão: os registros do daemon e os
arquivos passariam a discordar, e ele deixaria de iniciar com confiabilidade.

## Quando o Docker Engine é tudo de que você precisa

**O Docker Engine sozinho é tudo de que uma máquina Linux precisa para construir e rodar containers.**
O Docker Desktop acrescenta uma VM, de que o Linux não precisa, e uma janela gráfica, que um servidor
nunca usa.

| a máquina | o que instalar |
| --- | --- |
| um servidor Linux que roda containers | Docker Engine, ou só o containerd se um orquestrador o gerencia (aula 28) |
| um runner de CI que constrói imagens | Docker Engine, e o BuildKit vem junto |
| um notebook Linux | Docker Engine, mais o grupo ou o modo rootless da etapa anterior |
| um notebook Windows ou macOS | Docker Desktop, ou uma alternativa que também rode uma VM Linux (aula 28) |

O resto deste curso roda exatamente assim: uma máquina Linux, um Docker Engine, mais nada.
