---
title: Quando o laboratório não responde
version: 1
---

Estas são as falhas encontradas enquanto esta aula era gravada, na ordem em que um aluno as
encontra, com o que cada uma diz e o que significa. A maioria delas é uma linha esquecida.

**O `gcloud` não é encontrado.** Um terminal novo começa sem `~/gcp/google-cloud-sdk/bin` no caminho:

```
ana@laptop:~/gcp$ PATH=/usr/bin:/bin; gcloud version
bash: line 1: gcloud: command not found
```

A segunda linha de "Toda vez que você abrir um terminal" o põe de volta. O `fake-gcs-server` some do
mesmo jeito, no outro terminal, quando a linha do `export PATH` foi pulada.

**Sem credenciais, e nada dizendo para não usar nenhuma.** O terminal tem o caminho e o endpoint, e
não tem `CLOUDSDK_AUTH_DISABLE_CREDENTIALS`, então o `gcloud` procura uma conta com que assinar, não
encontra nenhuma e para antes de mandar qualquer coisa:

```
ana@laptop:~/gcp$ env -u CLOUDSDK_AUTH_DISABLE_CREDENTIALS gcloud storage buckets list
ERROR: (gcloud.storage.buckets.list) You do not currently have an active account selected.
Please run:

  $ gcloud auth login

to obtain new credentials.

If you have already logged in with a different account, run:

  $ gcloud config set account ACCOUNT

to select an already authenticated account to use.
```

**Não siga o conselho dele.** `gcloud auth login` conecta esta linha de comando a uma conta real do
Google, e a partir daí um terminal que perdeu a linha do endpoint estaria falando com o Google como
você. A correção é a terceira linha do bloco, digitada de novo.

**Sem projeto.** Toda requisição ao Cloud Storage dá nome a um projeto, e sem `CLOUDSDK_CORE_PROJECT`
não há nenhum para nomear:

```
ana@laptop:~/gcp$ env -u CLOUDSDK_CORE_PROJECT gcloud storage buckets list
ERROR: (gcloud.storage.buckets.list) The required property [project] is not currently set.
It can be set on a per-command basis by re-running your command with the [--project] flag.

You may set it for your current workspace by running:

  $ gcloud config set project VALUE

or it can be set temporarily by the environment variable [CLOUDSDK_CORE_PROJECT]
```

A última das três sugestões é a que este curso usa, e a terceira linha do bloco é onde ela está.

**O emulador não está rodando.** As variáveis estão definidas e ninguém está escutando na porta,
porque o outro terminal foi fechado, ou `Ctrl+C` interrompeu o servidor:

```
ana@laptop:~/gcp$ gcloud storage buckets list
ERROR: gcloud crashed (ConnectionError): HTTPConnectionPool(host='localhost', port=4443): Max retries exceeded with url: /storage/v1/b?alt=json&maxResults=1000&project=planner-dev&projection=full (Caused by NewConnectionError("HTTPConnection(host='localhost', port=4443): Failed to establish a new connection: [Errno 111] Connection refused"))

If you would like to report this issue, please run the following command:
  gcloud feedback

To check gcloud for common problems, please run the following command:
  gcloud info --run-diagnostics
```

**`gcloud crashed` parece pior do que é.** As duas palavras que importam são `port=4443` e
`Connection refused`: a requisição foi aonde devia, e não havia ninguém lá. Inicie o emulador de novo
no terminal dele. Ele volta vazio, e a aula em que você estava reconstrói o que precisa a partir do
primeiro comando. O mesmo erro com `port=8085`, `9020` ou outro número aponta o emulador de uma aula
posterior.

**A porta está ocupada.** Um segundo `fake-gcs-server`, num terceiro terminal, ou um que ficou para
trás num terminal fechado sem interrompê-lo:

```
ana@laptop:~/gcp$ timeout 10 fake-gcs-server -scheme http -port 4443 -backend memory -location southamerica-east1 2>&1 | tail -3
time=2026-10-30T15:06:30.251-03:00 level=ERROR msg="listen tcp 0.0.0.0:4443: bind: address already in use"
```

`address already in use` quer dizer que já há um emulador respondendo, então não há nada a corrigir, a
menos que você quisesse um vazio. Para parar o antigo, encontre o processo dele e encerre-o: `pgrep
-af fake-gcs-server` mostra o número dele, e `kill` seguido desse número o interrompe.

## Quando a própria instalação falha

**O `gcloud components install` para com um erro de rede.** Ele baixa cada componente de
`dl.google.com`, então precisa da rede na primeira vez e nunca mais. Rode a mesma linha de novo; ela
pula o que já está lá.

**Ele pede para atualizar a linha de comando primeiro.** A linha do `fixed_sdk_version` foi pulada.
Responda que não, rode essa linha e rode a instalação de novo.

**Um emulador Java não inicia**, nas aulas 10 e 19, com `java: command not found` ou um erro de
versão. Falta o pacote `openjdk-21-jre-headless` do primeiro bloco, e `java -version` diz isso numa
linha.

**Disco.** O laboratório quer 1,6 GB, e o `pip` precisa de algum espaço próprio enquanto
descompacta. Numa máquina virtual com disco pequeno, um `df -h ~` antes da instalação poupa uma hora
lendo erros pela metade.

**Recomeçar é barato.** Tudo o que esta seção instala mora em `~/gcp` e `~/.config/gcloud`, então `rm
-rf ~/gcp ~/.config/gcloud` e os blocos acima, em ordem, dão a você um laboratório no estado em que
estas transcrições foram gravadas. Nada fora desses dois diretórios foi tocado, fora os pacotes do
primeiro bloco.
