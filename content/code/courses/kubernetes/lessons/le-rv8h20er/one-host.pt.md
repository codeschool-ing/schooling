---
title: Uma máquina, um arquivo
version: 1
---

**Uma ideia comum sobre este curso é que o Kubernetes substitui o Docker, como se o Compose fosse
um brinquedo.** Não é. Para uma aplicação que vive numa máquina só, o Compose faz o trabalho bem, e
esta lição começa vendo isso acontecer. O que o Kubernetes acrescenta só faz sentido depois que você
viu onde uma máquina termina.

A loja da Ana é um serviço só: a imagem `shop:1.0` da seção anterior. A descrição inteira de como
ela roda cabe em seis linhas, em `~/shop/compose.yaml`:

```yaml
services:
  web:
    image: shop:1.0
    ports:
      - "8080:8080"
    restart: always
```

`image` diz o que roda, `ports` publica a porta 8080 do container na porta 8080 do laptop, e
`restart: always` manda o daemon do Docker iniciar o container de novo sempre que ele parar. Um
comando sobe tudo:

```
ana@laptop:~/shop$ docker compose up -d
 Network shop_default Creating 
 Network shop_default Creating 
 Network shop_default Created 
 Network shop_default Created 
 Container shop-web-1 Creating 
 Container shop-web-1 Created 
 Container shop-web-1 Starting 
 Container shop-web-1 Started 
ana@laptop:~/shop$ curl -s localhost:8080
shop 1.0 on 7f1b64994482
ana@laptop:~/shop$ docker compose ps --format "table {{.Name}}\t{{.Image}}\t{{.Status}}"
NAME         IMAGE      STATUS
shop-web-1   shop:1.0   Up 2 seconds
```

A resposta traz o hostname do container, `7f1b64994482`, que é o começo do id dele. Isso vai
importar daqui a pouco, porque ele muda quando o container é substituído.

## Uma falha é tratada

A primeira preocupação de quem opera é um processo que morre. Aqui ele é morto do jeito duro, com
`SIGKILL`, que nenhum programa consegue capturar nem tratar:

```
ana@laptop:~/shop$ sudo kill -9 $(docker inspect -f "{{.State.Pid}}" shop-web-1)
ana@laptop:~/shop$ docker inspect -f "{{.RestartCount}} restart(s), running: {{.State.Running}}" shop-web-1
1 restart(s), running: true
```

**A política de reinício trouxe o container de volta, e ninguém precisou perceber.** O daemon viu o
processo sair, leu `restart: always` e iniciou o container outra vez. Isso é supervisão, e numa
máquina só é quase tudo o que você quer: o mesmo que o `systemd` faz por um serviço, aplicado a um
container.

## Uma segunda cópia é recusada

A segunda preocupação é a carga. Um processo numa porta atende tantas requisições quanto um
processo consegue, então o passo óbvio é rodar três:

```
ana@laptop:~/shop$ docker compose up -d --scale web=3
 Container shop-web-1 Running 
 Container shop-web-3 Creating 
 Container shop-web-2 Creating 
 Container shop-web-3 Created 
 Container shop-web-2 Created 
 Container shop-web-3 Starting 
Error response from daemon: failed to set up container networking: driver failed programming external connectivity on endpoint shop-web-3 (500b23a17f0fc16b32dec5866dae4c752bce1634a13b1c62102aec76ac39cf59): Bind for 0.0.0.0:8080 failed: port is already allocated
```

**Dois containers não podem ser donos da porta 8080 da mesma máquina.** A primeira cópia está com
ela, a terceira pediu e foi recusada, e o Compose parou ali com uma réplica rodando e duas criadas e
paradas. Numa máquina só, a saída é não publicar porta nenhuma nas cópias e pôr um proxy na frente
delas, que é um segundo serviço que você agora configura, monitora e mantém em sintonia com o
primeiro à mão.

## E a máquina é o limite

Nada disso sobrevive ao próprio laptop desaparecer. A política de reinício é uma regra guardada pelo
daemon do Docker **naquela máquina**; se a máquina perde a energia, o daemon, a política e os
containers vão juntos, e nada em lugar nenhum sabe que uma loja deveria estar rodando. Nenhuma
captura mostra isso aqui, porque não há uma segunda máquina de onde assistir. Essa segunda máquina
que falta é o assunto do resto do curso.
