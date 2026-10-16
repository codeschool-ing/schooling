---
title: O seu laboratório, em resumo
version: 1
---

**Este curso é praticado contra o moto, no seu próprio computador, com a linha de comando de verdade
da AWS e sem conta na AWS.** É o mesmo ambiente dos quatro cursos de AWS, e a lição 1 do
`aws-foundations` o monta passo a passo, com os três jeitos de tê-lo e uma seção sobre o que dá
errado. Se você fez essa lição e guardou o laboratório, pule para "Toda vez que abrir um terminal",
mais abaixo. Se não fez, ou apagou, os passos estão aqui em resumo. A plataforma não roda nada por
você: nem máquina, nem shell no navegador, nem conta.

**Todas as transcrições foram gravadas no Ubuntu 24.04**, e há três jeitos de tê-lo. Instalado é o
recomendado, como o seu sistema ou dentro do WSL no Windows (`wsl --install -d Ubuntu-24.04` num
PowerShell de administrador). Uma máquina virtual é o caminho num Mac: Ubuntu Server 24.04 no UTM, no
VirtualBox ou no Multipass, com 2 processadores, 4 GB de memória e 15 GB de disco. Um shell online
alugado por hora também serve, porque nada aqui precisa de mais que um terminal com rede, mas
nenhuma lição depende da cota grátis de empresa nenhuma. No seu disco o laboratório inteiro dá uns
800 MB, e nada nele roda se você não o ligar.

## Os pacotes do Ubuntu

```sh
sudo apt-get update
sudo apt-get install -y python3 python3-venv curl unzip jq
```

## A linha de comando da AWS

A versão 2.37.4, na sua pasta pessoal, para não precisar de `sudo`:

```sh
mkdir -p ~/aws ~/.local/bin
cd ~/aws
curl -sS -o awscliv2.zip https://awscli.amazonaws.com/awscli-exe-linux-x86_64-2.37.4.zip
unzip -q awscliv2.zip
./aws/install -i ~/.local/aws-cli -b ~/.local/bin
rm -rf aws awscliv2.zip
```

Num processador Arm, o que inclui uma máquina virtual num Mac com Apple silicon, o arquivo é
`awscli-exe-linux-aarch64-2.37.4.zip`.

## O moto, num ambiente virtual

```sh
python3 -m venv ~/aws/venv
~/aws/venv/bin/pip install -q 'moto[server]==5.2.3'
```

## Mais dois, para este curso

**Este é o único passo que o `aws-foundations` não tem.** O Athena e o Redshift Spectrum rodam SQL
sobre arquivos no S3, e o moto aceita uma consulta dessas e não roda nada, como mostra a seção depois
da próxima. Então as lições a partir da 15 leem os mesmos arquivos com o **DuckDB**, um motor de banco
de dados que vive dentro de um programa Python, e os escrevem com o **PyArrow**, a biblioteca que lê
e escreve Parquet:

```sh
~/aws/venv/bin/pip install -q duckdb==1.5.6 pyarrow==25.0.1
```

## Dois terminais

**O moto roda num terminal só dele**, e fica em primeiro plano ali, imprimindo uma linha para cada
requisição que responde. Abra um terminal e digite:

```sh
cd ~/aws && source venv/bin/activate
moto_server -p 4567
```

Deixe rodando. `Ctrl+C` o para, e **pará-lo esquece tudo**: cada bucket, tabela e stream que ele
guardava. Cada lição deste curso começa com o moto vazio e monta o que precisa, então você pode
pará-lo no fim de uma sessão de estudo sem perder nada que uma lição não reconstrua.

## Toda vez que abrir um terminal

Num segundo terminal, aquele em que você digita pelo resto do curso:

```sh
cd ~/aws
export PATH="$HOME/.local/bin:$PATH" && source venv/bin/activate
export AWS_ENDPOINT_URL=http://localhost:4567 AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=sa-east-1 AWS_PAGER=
```

A primeira linha é onde ficam os arquivos do curso. A segunda põe o `aws` no caminho e ativa o
ambiente virtual. **A terceira é o truque inteiro**: `AWS_ENDPOINT_URL` manda cada requisição da linha
de comando para o moto em vez da Amazon, e as duas chaves são a palavra `test`, que o moto aceita e a
AWS recusa. A quarta põe você em São Paulo, e o `AWS_PAGER` vazio impede a linha de comando de abrir
uma resposta longa no `less`, o único ajuste aqui que é comodidade e não parte do laboratório
compartilhado.

## Confira que ele responde

```
ana@laptop:~/aws$ aws --version
aws-cli/2.37.4 Python/3.14.6 Linux/6.18.44-fc-v139 exe/x86_64.ubuntu.24
ana@laptop:~/aws$ aws sts get-caller-identity
{
    "UserId": "AKIAIOSFODNN7EXAMPLE",
    "Account": "123456789012",
    "Arn": "arn:aws:sts::123456789012:user/moto"
}
ana@laptop:~/aws$ aws s3 ls
ana@laptop:~/aws$ du -sh ~/aws ~/.local/aws-cli
516M	/home/ana/aws
273M	/home/ana/.local/aws-cli
```

**A conta é `123456789012`, e essa é a prova de que você está falando com o moto**: é o número de
exemplo da própria documentação da AWS, e o moto o dá a toda conta que imita. A resposta vazia de
`aws s3 ls` é um S3 vazio. Se aparecer um número de doze dígitos seu, ou um erro, a próxima seção é a
que você deve ler.
