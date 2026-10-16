---
title: Quando a montagem falha
version: 1
---

A montagem é onde a maioria das pessoas desiste de um curso como este, geralmente por causa de uma
linha de saída que parecia uma catástrofe e era uma coisa pequena. Estas são as falhas que aparecem
seguindo as duas últimas seções, cada uma com o que imprime e com o que resolve. **Todas foram
produzidas de propósito**, na máquina de onde vêm as transcrições.

## `permission denied while trying to connect to the docker API`

O primeiro comando `docker` depois de instalar, na mesma sessão que rodou o `usermod`:

```
ana@lab:~/tickets$ docker compose up -d
permission denied while trying to connect to the docker API at unix:///var/run/docker.sock
ana@lab:~/tickets$ groups
ana
```

O `groups` entrega: o usuário está no grupo `ana` e em mais nenhum, então o socket do Docker o
recusa. O `usermod -aG docker` mudou a conta, mas **uma sessão lê os seus grupos uma vez, quando
começa**. Saia e entre de novo, e o `groups` lista `docker`. Pôr `sudo` na frente de todo comando
também funciona, e deixa em `~/tickets` arquivos que pertencem ao root, o que vira um segundo
problema depois; a solução é o grupo.

## `address already in use`

Outra coisa na máquina já está escutando na porta 8080:

```
ana@lab:~/tickets$ docker compose up -d
 Network tickets_default Creating 
 Network tickets_default Creating 
 Network tickets_default Created 
 Network tickets_default Created 
Error response from daemon: failed to set up container networking: driver failed programming external connectivity on endpoint tickets-lb-1 (a7d4bc98cd3ba8a8a46466e58c0ef0d0a0e05b6bd344cc153b4148c7428dbd7c): failed to bind host port 127.0.0.1:8080/tcp: address already in use
ana@lab:~/tickets$ sudo ss -ltnp "sport = :8080"
State  Recv-Q Send-Q Local Address:Port Peer Address:PortProcess
LISTEN 0      5          127.0.0.1:8080      0.0.0.0:*    users:(("python3",pid=25519,fd=3))
```

O Docker criou a rede e depois não conseguiu publicar a porta do balanceador. `ss -ltnp` com um
filtro na porta nomeia o programa que a ocupa, aqui um processo Python com o seu pid. Pare esse
programa, ou troque o lado esquerdo de `"127.0.0.1:8080:80"` no `compose.yaml` por uma porta livre
e use essa porta onde o curso disser 8080. Uma bilheteria esquecida rodando de uma aula anterior,
em outro diretório, é a culpada de sempre, e o `docker ps` a lista.

## `did not find expected key`

O YAML lê a estrutura pela indentação, e uma linha do `compose.yaml` tem três espaços onde deveria
ter quatro:

```
ana@lab:~/tickets$ docker compose up -d
go-yaml load error in parser (while parsing a block mapping) at L3.C3-L20.C4: did not find expected key
```

O erro aponta para um intervalo, `L3.C3-L20.C4`, o bloco de linhas que não pôde ser lido como um
mapeamento, e não para a linha culpada. Dentro desse intervalo, procure a linha que não se alinha
com as vizinhas. Copiar o arquivo de novo com o botão do bloco é mais rápido do que caçar.

## Um `502 Bad Gateway` do nginx

Tudo subiu, e a bilheteria responde com a página de erro do nginx:

```
ana@lab:~/tickets$ curl -s localhost:8080/events/1; echo
<html>
<head><title>502 Bad Gateway</title></head>
<body>
<center><h1>502 Bad Gateway</h1></center>
<hr><center>nginx/1.27.5</center>
</body>
</html>

ana@lab:~/tickets$ docker compose logs app --no-log-prefix | tail -4
    DSN = os.environ["DATABASE_URL"]
          ~~~~~~~~~~^^^^^^^^^^^^^^^^
  File "<frozen os>", line 714, in __getitem__
KeyError: 'DATABASE_URL'
```

**502 é o nginx dizendo que a coisa atrás dele não respondeu**, então o problema nunca está no
próprio nginx. `docker compose logs app` mostra o que a bilheteria imprimiu antes de parar: um
`KeyError` para `DATABASE_URL`, porque a variável no `compose.yaml` foi escrita errado, como
`DATABASE_ULR`, e o programa não achou nada com o nome que pediu. Corrija o nome e rode
`docker compose up -d` de novo; o Compose recria os contêineres cuja configuração mudou.

O mesmo 502 aparece por alguns segundos depois de um reinício, enquanto a bilheteria sobe, e some
sozinho. Um que fica é um log para ler.

## Uma construção que não alcança o PyPI

`docker compose up --build` roda `pip install` dentro da imagem, e isso precisa alcançar pypi.org.
Numa rede que bloqueia ou intercepta esse acesso, a de uma escola ou de uma empresa, a construção
para no passo `[4/5]` com um erro que nomeia o endereço que não alcançou ou um certificado em que
não confiou. Não há conserto dentro do curso para uma rede que você não controla: construa uma vez
numa rede que funcione, e a imagem fica na máquina; as aulas seguintes só reconstroem quando
`app.py` ou `requirements.txt` mudam.

## Números muito diferentes dos impressos

O seu teste de carga vende 60 ingressos por segundo onde a aula imprimiu uns 120, ou 300 onde ela
imprimiu 140. **Isso não é uma falha.** Os números são uma propriedade da máquina, e a sua é outra
máquina. O que as aulas usam como argumento é a **forma**: como o número muda quando se acrescenta
um processador ou uma cópia. Se a forma bate, a aula funciona. Se não bate, `docker stats` num
segundo terminal enquanto o teste roda mostra qual contêiner está ocupado, que é a primeira
pergunta da seção 06.
