---
title: Uma defesa e uma falha, a uma chamada de distância
version: 1
---

**Esta seção mostra a anterior no seu laboratório: uma conta em que você nunca mexeu já tem uma rede dentro, um
bucket privado vira público com uma requisição, e a requisição que desfaz isso é do mesmo tamanho.**
Inicie o moto no primeiro terminal, vazio, e leia o `env.sh` nos dois.

## O que uma conta vazia já tem

Pergunte à conta que redes ela tem antes de você criar qualquer coisa:

```
ana@laptop:~/aws$ aws ec2 describe-vpcs --query "Vpcs[].[VpcId,CidrBlock,IsDefault]" --output text
vpc-fcbbbe17385be3d51	172.31.0.0/16	True
ana@laptop:~/aws$ aws ec2 describe-security-groups --query "SecurityGroups[].[GroupId,GroupName]" --output text
sg-d591b6e6e30335630	default
ana@laptop:~/aws$ aws ec2 describe-regions --query "length(Regions)"
38
ana@laptop:~/aws$ for r in $(aws ec2 describe-regions --query "Regions[].RegionName" --output text); do aws ec2 describe-vpcs --region "$r" --query "Vpcs[?IsDefault].VpcId" --output text; done | wc -l
38
```

**Uma rede padrão por região, e ninguém pediu nenhuma delas.** A AWS faz o mesmo: uma conta ganha uma
*VPC padrão* em cada região que tem habilitada, com uma sub-rede em cada zona de disponibilidade, uma
rota para a internet e um security group, para que uma primeira máquina funcione sem nenhuma decisão
de rede. O moto responde com uma em cada uma das suas 38 regiões. Cada uma é um lugar onde um recurso
pode ser lançado, e um inventário que só lê `sa-east-1` enxerga uma delas. A aula 8 decide o que
fazer com elas; por ora, repare que **a pergunta foi um laço, e on-premises teria sido uma semana com
uma prancheta**.

## Um bucket privado

Pare o moto com Ctrl+C no primeiro terminal e inicie de novo, para que o que ele imprimir daqui em
diante seja só esta parte, e as redes padrão vão embora com o resto.

O sistema de agendamento da clínica exporta as consultas do dia para um bucket. Crie o bucket, e um
arquivo pequeno que faz o papel da exportação:

```sh
cat > appointments.csv <<'EOF'
date,time,patient,doctor
2026-10-23,09:00,Maria Souza,Dr. Lima
2026-10-23,09:30,João Pereira,Dr. Lima
EOF
```

```
ana@laptop:~/aws$ aws s3api create-bucket --bucket clinic-exports --create-bucket-configuration LocationConstraint=sa-east-1 --query Location --output text
/clinic-exports
ana@laptop:~/aws$ aws s3 cp --no-progress appointments.csv s3://clinic-exports/2026-10-23.csv
upload: ./appointments.csv to s3://clinic-exports/2026-10-23.csv
```

Agora peça esse objeto **do jeito que um estranho pediria**: com o `curl`, que não manda credencial
nenhuma.

```
ana@laptop:~/aws$ curl -s -o /dev/null -w "%{http_code}\n" http://localhost:4567/clinic-exports/2026-10-23.csv
403
```

`403` é *proibido*. Uma requisição sem identidade por trás é recusada, que é o padrão de todo bucket
novo e o padrão certo.

## Uma requisição depois

O caio quer que o tablet da recepção leia a exportação sem ninguém digitar senha, e alguém sugere o
jeito mais rápido. É uma política de bucket que permite `s3:GetObject` a `"Principal": "*"`, o que
quer dizer **todo mundo**, autenticado ou não:

```
ana@laptop:~/aws$ aws s3api put-bucket-policy --bucket clinic-exports --policy '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":"*","Action":"s3:GetObject","Resource":"arn:aws:s3:::clinic-exports/*"}]}'
ana@laptop:~/aws$ curl -s -w "%{http_code}\n" http://localhost:4567/clinic-exports/2026-10-23.csv
date,time,patient,doctor
2026-10-23,09:00,Maria Souza,Dr. Lima
2026-10-23,09:30,João Pereira,Dr. Lima
200
```

**Os nomes de dois pacientes e o médico deles, servidos a uma requisição que não provou nada sobre
quem a enviou.** Na AWS esse endereço seria um nome na internet em vez de `localhost`, e o resultado
seria o mesmo para qualquer um que o encontrasse. O comando que fez isso não imprimiu nada. Nenhum
aviso, nenhuma confirmação, nenhuma segunda pessoa: a API fez o que uma chave válida pediu.

Contra uma conta real criada este ano, esse `put-bucket-policy` teria sido recusado, porque a AWS
hoje liga uma proteção chamada **Block Public Access** em todo bucket novo, e a aula 9 mostra por que
foi preciso uma década de incidentes para chegar lá. O moto guarda essa proteção e não aplica nada
dela, e é isso que deixa este laboratório mostrar a falha que a proteção existe para impedir.

O primeiro terminal registrou toda requisição desde que o moto iniciou:

```
ana@laptop:~/aws$ moto_server -p 4567
WARNING: This is a development server. Do not use it in a production deployment. Use a production WSGI server instead.
 * Running on http://127.0.0.1:4567
Press CTRL+C to quit
127.0.0.1 - - [23/Oct/2026 00:30:46] "PUT /clinic-exports HTTP/1.1" 200 -
127.0.0.1 - - [23/Oct/2026 00:30:47] "PUT /clinic-exports/2026-10-23.csv HTTP/1.1" 200 -
127.0.0.1 - - [23/Oct/2026 00:30:47] "GET /clinic-exports/2026-10-23.csv HTTP/1.1" 403 -
127.0.0.1 - - [23/Oct/2026 00:30:48] "PUT /clinic-exports?policy HTTP/1.1" 200 -
127.0.0.1 - - [23/Oct/2026 00:30:48] "GET /clinic-exports/2026-10-23.csv HTTP/1.1" 200 -
```

Leia as duas linhas `GET`, que são as duas do `curl`. O mesmo objeto, o mesmo endereço, a minutos de
distância: recusado, depois servido. **Uma linha de log como a segunda é como a maioria das
exposições é descoberta**, normalmente muito depois do fato e normalmente por outra pessoa. A aula 15
trata de guardar a linha que diz quem mudou a política entre uma e outra.

## E uma requisição de volta

A correção é do mesmo tamanho que a falha:

```
ana@laptop:~/aws$ aws s3api delete-bucket-policy --bucket clinic-exports
ana@laptop:~/aws$ curl -s -o /dev/null -w "%{http_code}\n" http://localhost:4567/clinic-exports/2026-10-23.csv
403
```

**Prove uma correção do jeito que a falha foi achada**: perguntando de novo, como o estranho, e lendo
a resposta. "Eu tirei a política" é uma afirmação. Um `403` para uma requisição anônima é uma prova,
e é o hábito que todas as aulas seguintes pedem de você.
