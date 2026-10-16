---
title: Quando a instalação falha
version: 1
---

É aqui que um curso é mais abandonado, num erro sobre uma ferramenta que o aluno ainda não terminou
de instalar. Estas são as falhas encontradas enquanto esta lição foi gravada, na ordem em que a
instalação as encontra, e o que cada uma quer dizer. **Quatro delas foram produzidas de propósito e
aparecem como a máquina as imprimiu; as outras são descritas, e cada uma diz por quê.**

**O ambiente virtual não foi criado.** O Ubuntu traz o Python sem a parte que cria ambientes
virtuais, e o `python3 -m venv` então para com uma mensagem que começa com *The virtual environment
was not created successfully because ensurepip is not available* e nomeia o pacote a instalar. A
cura é `sudo apt-get install -y python3-venv`, o pacote que o primeiro bloco da instalação instala.
A tentativa que falhou deixa um `~/aws/venv` pela metade, então remova-o com `rm -rf ~/aws/venv` e
rode o terceiro bloco de novo. **Esta não foi produzida aqui**, porque a máquina em que as lições
foram gravadas tem o pacote e a falha exige que ele falte; o curso `cloud`, lição 1, mostra a
mensagem inteira.

**O `apt-get` diz que não conseguiu obter uma trava.** O Ubuntu instala as próprias atualizações
nos primeiros minutos depois que uma máquina liga, e só um programa por vez pode instalar pacotes.
Espere alguns minutos e rode o comando de novo. Apagar o arquivo de trava é o conselho que você vai
achar na internet, e é assim que um banco de pacotes se estraga.

**O `aws` não é encontrado.** As ferramentas estão instaladas e este terminal não sabe onde:

```
ana@laptop:~$ aws --version
bash: line 1: aws: command not found
```

Todo terminal novo começa sem `~/.local/bin` no caminho e fora do ambiente virtual.
`source ~/aws/env.sh` devolve os dois, e a mesma linha resolve um `moto_server` que falta. Num
Ubuntu de desktop a mensagem pode trazer a sugestão de instalar o `aws-cli` por um pacote; ignore,
porque a versão de que o curso precisa já está instalada em `~/.local`.

**O `aws` não consegue se conectar ao endpoint.** A linha de comando fez o que o `env.sh` mandou, e
nada respondeu na porta 4567:

```
ana@laptop:~/aws$ aws sts get-caller-identity

aws: [ERROR]: Could not connect to the endpoint URL: "http://localhost:4567/"
```

O moto não está rodando. Inicie-o no primeiro terminal com `moto_server -p 4567`, depois de ler o
`env.sh` lá também. Se ele está rodando e isso ainda acontece, olhe o primeiro terminal: um moto que
parou com erro diz por quê nas últimas linhas.

**O moto não inicia porque a porta está em uso.** Uma segunda cópia, ou qualquer outro programa já
escutando na 4567, recebe isto:

```
ana@laptop:~/aws$ timeout 10 moto_server -p 4567
Address already in use
Port 4567 is in use by another program. Either identify and stop that program, or start the server with a different port.
```

O dono mais provável é um moto que você iniciou antes e deixou rodando, talvez num terminal
escondido atrás de outro. Ache-o e aperte Ctrl+C ali, ou feche esse terminal. Se outro programa
precisa mesmo da 4567, qualquer porta livre serve, desde que o `AWS_ENDPOINT_URL` do `env.sh` cite a
mesma.

**O token de segurança é inválido.** Esta é a falha que vale entender, porque é o que o `env.sh`
existe para impedir. Alguém removeu a variável que aponta para o moto, e a linha de comando fez o
que faz por padrão:

```
ana@laptop:~/aws$ unset AWS_ENDPOINT_URL; aws sts get-caller-identity

aws: [ERROR]: An error occurred (InvalidClientTokenId) when calling the GetCallerIdentity operation: The security token included in the request is invalid.
```

**Essa requisição foi para a própria AWS**, para o serviço de tokens de segurança de verdade em São
Paulo, levando a chave de marcação do moto. A AWS a recusou, porque essa chave não existe, e nada
foi criado nem cobrado. Com uma chave real no ambiente, o mesmo engano teria rodado o comando numa
conta real, e é por isso que este curso nunca pede que você guarde uma ali. `source ~/aws/env.sh`
define a variável de novo.

**O instalador da AWS falha com `Exec format error`, ou o `aws` não roda.** O arquivo zip é feito
para um tipo de processador. Uma máquina virtual num Mac com Apple silicon, e a maioria das placas
Arm pequenas, precisam do arquivo `aarch64` que a instalação cita, e `uname -m` imprime qual tipo
você tem: `x86_64` ou `aarch64`. Apague o `~/.local/aws-cli` e instale a partir do outro arquivo.
Não produzida aqui, já que a máquina de gravação é `x86_64`.

**Um download da lista de preços parou no meio.** O programa da última seção desta lição grava cada
download num arquivo terminado em `.part` e só lhe dá o nome real quando está completo, então um
download quebrado nunca é confundido com um terminado. Rode o mesmo comando de novo e ele recomeça
do início. Os arquivos que esta lição lê têm cerca de 1,5 MB cada, então isso é raro; o arquivo do
EC2 que a lição 14 lê tem uns 290 MB, e é ali que acontece.
