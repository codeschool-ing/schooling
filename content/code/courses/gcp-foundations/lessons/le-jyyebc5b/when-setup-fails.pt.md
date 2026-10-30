---
title: Quando a instalação falha
version: 1
---

Um curso costuma ser abandonado aqui, num erro sobre uma ferramenta que o aluno ainda não terminou de
instalar. Estas são as falhas encontradas enquanto esta lição foi gravada, na ordem em que a instalação
as encontra, e o que cada uma quer dizer. **Seis delas foram provocadas de propósito e estão citadas
como a máquina as imprimiu; as outras duas são descritas, e cada uma diz por quê.**

**O ambiente virtual não foi criado.** O Ubuntu traz o Python sem a parte que cria ambientes virtuais.
O `python3 -m venv` então para com uma mensagem que começa com *The virtual environment was not created
successfully because ensurepip is not available* e nomeia o pacote a instalar. A cura é
`sudo apt-get install -y python3-venv`, do primeiro bloco da instalação. A tentativa que falhou deixa
um `~/gcp/venv` pela metade, então remova-o com `rm -rf ~/gcp/venv` e rode esse bloco de novo. **Esta
não foi provocada aqui**, porque a máquina em que as lições foram gravadas tem o pacote, e a falha
precisa que ele falte. O curso `cloud`, lição 1, cita a mensagem inteira.

**O `apt-get` diz que não conseguiu uma trava.** O Ubuntu instala as próprias atualizações nos
primeiros minutos depois de a máquina ligar, e só um programa por vez pode instalar pacotes. Espere
alguns minutos e rode o comando de novo. Apagar o arquivo da trava é o conselho que você vai achar na
internet, e é assim que um banco de dados de pacotes se estraga. **Também não foi provocada aqui**:
depende do que a máquina estiver fazendo naquela hora.

**O `gcloud` não é encontrado.** As ferramentas estão instaladas e este terminal não sabe onde:

```
ana@laptop:~$ gcloud version
bash: line 1: gcloud: command not found
```

Todo terminal novo começa sem o diretório da CLI no caminho. O `source ~/gcp/env.sh` o põe de volta, e
a mesma linha resolve um `terraform` que falte. Num desktop Ubuntu a mensagem pode sugerir instalar o
`google-cloud-cli` por um pacote. Ignore: a versão de que o curso precisa já está instalada em
`~/.local`.

**O `gcloud` roda, e pede para você entrar numa conta.** Vale ler duas vezes, porque parece um
problema com a sua conta do Google e não é:

```
ana@laptop:~/gcp$ ~/.local/google-cloud-sdk/bin/gcloud pubsub topics list
ERROR: (gcloud.pubsub.topics.list) You do not currently have an active account selected.
Please run:

  $ gcloud auth login

to obtain new credentials.

If you have already logged in with a different account, run:

  $ gcloud config set account ACCOUNT

to select an already authenticated account to use.
```

O comando foi encontrado pelo caminho completo, mas o `env.sh` nunca foi lido, então o
`CLOUDSDK_CONFIG` não estava definido e o `gcloud` procurou as configurações em `~/.config/gcloud`,
onde não há nenhuma: nem projeto, nem token placeholder, nem endereço do emulador. **Não rode
`gcloud auth login` para a mensagem sumir.** Isso põe uma conta Google real justamente no diretório de
que o laboratório foi feito para manter distância. O `source ~/gcp/env.sh` é a cura.

**O emulador não está rodando.** A CLI não tem com quem falar na porta 8085, e diz isso por extenso:

```
ana@laptop:~/gcp$ gcloud pubsub topics list
ERROR: gcloud crashed (ConnectionError): HTTPConnectionPool(host='localhost', port=8085): Max retries exceeded with url: /v1/projects/planner-dev/topics?alt=json (Caused by NewConnectionError("HTTPConnection(host='localhost', port=8085): Failed to establish a new connection: [Errno 111] Connection refused"))

If you would like to report this issue, please run the following command:
  gcloud feedback

To check gcloud for common problems, please run the following command:
  gcloud info --run-diagnostics
```

