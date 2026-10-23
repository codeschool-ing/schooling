---
title: Quando a instalação falha
version: 1
---

É aqui que um curso costuma ser abandonado, num erro de uma ferramenta que ainda não está bem
instalada. Estas são as falhas encontradas enquanto esta aula era gravada, na ordem em que a
instalação as encontra. **Quatro foram produzidas de propósito e são citadas como a máquina as
imprimiu; as outras são descritas, e cada uma diz por quê.**

**O ambiente virtual não foi criado.** O Ubuntu traz o Python sem a parte que monta ambientes
virtuais, e `python3 -m venv` então para com uma mensagem que começa com *The virtual environment was
not created successfully because ensurepip is not available*, nomeando o pacote a instalar. Instale
com `sudo apt-get install -y python3-venv`, que o primeiro bloco já faz, remova o diretório feito pela
metade com `rm -rf ~/aws/venv` e rode o terceiro bloco de novo. **Não produzida aqui**: a máquina da
gravação tem o pacote, e a falha precisa que ele falte.

**O `apt-get` não consegue a trava.** O Ubuntu instala as próprias atualizações nos primeiros
minutos depois de a máquina ligar, e só um programa pode instalar pacotes por vez. Espere alguns
minutos e rode de novo. Apagar o arquivo de trava, o conselho que você vai achar na internet, é como
um banco de pacotes se estraga.

**O `aws` não é encontrado.** As ferramentas estão instaladas e este terminal não sabe onde:

```
ana@laptop:~$ aws --version
bash: line 1: aws: command not found
```

Todo terminal novo começa sem `~/.local/bin` no caminho e fora do ambiente virtual.
`source ~/aws/env.sh` devolve os dois, e a mesma linha resolve um `moto_server` que falta.

**O `aws` não consegue se conectar ao endpoint.** A linha de comando fez o que o `env.sh` mandou, e
nada respondeu na porta 4567:

```
ana@laptop:~/aws$ aws sts get-caller-identity

aws: [ERROR]: Could not connect to the endpoint URL: "http://localhost:4567/"
```

O moto não está rodando. Inicie-o no primeiro terminal, depois de ler o `env.sh` ali também. Se ele
está rodando e isso ainda acontece, olhe aquele terminal: um moto que parou com erro diz por quê nas
últimas linhas.

**O moto não inicia porque a porta está em uso.** Uma segunda cópia, ou qualquer outro programa já
escutando na 4567, recebe isto:

```
ana@laptop:~/aws$ timeout 10 moto_server -p 4567
Address already in use
Port 4567 is in use by another program. Either identify and stop that program, or start the server with a different port.
```

O dono mais provável é um moto que você iniciou antes e deixou rodando num terminal escondido atrás de
outro. Aperte Ctrl+C ali, ou feche esse terminal. Se outra coisa realmente precisa da 4567, qualquer
porta livre serve, desde que `AWS_ENDPOINT_URL` no `env.sh` aponte para a mesma.

**O token de segurança é inválido.** Esta é a falha que vale a pena entender, porque é a que o
`env.sh` foi escrito para tornar inofensiva. A variável que aponta para o moto foi removida, e a
linha de comando fez o que faz por padrão:

```
ana@laptop:~/aws$ unset AWS_ENDPOINT_URL; aws sts get-caller-identity

aws: [ERROR]: An error occurred (InvalidClientTokenId) when calling the GetCallerIdentity operation: The security token included in the request is invalid.
```

**Essa requisição foi para a própria AWS**, para o serviço de tokens real, levando a chave de mentira
do moto. A AWS a recusou, já que essa chave não existe, e nada foi criado nem cobrado. Com uma chave
real no ambiente, o mesmo deslize teria rodado o comando numa conta real. Esse é todo o argumento a
favor dos valores `test`: **um erro deve falhar, e não dar certo num lugar que você não queria**.
`source ~/aws/env.sh` define a variável de novo.

**O instalador falha com `Exec format error`.** O arquivo zip é feito para um tipo de processador, e
`uname -m` diz qual é o seu: `x86_64` ou `aarch64`. Apague `~/.local/aws-cli` e instale pelo arquivo
que a instalação indica para o outro. Não produzida aqui, já que a máquina da gravação é `x86_64`.
