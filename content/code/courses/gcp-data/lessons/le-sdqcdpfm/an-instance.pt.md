---
title: Uma instância, e os caminhos até ela
version: 1
---

**Uma instância do Cloud SQL é um servidor de banco de dados: uma máquina do tamanho que você
escolhe, um disco do tamanho que você escolhe, um motor nela, e um ou mais endereços.** Ela vive numa
região, numa zona dessa região, e é alcançada por uma rede que você nomeia. Este é o comando que
criaria a da Quitanda, escrito por inteiro. **Ele não foi executado**: não há Cloud SQL neste notebook
para respondê-lo, e nada abaixo é a saída dele.

```sh
gcloud sql instances create quitanda-orders \
  --database-version=POSTGRES_16 --edition=enterprise \
  --cpu=2 --memory=8GiB \
  --region=southamerica-east1 --availability-type=zonal \
  --storage-type=SSD --storage-size=100 --storage-auto-increase \
  --no-assign-ip --network=projects/planner-dev/global/networks/default \
  --backup-start-time=06:00 --enable-point-in-time-recovery \
  --database-flags=log_min_duration_statement=500 \
  --deletion-protection
```

Cada flag é uma decisão que alguém toma num projeto de verdade:

| flag | o que ela decide |
|---|---|
| `--database-version=POSTGRES_16` | o motor e a versão principal; o Cloud SQL escolhe a menor |
| `--edition=enterprise` | a edição da seção anterior, nomeada em vez de deixada no padrão |
| `--cpu=2 --memory=8GiB` | a máquina, no Enterprise: 2 vCPU e 8 GiB |
| `--availability-type=zonal` | uma máquina numa zona; `regional` é o standby da aula 7 |
| `--storage-type=SSD --storage-size=100` | um disco SSD de 100 GiB |
| `--storage-auto-increase` | o disco cresce sozinho antes de encher, e nunca diminui |
| `--no-assign-ip --network=…` | sem endereço público; alcançável só a partir daquela rede VPC |
| `--backup-start-time=06:00` | o backup diário começa às 06:00 **UTC**, 03:00 em São Paulo |
| `--enable-point-in-time-recovery` | guardar o log de transações também, de onde a aula 7 restaura |
| `--database-flags=…` | as configurações do motor, o assunto da próxima seção |
| `--deletion-protection` | `gcloud sql instances delete` é recusado até isso ser desligado |

**A hora do backup é em UTC**, e a referência da linha de comando diz isso com as palavras dela, "in
the UTC timezone". Um time que escreve `03:00` pensando na hora calma de São Paulo ganha um backup à
meia-noite, hora local, enquanto os últimos pedidos do dia ainda estão chegando.

**O disco cresce e nunca diminui.** O `--storage-auto-increase` vem ligado por padrão, e a referência
acrescenta um aviso ao lado: um pico de uso pode deixar a instância com armazenamento maior, e cobrado,
para sempre. Diminuir o tamanho significa mover os dados para uma instância nova. O
`--storage-auto-increase-limit` põe um teto nisso, e vale defini-lo no dia em que a instância é
criada.

**Nenhuma senha entrou no comando.** O `--root-password` existe, e põe a senha no histórico do shell,
na lista de processos enquanto o comando roda, e em qualquer script para onde o comando for copiado.
No PostgreSQL, a instância é criada com um usuário chamado `postgres` e nenhuma senha digitada por
você, e a senha é definida depois com a linha de comando pedindo por ela:

```sh
gcloud sql users set-password postgres --instance=quitanda-orders --prompt-for-password
```

O `--prompt-for-password` a lê com o eco desligado. Melhor ainda para a aplicação é nenhuma senha: o
Cloud SQL pode autenticar uma conta de serviço pelo IAM, que a aula 8 de `gcp-foundations` configura,
com a flag `cloudsql.iam_authentication` ligada.

## Três caminhos para dentro

**Uma instância criada com `--no-assign-ip` tem um endereço privado e mais nada**, e esse é o arranjo
que o Google recomenda para qualquer coisa em produção. O endereço fica numa faixa da sua rede VPC que
você empresta para a rede de serviços do Google, uma vez por rede, o que a documentação do Google chama
de **private services access**: uma faixa reservada com `gcloud compute addresses create` e um peering
feito com `gcloud services vpc-peerings connect`, ambos da rede das aulas 15 e 18 de
`gcp-foundations`. Uma máquina virtual nessa rede alcança então a instância pelo endereço privado e
pela porta 5432, e nada na internet alcança, porque nenhuma rota chega até ela.

**O Cloud SQL Auth Proxy é o segundo caminho, e é o que a maioria das aplicações usa.** É um programa
pequeno que roda ao lado da aplicação, escuta em `127.0.0.1:5432`, e encaminha cada conexão para a
instância por TLS, autorizando-a com a identidade IAM de quem o roda. A aplicação se conecta em
`localhost` e não sabe nada de certificados; a instância é identificada pelo **nome de conexão**,
`planner-dev:southamerica-east1:quitanda-orders`, projeto, região e instância:

```sh
./cloud-sql-proxy --private-ip planner-dev:southamerica-east1:quitanda-orders
```

Isso também não foi executado, pelo mesmo motivo do primeiro comando. No notebook de um desenvolvedor
com o papel certo, a mesma linha sem `--private-ip` alcança uma instância que tem endereço público, e
esse é o terceiro caminho: um **IP público**, que recusa tudo menos as redes listadas nas redes
autorizadas da instância, ou é alcançado só pelo proxy. Um endereço público com `0.0.0.0/0` nas redes
autorizadas é o equivalente, em banco de dados, ao bucket vazado da aula 4, e acontece pelo mesmo
motivo, alguém fazendo uma conexão funcionar numa sexta-feira.

**O que uma conexão custa é a rede da aula 5.** Tráfego de uma máquina na mesma zona é de graça; de
outra zona da região custa 0,01 o GiB, como tráfego entre máquinas; de outra região, é o preço entre
regiões. Uma aplicação em `southamerica-east1-a` lendo um banco em `southamerica-east1-b` paga por cada
resultado que puxa de lá.
