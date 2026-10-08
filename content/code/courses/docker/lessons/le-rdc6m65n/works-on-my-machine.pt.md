---
title: Na minha máquina funciona
version: 2
---

**Um programa nunca roda sozinho.** Ele roda em cima de um compilador ou interpretador numa certa
versão, de um conjunto de bibliotecas, de um banco de dados em outra versão e de um punhado de
configurações. Cada máquina por onde ele passa tem o seu próprio conjunto dessas quatro coisas, e
os relatos de bug que começam com "na minha máquina funciona" são relatos sobre a diferença.

A Ana trabalha no `shelf`, o pequeno serviço que entrega por HTTP o catálogo de uma livraria. Ele é
escrito em Go, então compilá-lo exige o conjunto de ferramentas do Go, e guarda os livros no
PostgreSQL. O colega dela, Bruno, cuida de outro projeto da mesma equipe que ainda roda no
PostgreSQL 16. O servidor de homologação foi montado há um ano por alguém que já saiu da empresa.

Veja como isso dá errado, de forma concreta. O PostgreSQL 17 trouxe o `JSON_TABLE`, um jeito de
transformar um documento JSON em linhas. Uma consulta de relatório que o usa roda num notebook com
o 17 e falha com erro de sintaxe num servidor com o 16. Ninguém mexeu na consulta. A única coisa
diferente era a máquina.

## As respostas de sempre, e quanto cada uma custa

**Um README que lista versões** é a mais barata e a menos confiável. É um pedido, ninguém confere,
e fica velho na primeira vez que alguém atualiza uma coisa para um projeto.

**Instalar tudo no sistema** funciona até dois projetos discordarem. Debian e Ubuntu conseguem
manter o PostgreSQL 16 e o 17 lado a lado, em duas portas e com dois diretórios de dados, mas aí
cada ferramenta da máquina, do `psql` a um script de backup, precisa ser avisada de qual deles está
falando, e o arranjo muda de distribuição para distribuição e de notebook para notebook.

**Uma máquina virtual por projeto** resolve a briga, ao preço de um sistema operacional inteiro por
projeto: kernel próprio, boot próprio, gigabytes de disco e uma fatia fixa de memória reservada,
esteja a máquina ocupada ou não. A aula 2 põe as duas coisas lado a lado.

## O que um container muda

**Um container leva o programa junto com tudo de que ele precisa acima do kernel**: o compilador ou
interpretador, as bibliotecas, os arquivos de configuração, nas versões exatas que alguém escolheu.
A máquina embaixo só precisa de um motor de containers, e essa é a última coisa que alguém precisa
instalar à mão.

A máquina da Ana mostra isso. **As transcrições das aulas 1 a 4 estão aqui para serem lidas**: você
monta uma máquina como a dela na aula 5, e dali em diante todo comando pode ser digitado. Volte a
estas então, se quiser vê-las acontecer na sua. Não há Go nenhum na máquina dela:

```
ana@vm:~$ env go version
env: ‘go’: No such file or directory
```

E mesmo assim ela consegue rodar o compilador do Go, na versão de que o `shelf` precisa, sem
instalá-lo:

```
ana@vm:~$ docker run --rm golang:1.25 go version
go version go1.25.14 linux/amd64
```

O `docker run` iniciou um container a partir da imagem `golang:1.25`, rodou `go version` dentro dele
e removeu o container quando o comando terminou, que é o que o `--rm` pede. O compilador veio com a
imagem. Nada foi instalado na máquina da Ana, e nada ficou nela além da própria imagem, que fica
para a próxima vez.

O mesmo truque resolve a briga do Bruno. Duas versões principais do PostgreSQL, numa máquina só, uma
depois da outra, e nenhuma instalada:

```
ana@vm:~$ docker run --rm postgres:16 postgres --version
postgres (PostgreSQL) 16.15 (Debian 16.15-1.pgdg13+2)
ana@vm:~$ docker run --rm postgres:17 postgres --version
postgres (PostgreSQL) 17.11 (Debian 17.11-1.pgdg13+2)
```

Cada imagem traz o próprio binário `postgres` e as próprias bibliotecas. Elas também podem rodar ao
mesmo tempo, porque cada container ganha o próprio sistema de arquivos e a própria rede; a aula 9
roda um banco de verdade desse jeito.

**Uma observação honesta sobre estas transcrições.** O primeiro `docker run` de uma imagem numa
máquina faz o download dela, o que leva de segundos a minutos. O laboratório já tinha baixado
estas quatro imagens, então nenhum download aparece aqui. A aula 9 mostra um.

## O que ele não resolve

Um container leva tudo o que fica **acima** do kernel e nada do que fica abaixo. Três coisas,
portanto, ainda dependem da máquina, e cada uma tem a sua aula:

- **o kernel e o processador.** Todos os containers de uma máquina compartilham o kernel dela, então
  uma imagem construída para uma arquitetura de processador não roda em outra sem ajuda. A aula 2
  mostra o erro.
- **os dados.** Os arquivos de um container vão embora quando o container vai. A aula 7 mostra o
  que se perde, e a aula 8, onde os dados deveriam morar.
- **a configuração que de fato muda.** A senha do banco no notebook e em produção não deveria ser a
  mesma, então ela não pode ficar gravada na imagem. A aula 18 trata de passá-la quando o container
  inicia.
