---
title: Um script de provisionamento
version: 1
---

Um arquivo num repositório é metade da cura. A outra metade é um programa que faz um servidor
ficar igual a ele, e a propriedade de que esse programa mais precisa é que **rodá-lo duas vezes
seja o mesmo que rodá-lo uma**. Essa propriedade se chama **idempotência**. Um script que a tem
pode rodar numa máquina vazia, numa máquina que ele montou no mês passado e numa máquina que alguém
editou à mão, e em cada caso faz só o que falta e diz o que foi.

A primeira tentativa de costume é uma lista dos comandos que alguém digitou ao montar o primeiro
servidor: `apt install`, `cp`, `echo >> pg_hba.conf`, `createuser`. Funciona uma vez. Na segunda,
o `createuser` falha porque o papel já existe, o `echo` acrescenta a linha do `pg_hba.conf` de
novo, e o script para no meio ou, pior, segue em frente. **Todo passo tem de conferir antes de
agir.** Aqui está o script inteiro, nas partes que fazem isso:

```schooling-example
{"language": "bash", "file": "provision.sh", "parts": [{"code": "#!/usr/bin/env bash\n# provision.sh: make this machine the shop's database server, or confirm\n# that it already is one. Run it as root, as often as you like.\nset -euo pipefail\nHERE=$(cd \"$(dirname \"$0\")\" && pwd)\ncd /\n", "note": "O `set -euo pipefail` para o script no primeiro comando que falhar, em vez de seguir em frente e anunciar sucesso sobre um servidor montado pela metade. `HERE` é o repositório onde o script mora, achado pelo próprio caminho do script, então ele pode ser rodado de qualquer lugar; o `cd /` depois disso evita que o `sudo -u postgres` reclame que não consegue entrar no seu diretório pessoal."}, {"code": "ETC=/etc/postgresql/16/main\nchanged=no\nreload=no\nsay() { echo \"$*\"; changed=yes; }\n", "note": "`changed` registra se alguma coisa foi feita, `reload` se a configuração foi mexida. `say` é como cada passo anuncia uma ação, e ele marca `changed` enquanto imprime, então nenhum passo age sem o script saber."}, {"code": "if [ \"$(dpkg-query -W -f '${db:Status-Status}' postgresql 2>/dev/null)\" != installed ]; then\n    DEBIAN_FRONTEND=noninteractive apt-get install -y -q postgresql >/dev/null\n    say \"installed postgresql\"\nfi\n", "note": "**Conferir, depois agir.** Todo passo tem esse formato. Aqui a conferência é o banco de pacotes: o `dpkg-query` imprime `installed` quando o PostgreSQL está lá, e só no caso contrário o `apt-get` roda. A saída dele vai para `/dev/null`, porque o trabalho deste script é dizer o que mudou, numa linha."}, {"code": "if ! cmp -s \"$HERE/conf.d/50-shop.conf\" \"$ETC/conf.d/50-shop.conf\"; then\n    install -o postgres -g postgres -m 644 \"$HERE/conf.d/50-shop.conf\" \"$ETC/conf.d/\"\n    say \"wrote $ETC/conf.d/50-shop.conf\"\n    reload=yes\nfi\n", "note": "O `cmp -s` compara o arquivo do repositório com o instalado e não diz nada; ele falha quando os dois diferem ou quando o instalado ainda não existe. Só então o arquivo é copiado, com o `install` acertando dono e permissões no mesmo passo, e só então se pede um reload."}, {"code": "HBA='host    shop    shop_app    10.0.0.0/24    scram-sha-256'\nif ! grep -qxF \"$HBA\" \"$ETC/pg_hba.conf\"; then\n    echo \"$HBA\" >> \"$ETC/pg_hba.conf\"\n    say \"added the shop_app line to pg_hba.conf\"\n    reload=yes\nfi\n", "note": "O `grep -qxF` procura a linha inteira, exata, como texto fixo. Uma linha que já está lá fica como está; uma que falta é acrescentada no fim. Acrescentar no fim só é seguro aqui porque nada acima dela no `pg_hba.conf` do Ubuntu casa com a rede `10.0.0.0/24`."}, {"code": "if [ \"$reload\" = yes ]; then\n    systemctl reload postgresql@16-main\n    sleep 1\n    echo \"reloaded the configuration\"\nfi\n", "note": "**Reload só quando algo mudou.** Um reload é um sinal, e o servidor o aplica um instante depois, então o `sleep 1` dá esse instante antes de o script perguntar qualquer coisa ao servidor. Um parâmetro que precisa de restart é lido aqui e fica esperando; veja a última parte."}, {"code": "sql() { sudo -u postgres psql -XAtq -v ON_ERROR_STOP=1 -c \"$1\"; }\nif [ -z \"$(sql \"SELECT 1 FROM pg_roles WHERE rolname = 'shop_owner'\")\" ]; then\n    sql \"CREATE ROLE shop_owner NOLOGIN\"\n    say \"created role shop_owner\"\nfi\nif [ -z \"$(sql \"SELECT 1 FROM pg_roles WHERE rolname = 'shop_app'\")\" ]; then\n    sql \"CREATE ROLE shop_app LOGIN\"\n    say \"created role shop_app, with no password yet\"\nfi\nif [ -z \"$(sql \"SELECT 1 FROM pg_database WHERE datname = 'shop'\")\" ]; then\n    sudo -u postgres createdb --owner shop_owner shop\n    say \"created database shop\"\nfi\n", "note": "O mesmo conferir-e-agir para o que mora dentro do servidor. `sql` roda um comando como o papel `postgres` e imprime linhas cruas, então uma resposta vazia quer dizer que o papel ou o banco não existe. `shop_app` fica sem senha: senha não pertence a um repositório, e a lição 11 define uma com `\\password`. O que cada papel pode fazer é assunto das lições 12 e 13."}, {"code": "waiting=$(sql \"SELECT string_agg(name, ', ') FROM pg_settings WHERE pending_restart\")\nif [ -n \"$waiting\" ]; then\n    echo \"RESTART NEEDED for: $waiting\"\nfi\nif [ \"$changed\" = no ]; then\n    echo \"nothing to change\"\nfi", "note": "**O script nunca reinicia o servidor.** Um restart derruba todas as conexões, e quando fazer isso é decisão de uma pessoa, então ele diz quais parâmetros estão esperando e para. Uma execução que não fez nada diz isso — e é essa a linha a procurar na segunda vez que ele roda."}]}
```

