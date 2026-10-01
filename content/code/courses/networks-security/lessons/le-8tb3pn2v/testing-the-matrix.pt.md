---
title: Testando cada célula de onde ela começa
version: 1
---

Um conjunto de regras é uma afirmação sobre o que alcança o quê, e **uma afirmação se confere
tentando a partir de onde o tráfego começa**. Ler as regras prova o que elas dizem; só uma tentativa
de conexão prova o que elas fazem. Por isso o `probe` roda a partir de uma máquina em cada zona,
contra as células que deveriam estar abertas e as que não deveriam:

```
ana@remote:~$ probe www:443 www:80 dns:53 app:8080 db:5432 laptop:22
www:443                open
www:80                 open
dns:53                 blocked
app:8080               blocked
db:5432                blocked
laptop:22              blocked
```

A partir da internet, a loja responde nas duas portas e tudo lá dentro está `blocked`, não `refused`:
os pacotes nunca chegaram a nada que pudesse recusá-los. `dns:53` também está bloqueado, e isso é a
matriz funcionando: o `probe` tenta **TCP**, e a célula da internet permite só UDP. O servidor de
nomes continua respondendo à internet, pelo transporte que a regra permite:

```
ana@remote:~$ dig +short @192.0.2.53 www.example.com
192.0.2.80
ana@laptop:~$ dig +short @192.0.2.53 db.corp.example.com
192.168.20.30
```

Depois, a partir da LAN da equipe e do segmento de gestão:

```
ana@laptop:~$ probe www:443 app:8080 db:5432 app:22 remote:443
www:443                open
app:8080               open
db:5432                blocked
app:22                 blocked
remote:443             open
ana@admin:~$ probe app:22 db:22 www:22 app:8080 db:5432
app:22                 open
db:22                  open
www:22                 refused
app:8080               blocked
db:5432                blocked
```

O `laptop` navega e usa a aplicação e não alcança mais nada no segmento de servidores. O `admin`
alcança o SSH nos dois servidores e não consegue usar a aplicação nem o banco de dados, porque
administrar uma máquina e usar o serviço dela são células diferentes. `www:22` diz `refused` a partir
de `admin`: a regra deixou a conexão passar, e `www` simplesmente não roda servidor SSH.

**As linhas da internet, da equipe e da gestão foram testadas agora a partir das zonas onde
começam**, as células permitidas e uma amostra das negadas; a próxima seção testa a linha da DMZ a
partir do `www`. Guarde esse teste. Depois de qualquer mudança nas regras, rode-o de novo: uma
regra adicionada às pressas para consertar uma coisa é o jeito comum de outra célula se abrir por
acidente, e a aula 18 reúne as formas clássicas de isso acontecer.
