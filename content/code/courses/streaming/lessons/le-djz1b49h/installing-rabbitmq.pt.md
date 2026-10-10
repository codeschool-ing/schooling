---
title: Instalando o RabbitMQ, e um emulador de SQS e SNS
version: 1
---

**O RabbitMQ está no arquivo do Ubuntu, e o runtime Erlang em que ele é escrito também.** O Ubuntu
24.04 tem o RabbitMQ 3.12; a equipe do RabbitMQ publica versões mais novas nos próprios
repositórios, e tudo o que esta lição faz funciona igual nelas. Instale-o, e o cliente Python dele:

@@fence@@

Numa máquina virtual, a instalação já sobe o servidor sob o systemd, como um serviço que também
sobe a cada boot, escutando clientes na porta 5672. **Essa subida não aconteceu na máquina em que
este curso foi gravado**, que não tem systemd; lá o servidor foi iniciado à mão com
`sudo rabbitmq-server -detached`, que faz o mesmo trabalho sem gerenciador de serviços. Na sua,
confira que ele está no ar:

@@fence@@

`rabbitmqctl` e `rabbitmq-diagnostics` falam com o servidor como administrador, e é por isso que
precisam de `sudo`: eles se recusam a rodar como usuário comum. O **pika** é o cliente que os seus
programas usam, e ele conecta como o usuário embutido do RabbitMQ, `guest`, cuja senha é `guest` e
que só tem permissão para conectar a partir do `localhost`. Essa restrição é toda a segurança dele,
e basta para um servidor que escuta numa máquina que ninguém mais usa. Um servidor que outras
pessoas alcançam ganha usuários próprios e apaga o `guest`, como diz a própria lista de verificação
de produção do RabbitMQ.

## SQS e SNS, sem conta na AWS

Amazon SQS e SNS são serviços: não há nada para instalar, e usá-los exige uma conta na AWS e uma
fatura. Este curso os roda pelo **moto**, uma biblioteca Python que imita as APIs da AWS, rodando
como um servidor local. Ele é um **emulador, não a AWS**: responde às mesmas requisições com os
mesmos formatos e implementa o comportamento que esta lição examina, mas tempos, limites e preços
são da Amazon, e nada medido contra o moto diz algo sobre eles. O `boto3` é o cliente Python da
própria AWS, o mesmo que você usaria contra o serviço de verdade:

@@fence@@

O extra `[server]` traz o servidor web que deixa o moto rodar como um processo separado, e ele
puxa várias dezenas de pacotes junto; todos ficam dentro do `~/venv`. Nada foi iniciado ainda. A
seção de SQS, mais adiante nesta lição, o sobe no segundo shell.
