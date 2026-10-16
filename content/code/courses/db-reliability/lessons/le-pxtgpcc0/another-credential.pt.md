---
title: Atrás de outra credencial
version: 1
---

A pergunta a fazer sobre cada cópia, depois de "que evento único a destrói junto com o banco", é:
**quais credenciais conseguem apagá-la, e onde essas credenciais ficam?** Neste laboratório a resposta
é desconfortável. O `postgres` no servidor do banco consegue apagar tudo nos dois repositórios, porque
escreve nos dois. Qualquer um que vire `postgres`, ou root, nesse servidor consegue remover todos os
backups antes de tocar no banco, e num ataque de ransomware é nessa ordem que as coisas acontecem.

Há três jeitos de pôr um backup atrás de uma credencial que o servidor do banco não tem.

## Puxar em vez de empurrar

No arranjo das lições 5 e 9, o servidor do banco **empurra** os seus backups e segmentos para o
repositório, então precisa de acesso de escrita, e com acesso de escrita normalmente vem o de apagar.
A alternativa é um **servidor de backup** separado que **puxa**: ele guarda o repositório nos seus
próprios discos, conecta no servidor do banco para ler dele, e o servidor do banco não tem nenhum jeito
de entrar no servidor de backup. O pgBackRest suporta exatamente isso, com o repositório num
"repository host" alcançado por SSH, e o Barman é construído em torno disso. Um servidor do banco
comprometido consegue então danificar o banco e mais nada.

## Escrever sem apagar

Quando o repositório é object storage, a credencial do servidor do banco pode ter permissão para
**escrever objetos novos e mais nada**: sem apagar, sem sobrescrever, sem mudar as configurações do
bucket. A retenção passa então a ser feita por uma regra de ciclo de vida no bucket, ou por uma rotina
separada com uma credencial separada, e um object lock faz até isso esperar a data de retenção.

## Outra conta, outras pessoas

A separação mais forte é administrativa. O repositório offsite fica em **outra conta**, de preferência
em outro provedor, cujos administradores não são os administradores do banco e cujas credenciais não
ficam guardadas em nenhuma máquina onde o banco roda, protegidas por um segundo fator. Perder a conta
de nuvem principal, para um atacante ou numa disputa de cobrança, deixa então os backups onde
estavam.

Nenhum desses foi digitado neste laboratório, que é uma máquina e um administrador. Eles estão listados
porque são a diferença entre "temos backups offsite" e "temos backups que a pessoa que invadiu o
servidor do banco não consegue apagar", e a lição 10 é sobre o dia em que essa diferença é a única que
importa.