Salve-o como `shop-db/provision.sh` e faça o commit ao lado do arquivo de configuração:

```
ana@db:~$ git -C shop-db add provision.sh
ana@db:~$ git -C shop-db commit -m "provision.sh: build the shop server from nothing"
[main 2332b60] provision.sh: build the shop server from nothing
 1 file changed, 57 insertions(+)
 create mode 100644 provision.sh
ana@db:~$ git -C shop-db log --oneline
2332b60 provision.sh: build the shop server from nothing
6ab72d8 The shop server's settings, one file
```

## Onde rodar

O script foi escrito para **uma máquina nova**: um Ubuntu 24.04 montado como a lição 3 montou o
seu, e parado antes do `apt install postgresql`. Uma segunda máquina virtual, ou uma cópia da sua
feita antes desse passo, é o lugar certo. Copie o repositório do jeito que você passa arquivos
entre máquinas — `git clone` de onde você o guarda, ou `scp -r shop-db` — e rode lá. Na máquina de
gravação os mesmos dois arquivos foram escritos direto num servidor novo. O prompt dele também diz
`ana@db`, porque esse é o nome que a lição 3 dá a um servidor.

Ele é idempotente, então rodá-lo no servidor do curso não quebraria nada, mas também não seria
nada. Saiba o que ele faria lá: escreveria o `50-shop.conf`, que faz o servidor escutar em todos os
endereços e pede um restart por causa do `shared_buffers`; acrescentaria uma linha ao
`pg_hba.conf`; e criaria os papéis `shop_owner` e `shop_app`. Ele **pularia o banco**, porque o
`shop` existe — e não perceberia que o seu pertence a `ana`, e não a `shop_owner`, já que a
conferência só pergunta se o nome existe. Vale lembrar dessa lacuna: um script confere exatamente
o que foi escrito para conferir.

## Duas vezes

Na máquina nova, nada está instalado ainda:

```
ana@db:~$ psql --version
-bash: line 1: psql: command not found
ana@db:~$ sudo bash shop-db/provision.sh
installed postgresql
wrote /etc/postgresql/16/main/conf.d/50-shop.conf
added the shop_app line to pg_hba.conf
reloaded the configuration
created role shop_owner
created role shop_app, with no password yet
created database shop
RESTART NEEDED for: listen_addresses, shared_buffers
ana@db:~$ sudo systemctl restart postgresql@16-main
ana@db:~$ sudo bash shop-db/provision.sh
nothing to change
```

A primeira execução fez todos os passos e disse cada um, uma linha por passo. Ela terminou
avisando de dois parâmetros esperando um restart, porque `listen_addresses` e `shared_buffers` só
são lidos quando o servidor sobe. Numa máquina a que ninguém está conectado ainda, agora é uma boa
hora, então o restart é o comando seguinte. Num servidor em uso ele esperaria uma hora tranquila, e
o script continuaria avisando a cada execução.

**A segunda execução é o teste do script**, e ela não mudou nada: nenhum arquivo escrito, nenhuma
linha acrescentada, nenhum reload, nenhum papel. Um script de provisionamento que muda alguma coisa
toda vez que roda está brigando com outra ferramenta pelo mesmo arquivo ou carregando um bug, e de
qualquer jeito você quer saber disso na segunda execução, e não na quinquagésima.

## Uma mudança é um commit

Depois que um servidor é montado assim, uma mudança nele passa primeiro pelo repositório. Edite o
arquivo, leia a diferença, faça o commit com o motivo e rode o script:

```
ana@db:~$ sed -i 's/^work_mem = 16MB/work_mem = 32MB/' shop-db/conf.d/50-shop.conf
ana@db:~$ git -C shop-db diff
diff --git a/conf.d/50-shop.conf b/conf.d/50-shop.conf
index 9150e27..714e6d4 100644
--- a/conf.d/50-shop.conf
+++ b/conf.d/50-shop.conf
@@ -2,7 +2,7 @@
 # defaults. provision.sh copies it into /etc/postgresql/16/main/conf.d/.
 listen_addresses = '*'               # the application connects from 10.0.0.0/24
 shared_buffers = 1GB                 # a quarter of a 4 GB machine (lesson 6)
-work_mem = 16MB
+work_mem = 32MB
 maintenance_work_mem = 256MB
 log_min_duration_statement = 500ms   # lesson 19
 log_lock_waits = on
ana@db:~$ git -C shop-db commit -q -am "work_mem 32MB: the nightly report sorts on disk"
ana@db:~$ sudo bash shop-db/provision.sh
wrote /etc/postgresql/16/main/conf.d/50-shop.conf
reloaded the configuration
```

O `sed` faz o papel do seu editor. O `work_mem` só precisa de reload, então esta execução não
imprimiu linha de restart. A mensagem do commit leva o motivo, que é o que o `git log` vai
responder quando alguém perguntar daqui a seis meses por que este servidor ordena com 32 MB.
