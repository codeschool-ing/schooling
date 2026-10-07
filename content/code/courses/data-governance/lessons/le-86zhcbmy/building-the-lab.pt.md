---
title: Montando a máquina
version: 1
---

Estes são os comandos, em ordem. Rode-os na máquina Ubuntu 24.04 recém-criada da seção anterior,
como um usuário que pode usar `sudo`.

**1. Os pacotes.** O PostgreSQL 16 com a extensão `pgaudit`, o OpenSSL para os certificados da aula
3, o `cryptsetup` para o volume cifrado dela, o Python para o gerador de dados e os pequenos
programas que as aulas seguintes escrevem, e o `curl` para o download da aula 4:

```sh
sudo apt-get update
sudo apt-get install -y postgresql-16 postgresql-16-pgaudit openssl cryptsetup python3 curl
```

Instalar o PostgreSQL cria um cluster chamado `main` na porta 5432. O laboratório não mexe nele e
monta o seu ao lado, para nada que você faça neste curso tocar num banco que você já tinha.

**2. A Ana.** Toda transcrição é digitada pela Ana, engenheira de dados da Ipê, num diretório
chamado `gov`. Ela é administradora desta máquina, como você é da sua:

```sh
sudo useradd -m -s /bin/bash ana
echo 'ana ALL=(ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/ana
sudo chmod 0440 /etc/sudoers.d/ana
sudo -iu ana
mkdir ~/gov && cd ~/gov
```

Daqui em diante você é a Ana, e todo comando do curso roda em `~/gov`.

**3. O cluster.** O `pg_createcluster` do Ubuntu cria um cluster com os arquivos onde o Ubuntu os
põe, `/etc/postgresql/16/gov` e `/var/lib/postgresql/16/gov`. Três configurações são acrescentadas:
o fuso horário em que a Ipê trabalha, duas vezes, para os horários aparecerem como nas transcrições,
e a biblioteca `pgaudit`. O segundo comando abre um editor; acrescente as quatro linhas no fim do
arquivo, salve e saia:

```sh
sudo pg_createcluster 16 gov --port 5433 --locale C.UTF-8
sudo nano /etc/postgresql/16/gov/postgresql.conf
```

```ini
# --- the lab ---
timezone = 'America/Sao_Paulo'
log_timezone = 'America/Sao_Paulo'
shared_preload_libraries = 'pgaudit'
```

```sh
sudo pg_ctlcluster 16 gov start
```

**4. Dizendo ao `psql` aonde ir.** O `psql` do Ubuntu pergunta a um pequeno wrapper com que cluster
falar. Esta linha diz `gov` e o banco `ipe`, para todo usuário:

```sh
echo '* * 16 gov ipe' | sudo tee /etc/postgresql-common/user_clusters
```

Uma conexão por nome de host não pergunta ao wrapper, então a porta tem de estar também no ambiente
da Ana, junto com o banco e o fuso horário:

```sh
echo 'export PGPORT=5433 PGDATABASE=ipe TZ=America/Sao_Paulo' >> ~/.bashrc
source ~/.bashrc
```

**5. Dois nomes para a máquina.** A aula 3 confere um certificado contra um nome, e não contra um
endereço, então o laboratório aponta dois nomes para a própria máquina:

```sh
echo '127.0.0.1 db.ipe.example bao.ipe.example' | sudo tee -a /etc/hosts
```

Essa é a máquina. Perguntada sobre o que tem, ela responde:

```
ana@lab:~/gov$ psql --version
psql (PostgreSQL) 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)
ana@lab:~/gov$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
16  gov     5433 online postgres /var/lib/postgresql/16/gov  /var/log/postgresql/postgresql-16-gov.log
16  main    5432 down   postgres /var/lib/postgresql/16/main /var/log/postgresql/postgresql-16-main.log
```

O `gov` está no ar na 5433. Na máquina em que estas transcrições foram gravadas, o `main` estava
parado; na sua ele provavelmente está no ar, e tanto faz. O banco `ipe` ainda não existe. A próxima
seção o cria e o preenche.
