---
title: Instalando o laboratório
version: 1
---

Tudo abaixo roda num terminal no Ubuntu 24.04, como o seu próprio usuário, e só o primeiro bloco
pede `sudo`. **Todo o resto vai para dois lugares: `~/aws`, onde você trabalha pelo resto do curso,
e `~/.local`, onde fica a linha de comando da AWS.** Apagar os dois, e o `~/.cache/aws-prices`
depois que a última seção desta lição o preencher, remove o laboratório por completo.

Se você fez o curso `cloud` e guardou o laboratório dele, a linha de comando da AWS já está em
`~/.local`, na mesma versão. Se `aws --version` imprime `aws-cli/2.37.4`, você pode pular o
segundo bloco. O moto do curso `cloud` rodava em outra porta e em outro diretório; este é novo.

## Os pacotes do Ubuntu

Python, `curl` e `jq` vêm do próprio repositório do Ubuntu, com o `unzip` para abrir o instalador
da AWS:

```sh
sudo apt-get update
sudo apt-get install -y python3 python3-venv curl jq unzip
```

**O `python3-venv` é o que as pessoas esquecem**, porque o Ubuntu traz o Python sem ele. Sem ele o
terceiro bloco falha, e a seção sobre falhas diz como isso aparece.

## A linha de comando da AWS

A AWS publica a linha de comando como um arquivo zip com um instalador dentro. Estes comandos baixam
uma versão fixa, a mesma com que cada transcrição deste curso foi gravada, e a instalam no seu
diretório pessoal, então não precisam de `sudo`:

```sh
mkdir -p ~/aws ~/.local/bin
cd ~/aws
curl -sS -o awscliv2.zip https://awscli.amazonaws.com/awscli-exe-linux-x86_64-2.37.4.zip
unzip -q awscliv2.zip
./aws/install -i ~/.local/aws-cli -b ~/.local/bin
rm -rf aws awscliv2.zip
```

Uma versão mais nova serve para tudo o que este curso faz; a linha de versão e o texto de algumas
mensagens vão diferir das lições, e nada mais. Num computador com processador Arm, o que inclui uma
máquina virtual num Mac com Apple silicon, o arquivo é `awscli-exe-linux-aarch64-2.37.4.zip`.

## O moto, num ambiente virtual

Um ambiente virtual é um diretório com a sua própria cópia do instalador de pacotes do Python,
então o que você instala ali não toca em mais nada da máquina. O moto vai para um em `~/aws/venv`,
fixado na versão com que as lições foram gravadas. A parte `[server]` pede as peças que deixam o
moto responder pela rede, e não só dentro de um programa Python:

```sh
python3 -m venv ~/aws/venv
~/aws/venv/bin/pip install -q 'moto[server]==5.2.3'
```

## Um arquivo que aponta tudo para o moto

A linha de comando da AWS decide para onde enviar uma requisição, e com quais credenciais, a partir
de um punhado de variáveis de ambiente. Um arquivo curto define todas, e cada lição começa
lendo-o:

```sh
cat > ~/aws/env.sh <<'EOF'
# The AWS courses' lab. Read it into every terminal: source ~/aws/env.sh
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
| `activate` | ativa o ambiente virtual, o que põe o `moto_server` no caminho |
| `AWS_ENDPOINT_URL` | **manda toda requisição ao moto, na porta 4567 deste computador, em vez da AWS** |
| `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` | as credenciais de marcação do moto, `test` e `test`. O moto as aceita e a AWS as recusa, então uma requisição que escape para a AWS por engano falha em vez de fazer alguma coisa |
| `AWS_DEFAULT_REGION` | `sa-east-1`, São Paulo, a região em que todas as lições trabalham |
| `AWS_PAGER` | imprime respostas longas direto no terminal, em vez de abri-las num paginador |
| `MOTO_IAM_LOAD_MANAGED_POLICIES` | faz o moto carregar as políticas de permissão que a própria AWS mantém, que a lição 7 lê |

**Nunca ponha uma chave real neste arquivo**, nem em qualquer arquivo que este curso peça para você
criar. Os dois valores `test` não são segredo; uma chave real é. Um arquivo no seu diretório
pessoal acaba copiado para backups, pastas compartilhadas e capturas de tela sem ninguém decidir isso.

## Toda vez que você abrir um terminal

Uma linha, em cada um dos dois terminais:

```sh
source ~/aws/env.sh
```

O seu prompt ganha `(venv)` na frente; as transcrições das lições o deixam de fora.

No **primeiro terminal**, inicie o moto na porta 4567. Ele ocupa esse terminal enquanto roda, e é
essa a ideia: as requisições aparecem ali à medida que chegam.

```sh
moto_server -p 4567
```

No **segundo terminal**, confira se cada ferramenta responde, e então mande ao moto a primeira
requisição:

```
ana@laptop:~/aws$ aws --version
aws-cli/2.37.4 Python/3.14.6 Linux/6.18.44-fc-v139 exe/x86_64.ubuntu.24
ana@laptop:~/aws$ python3 -c 'import moto; print(moto.__version__)'
5.2.3
ana@laptop:~/aws$ aws sts get-caller-identity
{
    "UserId": "AKIAIOSFODNN7EXAMPLE",
    "Account": "123456789012",
    "Arn": "arn:aws:sts::123456789012:user/moto"
}
ana@laptop:~/aws$ aws configure list
NAME       : VALUE                    : TYPE             : LOCATION
profile    : <not set>                : None             : None
access_key : ****************test     : env              : 
secret_key : ****************test     : env              : 
region     : sa-east-1                : env              : ['AWS_REGION', 'AWS_DEFAULT_REGION']
ana@laptop:~/aws$ cd ~ && du -sh aws .local/aws-cli
301M	aws
273M	.local/aws-cli
ana@laptop:~/aws$ ps -C moto_server -o rss=,comm=
83424 moto_server
```

`aws sts get-caller-identity` faz a pergunta que toda sessão AWS sabe responder: quem sou eu? Na
AWS, ela nomeia a conta e o usuário ou a role por trás das credenciais. No moto, ela nomeia a conta
padrão do moto, `123456789012`, e um usuário chamado `moto`, porque o moto aceita quaisquer
credenciais e as atribui a esse usuário. `aws configure list` diz de onde veio cada configuração, e
o `env` na terceira coluna é este arquivo fazendo o seu trabalho.

No primeiro terminal, o moto imprimiu uma linha quando essa requisição chegou:

```
ana@laptop:~/aws$ moto_server -p 4567
WARNING: This is a development server. Do not use it in a production deployment. Use a production WSGI server instead.
 * Running on http://127.0.0.1:4567
Press CTRL+C to quit
127.0.0.1 - - [16/Oct/2026 12:32:26] "POST / HTTP/1.1" 200 -
```

**Um `POST` para `/` respondido com `200` é uma chamada de API.** Enquanto você mantiver esse
terminal à vista, vê cada requisição que a linha de comando envia. A lição 26 abre uma delas e lê o
que tem dentro.

As últimas linhas do segundo terminal são o custo do laboratório: o disco que as duas instalações
ocupam, e a memória que o moto segura enquanto roda, em kilobytes. Pare o moto com **Ctrl+C** no
terminal dele quando terminar uma sessão; a próxima lição o inicia de novo, vazio.
