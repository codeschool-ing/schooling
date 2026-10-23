---
title: Seu laboratório, e três jeitos de ter um
version: 1
---

**Tudo nesta aula roda numa máquina que você mesmo prepara; a plataforma não roda nada por você.**
As transcrições abaixo foram gravadas numa máquina Linux com as mesmas ferramentas e versões que esta
seção manda instalar, por um usuário chamado `ana` numa máquina chamada `vm`. O seu prompt vai
mostrar os seus próprios nomes, e os tempos e as datas na saída vão ser outros; todo o resto deve
bater.

## Do que as três ferramentas precisam

| ferramenta | roda sobre | versão usada aqui |
| --- | --- | --- |
| **O renderizador de linha de comando do Mermaid**, `mmdc` | Node.js, mais um navegador headless que ele baixa na instalação | `@mermaid-js/mermaid-cli` 11.17.0 no Node.js 22 |
| **PlantUML** | Java, como um único arquivo `.jar` | PlantUML 1.2026.9 no Java 21 |
| **Structurizr** | uma imagem de contêiner (ou Java, como um único arquivo `.war`) | `structurizr/structurizr:2026.09.19` no Docker |

O Docker só é necessário para a seção do Structurizr. Se você pular essa seção, Node.js e Java
bastam.

## Três caminhos

| | o que é | quanto custa ao seu computador |
| --- | --- | --- |
| **instalado** (recomendado) | Node.js 22 LTS, um runtime Java 21 e, para o Structurizr, o Docker, no computador que você já usa | cerca de 700 MB de disco para o navegador que o `mmdc` baixa, 30 MB para o PlantUML, cerca de 730 MB para a imagem do Structurizr; memória não é problema |
| **uma máquina virtual** | uma VM com Ubuntu 24.04, feita por exemplo com Multipass, com as mesmas três instaladas dentro | o mesmo disco dentro da VM, mais a própria VM: 2 processadores, 4 GB de memória e 20 GB de disco ficam confortáveis |
| **online** | os editores dos próprios projetos no navegador: o Mermaid Live Editor, o servidor online do PlantUML, as ferramentas online do Structurizr | nada no seu computador, e **tudo o que você digita vai para o servidor de outra pessoa** |

**O caminho instalado é o recomendado** porque as ferramentas são pequenas, são o que o pipeline de
uma equipe vai rodar, e os arquivos dos diagramas ficam no seu disco. A máquina virtual é a escolha
certa se você prefere manter o seu computador limpo, ou se ele roda um sistema operacional em que
alguma das ferramentas dá trabalho. Os editores online aparecem aqui para você saber que existem;
não foram verificados para este curso, podem mudar os termos quando os donos quiserem, e **um
diagrama de arquitetura do sistema de uma empresa real não deve ser digitado no site de outra
pessoa** sem o acordo dessa empresa.

## Instalando

- **Node.js 22 LTS**: em nodejs.org, o instalador para o seu sistema, ou por um gerenciador de
  versões. No Ubuntu 24.04 o pacote `nodejs` é de uma versão mais antiga; use os pacotes da
  NodeSource ou os binários oficiais.
- **Java 21**: uma build gratuita como a Eclipse Temurin, em adoptium.net. No Ubuntu 24.04,
  `sudo apt install openjdk-21-jre-headless` instala uma. **Esse comando não foi rodado para este
  curso**; a máquina da gravação já tinha o Java 21.
- **Docker**: Docker Desktop no Windows ou no macOS, Docker Engine no Linux, seguindo as instruções
  do próprio Docker. O seu usuário precisa de permissão para rodar `docker` sem `sudo`.

Depois crie uma pasta para esta aula e confira as versões. Estas foram gravadas:

```
ana@vm:~$ mkdir diagrams
ana@vm:~/diagrams$ node --version
v22.22.0
ana@vm:~/diagrams$ java -version
openjdk version "21.0.12.1" 2026-08-18
OpenJDK Runtime Environment (build 21.0.12.1+1-1-24.04.4-Ubuntu)
OpenJDK 64-Bit Server VM (build 21.0.12.1+1-1-24.04.4-Ubuntu, mixed mode, sharing)
ana@vm:~/diagrams$ docker --version
Docker version 29.9.1, build dfc520d
```

As suas versões podem ser mais novas dentro da mesma versão maior, e tudo bem. Mais antigas podem
não servir: um Node.js mais antigo pode não conseguir instalar o `mmdc`, e o PlantUML só foi testado
aqui no Java 21.

**Todos os comandos do resto da aula rodam nessa pasta `diagrams`.**