`gcloud crashed` soa pior do que é. A parte útil está no fim da primeira linha, `Connection refused` em
`localhost` porta `8085`: nada está escutando ali. Inicie o emulador no primeiro terminal, como a seção
anterior mostra. A sugestão de rodar `gcloud feedback` é para um travamento de verdade; este não é um,
então não há nada a relatar.

**Não há Java.** O emulador é um programa Java, e a CLI confere isso antes de iniciá-lo:

```
ana@laptop:~/gcp$ gcloud beta emulators pubsub start --host-port=localhost:8085
ERROR: (gcloud.beta.emulators.pubsub.start) To use the Google Cloud Pub/Sub emulator, a Java 7+ JRE must be installed and on your system PATH
```

A mensagem pede Java 7 ou mais recente, o que é mais antigo que qualquer coisa que o Ubuntu 24.04
ainda distribui. Instale o `openjdk-21-jre-headless`, do primeiro bloco da instalação, e inicie o
emulador de novo.

**A porta já está ocupada.** Um segundo emulador, iniciado enquanto o primeiro ainda roda, encontra a
porta 8085 em uso. Ele imprime um stack trace do Java de umas quarenta linhas, e duas delas são as que
se leem:

```
ana@laptop:~/gcp$ timeout 20 gcloud beta emulators pubsub start --host-port=localhost:8085 2>&1 | grep -m2 -E "Exception|already in use"
[pubsub] Exception in thread "main" java.net.BindException: Address already in use
[pubsub] 	Suppressed: java.lang.RuntimeException: Rethrowing promise failure cause
```

`Address already in use` quer dizer que outro programa ocupa a porta, e quase sempre é o emulador que
você iniciou antes em outro terminal e esqueceu. Procure-o lá e pare-o com **Ctrl+C**. Se não o achar,
`ss -ltnp | grep 8085` nomeia o processo que ocupa a porta.

**Um pedido foi para o Google em vez do emulador.** Esta é a falha que o laboratório foi feito para
tornar inofensiva. Remova a propriedade que aponta o Pub/Sub para a porta 8085, pergunte de novo, e
ponha a propriedade de volta:

```
ana@laptop:~/gcp$ gcloud config unset api_endpoint_overrides/pubsub
Unset property [api_endpoint_overrides/pubsub].
ana@laptop:~/gcp$ gcloud pubsub topics list
ERROR: (gcloud.pubsub.topics.list) UNAUTHENTICATED: Request had invalid authentication credentials. Expected OAuth 2 access token, login cookie or other valid authentication credential. See https://developers.google.com/identity/sign-in/web/devconsole-project. This command is authenticated with an access token from /home/ana/gcp/placeholder-token specified by the [auth/access_token_file] property.
- '@type': type.googleapis.com/google.rpc.ErrorInfo
  metadata:
    method: google.pubsub.v1.Publisher.ListTopics
    service: pubsub.googleapis.com
  reason: CREDENTIALS_MISSING
ana@laptop:~/gcp$ gcloud config set api_endpoint_overrides/pubsub http://localhost:8085/
WARNING: The value set for [api_endpoint_overrides/pubsub] was found to be associated with a universe domain outside of the current config universe [googleapis.com]. Please create a new gcloud configuration for each universe domain you make requests to using `gcloud config configurations create` with the `--universe-domain` flag or switch to a configuration associated with [http://localhost:8085/].
Updated property [api_endpoint_overrides/pubsub].
```

Sem o override, o `gcloud` mandou o pedido para `pubsub.googleapis.com`, nos datacenters do Google, e o
Google recusou a palavra `placeholder` como credencial. **Essa recusa é a rede de proteção
funcionando**: um comando que escapa do laboratório falha em vez de fazer alguma coisa no projeto de
alguém. Se você a vir quando queria falar com o emulador, falta o override; o `gcloud config list`
mostra se ele está lá.
