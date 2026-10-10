---
title: O Metabase na sua máquina, e três jeitos de tê-lo
version: 1
---

O **Metabase** é uma ferramenta de business intelligence de código aberto: uma aplicação web que se
conecta a um banco, deixa as pessoas montarem perguntas escolhendo tabelas, colunas e agrupamentos
em menus, desenha as respostas como gráficos e organiza gráficos em painéis. É sobre ele que as
aulas 5, 6 e 9 constroem, e o motivo de estar neste curso é que ele é gratuito, roda na sua máquina,
e o que ele faz com uma camada semântica é o que toda ferramenta de BI faz com uma.

Ele roda dentro da mesma máquina virtual que o PostgreSQL, e você o abre no seu próprio navegador
pela porta encaminhada na aula 1.

## Com Docker, na máquina virtual — o caminho recomendado

O Metabase é distribuído como uma **imagem de contêiner**: o programa e tudo de que ele precisa,
empacotados para rodar do mesmo jeito em qualquer Linux com Docker. Instale o Docker pelos pacotes
do próprio Ubuntu:

```sh
sudo apt update
sudo apt install -y docker.io
```

(A máquina em que este curso foi gravado já tinha Docker, instalado pelos pacotes do próprio Docker,
então esse passo é o único comando desta aula que não foi gravado. Tudo daqui para baixo foi.)

Depois, suba o Metabase. A versão está escrita para que o que você vê bata com o curso:

```sh
sudo docker run -d --name metabase --network host --restart unless-stopped \
  -e JAVA_OPTS=-Xmx1g \
  -v metabase-data:/metabase-data -e MB_DB_FILE=/metabase-data/metabase.db \
  metabase/metabase:v0.64.1.5
```

O que cada parte faz:

| parte | por quê |
|---|---|
| `-d --name metabase` | rodar em segundo plano, com um nome que os outros comandos possam usar |
| `--network host` | compartilhar a rede da máquina, para que `localhost:5432` dentro do Metabase seja o seu PostgreSQL e a porta 3000 seja a da máquina |
| `--restart unless-stopped` | subir de novo quando a máquina reiniciar |
| `-e JAVA_OPTS=-Xmx1g` | limitar a memória que o Java do Metabase pode usar, para o PostgreSQL ter espaço |
| `-v metabase-data:/metabase-data` e `MB_DB_FILE` | guardar as configurações, usuários e perguntas do próprio Metabase num volume que sobrevive ao contêiner |

Na primeira vez, o Docker baixa a imagem antes de subir e mostra o progresso. Qual o tamanho dela, e
o que está rodando:

```
ana@vm:~$ sudo docker images metabase/metabase
IMAGE                         ID             DISK USAGE   CONTENT SIZE   EXTRA
metabase/metabase:v0.64.1.5   08b1ebc81765       1.92GB          828MB   U    
```

```
ana@vm:~$ sudo docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
NAMES      IMAGE                         STATUS
metabase   metabase/metabase:v0.64.1.5   Up 34 seconds
```

O Metabase demora para subir — cerca de meio minuto na máquina em que isto foi gravado, e mais numa
máquina virtual pequena. Ele responde quando está pronto:

```
ana@vm:~$ curl -s -w '\n' http://localhost:3000/api/health
{"status":"ok"}
```

**O que custa à sua máquina**, medido depois de estabilizar:

```
ana@vm:~$ sudo docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}"
NAME       MEM USAGE / LIMIT
metabase   1.412GiB / 15.72GiB
```

Cerca de 1,4 GB de memória com o limite no lugar, que é por que a aula 1 pediu uma máquina de 4 GB;
a imagem ocupa 1,92 GB de disco.

## O arquivo Java, sem Docker

O Metabase também é distribuído como um único arquivo Java, `metabase.jar`, no site dele, que roda
com `java -jar metabase.jar` numa máquina com um Java recente. Não precisa de Docker, e é a escolha
natural num computador onde o Docker não está disponível. A documentação dele diz que versão de Java
cada lançamento exige, e o curso não repete, porque isso muda de um lançamento para outro.

## Online: Metabase Cloud

O Metabase vende uma versão hospedada. Não custa nada à sua máquina, e exige conta, um plano pago
depois do período de teste, e um jeito de o serviço hospedado chegar ao seu banco — o que um banco
dentro da sua máquina virtual não oferece. O curso não depende dela.
