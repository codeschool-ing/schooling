---
title: A sua AWS, no seu próprio computador
version: 1
---

Este curso é praticado contra o **moto**, um programa de código aberto que responde à API da AWS
numa porta do seu próprio computador, com a linha de comando de verdade da AWS apontada para ele.
Não existe conta AWS em lugar nenhum, nada é cobrado, e a plataforma não roda nada por você: cada
comando destas lições é digitado no seu próprio terminal. **A lição 1 de `aws-foundations` monta
este ambiente por inteiro**, com os três jeitos de ter um terminal no Ubuntu 24.04 (instalado, que
é o que ela recomenda; uma máquina virtual; um shell alugado on-line), o que cada um custa ao seu
computador e o que fazer quando a instalação falha. Se você fez aquele curso, já tem tudo o que vem
abaixo. Se não fez, ou apagou depois, esta seção é a mesma montagem, resumida.

## Montando

Três pacotes vêm do repositório do Ubuntu. `python3-venv` é o que as pessoas esquecem, porque o
Ubuntu traz o Python sem ele:

```sh
sudo apt-get update
sudo apt-get install -y python3-venv curl unzip jq
```

Depois a linha de comando da AWS, versão 2.37.4, em `~/.local`, e o moto 5.2.3 num ambiente virtual
só dele, em `~/aws/venv`. Nada aqui precisa de `sudo`:

```sh
mkdir -p ~/aws ~/.local/bin && cd ~/aws
curl -sS -o awscliv2.zip https://awscli.amazonaws.com/awscli-exe-linux-x86_64-2.37.4.zip
unzip -q awscliv2.zip && ./aws/install -i ~/.local/aws-cli -b ~/.local/bin
rm -rf aws awscliv2.zip
python3 -m venv ~/aws/venv
~/aws/venv/bin/pip install -q 'moto[server]==5.2.3'
```

Se `aws-foundations` já instalou a linha de comando, o `./aws/install` recusa com uma mensagem sobre
uma instalação existente, e tudo bem: a versão é a mesma. Num computador com processador Arm o
arquivo é `awscli-exe-linux-aarch64-2.37.4.zip`.

## Iniciando, toda vez

**O moto guarda tudo na memória e esquece quando para**, então nada de ontem continua lá hoje, e
nenhuma lição supõe que continue. Abra um terminal só para o moto e inicie-o ali:

```sh
~/aws/venv/bin/moto_server -p 4567
```

Ele imprime um aviso, o endereço em que escuta e depois uma linha para cada requisição que responde:

```
WARNING: This is a development server. Do not use it in a production deployment. Use a production WSGI server instead.
 * Running on http://127.0.0.1:4567
Press CTRL+C to quit
127.0.0.1 - - [16/Oct/2026 12:22:09] "GET / HTTP/1.1" 200 -
127.0.0.1 - - [16/Oct/2026 12:22:10] "POST / HTTP/1.1" 200 -
```

**O aviso é sobre o moto, não sobre você**: ele é um servidor web de desenvolvimento, e é exatamente
para isso que ele serve aqui. Deixe esse terminal aberto. Num **segundo** terminal, aquele em que
você trabalha, cinco linhas apontam a linha de comando para ele:

```sh
cd ~/aws && source venv/bin/activate
export PATH="$HOME/.local/bin:$PATH"
export AWS_ENDPOINT_URL=http://localhost:4567
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=sa-east-1
```

`AWS_ENDPOINT_URL` manda cada requisição para o moto em vez da AWS. O par de chaves é a palavra
`test` duas vezes: o moto aceita qualquer credencial, e a AWS recusa estas, que é justamente a ideia.
A região é São Paulo. As variáveis vivem só naquele terminal, então um terminal novo precisa das
cinco linhas de novo.

Depois confira que ele responde:

```
ana@laptop:~/aws$ aws --version
aws-cli/2.37.4 Python/3.14.6 Linux/6.18.44-fc-v139 exe/x86_64.ubuntu.24
ana@laptop:~/aws$ aws sts get-caller-identity
{
    "UserId": "AKIAIOSFODNN7EXAMPLE",
    "Account": "123456789012",
    "Arn": "arn:aws:sts::123456789012:user/moto"
}
ana@laptop:~/aws$ du -sh ~/aws/venv ~/.local/aws-cli
301M	/home/ana/aws/venv
273M	/home/ana/.local/aws-cli
```

A primeira linha é a versão da linha de comando. O segundo comando perguntou "quem sou eu?", e o
moto respondeu com uma conta que ele inventou, `123456789012`, que é a conta que todas as
transcrições deste curso mostram. O outro terminal imprimiu uma linha para essa requisição. O último
comando é o disco que as duas instalações ocupam, uns 575 MB, e apagar `~/aws` e `~/.local/aws-cli`
remove tudo.

## Quando ele não responde

Três falhas cobrem quase todos os casos.

**Falta a variável do endpoint.** Um terminal novo em que as cinco linhas não foram digitadas manda
a requisição para a AWS de verdade, que recusa a chave `test`:

```
ana@laptop:~/aws$ aws sts get-caller-identity

aws: [ERROR]: An error occurred (InvalidClientTokenId) when calling the GetCallerIdentity operation: The security token included in the request is invalid.
```

As palavras *security token* são da AWS, e vê-las significa que a requisição saiu do seu computador.
Digite as cinco linhas e pergunte de novo.

**O moto não está rodando.** A linha de comando tenta de novo e depois desiste do endereço:

```
ana@laptop:~/aws$ aws sts get-caller-identity

aws: [ERROR]: Could not connect to the endpoint URL: "http://localhost:4567/"
```

**A porta 4567 está ocupada**, por um moto antigo esquecido em outro terminal ou por outro programa.
Um segundo moto para na hora, e diz por quê:

```
ana@laptop:~/aws$ timeout 10 moto_server -p 4567 2>&1 | tail -2
Address already in use
Port 4567 is in use by another program. Either identify and stop that program, or start the server with a different port.
```

Feche o outro terminal, ou encontre o programa com `ss -ltnp | grep 4567`.
