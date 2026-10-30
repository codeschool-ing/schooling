---
title: Quando o laboratório não responde
version: 1
---

Estas são as falhas que apareceram enquanto esta lição era gravada, na ordem em que um aluno as
encontra, com o que cada uma diz e o que quer dizer. Quase todas são uma linha esquecida.

**O `az` não é encontrado.** Um terminal novo começa sem `~/.local/bin` no path:

```
ana@laptop:~/azure$ PATH=/usr/bin:/bin; az version
bash: line 1: az: command not found
```

A segunda linha de "Toda vez que abrir um terminal" o põe de volta, e o `terraform` some do mesmo
jeito.

**Sem connection string.** O terminal tem o path e não tem a terceira linha, então a linha de comando
não sabe com qual armazenamento falar e para antes de mandar qualquer coisa:

```
ana@laptop:~/azure$ env -u AZURE_STORAGE_CONNECTION_STRING az storage container list -o table 2>&1 | tail -3
ERROR: Please provide storage account name or connection string.
```

**O Azurite não está rodando.** A variável está definida e nada escuta na porta, porque o computador
foi reiniciado ou os contêineres foram parados:

```
ana@laptop:~/azure$ docker compose stop azurite 2>&1 | tail -1
 Container azure-azurite-1 Stopped 
ana@laptop:~/azure$ az storage container list -o table 2>&1 | tail -3
ERROR: HTTPConnection(host='127.0.0.1', port=10000): Failed to establish a new connection: [Errno 111] Connection refused
ana@laptop:~/azure$ docker compose up -d 2>&1 | tail -1
 Container azure-azurite-1 Started 
```

`Connection refused` na porta 10000 é o Azurite, na 8081 o emulador do Cosmos DB, na 1433 o SQL Server
e na 5672 o emulador do Event Hubs. Ligue o que a lição nomeia; ele volta vazio.

**A porta está ocupada.** Outro programa já escuta numa das portas do emulador, muitas vezes um
Azurite instalado de outro jeito, ou a extensão do Visual Studio Code com o mesmo nome:

```
ana@laptop:~/azure$ docker compose up -d 2>&1 | tail -1
Error response from daemon: failed to set up container networking: driver failed programming external connectivity on endpoint azure-azurite-1 (9ea6bfe423cfdad65ee7939114da6f05842ec9ed176408f1ae71134c2e7806d4): failed to bind host port 127.0.0.1:10000/tcp: address already in use
```

`sudo ss -ltnp 'sport = :10000'` mostra qual programa a ocupa. Pare esse programa em vez de mudar a
porta no `compose.yaml`: `UseDevelopmentStorage=true` sempre quer dizer 10000, 10001 e 10002.

**O Docker responde `permission denied`.** Esta não foi gravada, porque a máquina em que o curso foi
gravado roda tudo como administrador. A mensagem cita `/var/run/docker.sock`, e quer dizer que o seu
usuário ainda não está no grupo `docker`: a linha do `usermod` do primeiro passo vale a partir do
próximo login, não no terminal em que você a digitou. Saia da sessão e entre de novo, e o `id` deve
listar `docker` entre os seus grupos.

**Um comando chegou a um Azure de verdade.** Esta é a que vale reconhecer, porque é a única falha
daqui que sai do seu computador. Nada neste curso roda `az login`, e por isso nada nele consegue
tocar uma assinatura. Se você já usou a linha de comando do Azure antes, com uma conta de verdade, o
login fica lembrado em `~/.azure`. Um comando que nomeia uma conta real, como
`az storage container list --account-name` seguido de um nome seu, vai usá-lo. **Todo comando de
armazenamento deste curso tira o destino da connection string e não nomeia conta nenhuma.** Se você
vir numa resposta um nome de conta que não seja `devstoreaccount1`, pare, e rode `az logout` antes de
seguir.

**O SQL Server para alguns segundos depois de ligar.** `docker compose --profile sql logs sql` diz
por quê, e num notebook é quase sempre memória: o SQL Server se recusa a rodar com menos de 2 GB. Dê
mais à máquina virtual ou ao Docker Desktop, ou pare o emulador do Cosmos DB enquanto usa o SQL
Server; nenhuma lição precisa dos dois ao mesmo tempo.
