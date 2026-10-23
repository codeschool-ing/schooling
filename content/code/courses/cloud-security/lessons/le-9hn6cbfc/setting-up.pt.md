---
title: Instalando o laboratório
version: 1
---

Tudo abaixo roda num terminal do Ubuntu 24.04, como o seu próprio usuário, e só o primeiro bloco
pede `sudo`. **O resto vai para dois lugares: `~/aws`, onde você trabalha o curso inteiro, e
`~/.local`, onde fica a linha de comando da AWS.** Apagar os dois remove o laboratório por completo.

Se `aws --version` já imprime `aws-cli/2.37.4`, o segundo bloco está feito; se
`~/aws/venv/bin/moto_server` existe, o terceiro e o quarto também. Pule para a última parte desta
seção e confira que o laboratório responde.

## Os pacotes do Ubuntu

Python, `curl` e `jq` vêm do repositório do próprio Ubuntu, com o `unzip` para abrir o instalador da
AWS:

```sh
sudo apt-get update
sudo apt-get install -y python3 python3-venv curl jq unzip
```

**O `python3-venv` é o que as pessoas esquecem**, porque o Ubuntu traz o Python sem ele. Sem ele o
terceiro bloco falha, e a próxima seção mostra como isso aparece.

## A linha de comando da AWS

A AWS publica a sua linha de comando como um arquivo zip com um instalador dentro. Estes comandos
baixam uma versão fixa, a mesma com que todas as transcrições foram gravadas, e a instalam no seu
diretório pessoal, então nada aqui precisa de `sudo`:

```sh
mkdir -p ~/aws ~/.local/bin
cd ~/aws
curl -sS -o awscliv2.zip https://awscli.amazonaws.com/awscli-exe-linux-x86_64-2.37.4.zip
unzip -q awscliv2.zip
./aws/install -i ~/.local/aws-cli -b ~/.local/bin
rm -rf aws awscliv2.zip
```

Uma versão mais nova faz tudo o que este curso pede; a linha de versão e o texto de algumas mensagens
vão diferir das transcrições. Num processador Arm, o que inclui uma máquina virtual num Mac com Apple
silicon, o arquivo é `awscli-exe-linux-aarch64-2.37.4.zip`.

## O moto, num ambiente virtual

Um ambiente virtual é um diretório com a sua própria cópia do instalador de pacotes do Python, então o
que vai nele não toca mais nada da máquina. O moto vai para um em `~/aws/venv`, fixado na versão com
que as aulas foram gravadas. O `[server]` pede as partes que deixam o moto responder pela rede, e não
só dentro de um programa Python:

```sh
python3 -m venv ~/aws/venv
~/aws/venv/bin/pip install -q 'moto[server]==5.2.3'
```

## Um arquivo que aponta tudo para o moto

A linha de comando da AWS decide para onde vai uma requisição, e com quais credenciais, a partir de
algumas variáveis de ambiente. Um arquivo curto define todas, e toda aula começa lendo ele:

```sh
cat > ~/aws/env.sh <<'EOF'
# The lab for the AWS courses and cloud-security. Read it into every terminal: source ~/aws/env.sh
export PATH="$HOME/.local/bin:$PATH"
. "$HOME/aws/venv/bin/activate"
export AWS_ENDPOINT_URL=http://localhost:4567
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=sa-east-1
export AWS_PAGER=
export MOTO_IAM_LOAD_MANAGED_POLICIES=true
cd "$HOME/aws"
EOF
```

Linha por linha, depois do comentário:

| linha | o que faz |
|---|---|
| `PATH` | põe `~/.local/bin`, onde está o `aws`, no caminho |
| `activate` | entra no ambiente virtual, o que põe o `moto_server` no caminho |
| `AWS_ENDPOINT_URL` | **manda toda requisição para o moto, na porta 4567 deste computador, em vez de para a AWS** |
| `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` | as credenciais de mentira do moto, `test` e `test` |
| `AWS_DEFAULT_REGION` | `sa-east-1`, São Paulo, a região em que toda aula trabalha |
| `AWS_PAGER` | imprime respostas longas direto no terminal, em vez de abrir um paginador |
| `MOTO_IAM_LOAD_MANAGED_POLICIES` | dá ao moto as políticas de permissão que a própria AWS mantém, como a `AdministratorAccess` |

**Os dois valores `test` são a primeira decisão de segurança do curso.** O moto os aceita e a AWS os
recusa, então uma requisição que escape para a AWS por engano falha em vez de fazer alguma coisa.
**Nunca ponha uma chave real neste arquivo**, nem em nenhum arquivo que o curso pedir para criar: um
arquivo no seu diretório pessoal é copiado para backups, pastas compartilhadas e capturas de tela sem
ninguém decidir isso, e a aula 7 trata do que acontece depois.

## Toda vez que abrir um terminal

Uma linha, em cada um dos dois terminais:

```sh
source ~/aws/env.sh
```

O seu prompt ganha `(venv)` na frente; as transcrições o omitem.

No **primeiro terminal**, inicie o moto na porta 4567. Ele ocupa esse terminal enquanto roda, e é
essa a ideia, já que as requisições aparecem ali conforme chegam:

```sh
moto_server -p 4567
```

No **segundo terminal**, confira que cada ferramenta responde e mande ao moto a primeira requisição:

```
ana@laptop:~/aws$ aws --version
aws-cli/2.37.4 Python/3.14.6 Linux/6.18.44-fc-v153 exe/x86_64.ubuntu.24
ana@laptop:~/aws$ python3 -c 'import moto; print(moto.__version__)'
5.2.3
ana@laptop:~/aws$ aws sts get-caller-identity
{
    "UserId": "AKIAIOSFODNN7EXAMPLE",
    "Account": "123456789012",
    "Arn": "arn:aws:sts::123456789012:user/moto"
}
ana@laptop:~/aws$ cd ~ && du -sh aws .local/aws-cli
302M	aws
273M	.local/aws-cli
```

`aws sts get-caller-identity` faz a única pergunta que todo conjunto de credenciais da AWS sabe
responder: **quem sou eu?** Contra a AWS, ela nomeia a conta e o usuário ou papel por trás da chave.
Contra o moto, nomeia a conta padrão do moto, `123456789012`, e um usuário chamado `moto`, já que o
moto aceita qualquer chave até a aula 6 ligar a verificação. As duas últimas linhas são o que o
laboratório custa ao seu disco.

No primeiro terminal, o moto imprimiu uma linha quando a requisição chegou:

```
ana@laptop:~/aws$ moto_server -p 4567
WARNING: This is a development server. Do not use it in a production deployment. Use a production WSGI server instead.
 * Running on http://127.0.0.1:4567
Press CTRL+C to quit
127.0.0.1 - - [23/Oct/2026 00:29:59] "POST / HTTP/1.1" 200 -
```

**Um `POST` para `/` respondido com `200` é uma chamada de API**, e `127.0.0.1` é de onde ela veio.
Quando terminar uma sessão, pare o moto com **Ctrl+C** no terminal dele. A próxima aula o inicia de
novo, vazio.
