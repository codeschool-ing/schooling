---
title: O seu laboratório, em resumo
version: 1
---

**Este curso é praticado contra o moto, uma imitação de código aberto da API da AWS, com a linha de
comando real da AWS e sem conta na AWS.** Todo comando dele roda no seu próprio computador, não
custa nada e não chega a ninguém. Os quatro cursos de AWS desta escola compartilham um ambiente, e
o `aws-foundations` o constrói na lição 1, com cada caminho explicado e uma seção sobre o que dá
errado. Se você fez aquele curso e guardou o laboratório, pule para a verificação no fim desta
seção. Se não, os passos estão abaixo, em resumo, e constroem exatamente a mesma coisa.

## O que o moto é, e o que ele não é

O moto é um programa Python que escuta numa porta do seu computador e responde do jeito que a AWS
responde. Peça a ele para lançar uma instância e ele devolve um id de instância, um estado e uma
Availability Zone, no mesmo JSON que o serviço real devolve. **O que ele não faz é rodar nada.** Não
há máquina atrás daquele id, nem disco atrás de um volume, nem contêiner atrás de uma task do ECS:
cada um é um registro que o moto guarda na memória e esquece quando para.

Isso faz dele a ferramenta certa para a maior parte deste curso, que é sobre a forma das coisas: o
que um launch template guarda, como um grupo decide quantas instâncias manter, o que uma task
definition diz. E faz dele a ferramenta errada para três coisas, e as lições dizem isso a cada vez:

- **O moto impõe muito menos que a AWS.** Por padrão ele nem avalia políticas de IAM, então uma
  chamada que uma política deveria negar dá certo. Ele aceita limites que a AWS recusaria e pula
  verificações que a AWS faz.
- **Nada do que ele informa é uma medição.** Um preço spot, um número de CPU ou um tempo vindo do
  moto é um marcador de lugar. Todo preço deste curso vem da lista de preços publicada pela AWS,
  lida por um programa que a próxima seção mostra inteiro.
- **Alguns serviços não estão lá.** O App Runner é o que este curso precisa, e a lição 22 o ensina a
  partir da documentação da AWS e diz isso.

Onde uma lição precisa que o código rode de verdade, como no Lambda a partir da lição 14, ela o roda
no seu computador com o runtime que a AWS publica, e aquela lição mostra como.

## Três jeitos de ter o laboratório

**Recomendado: instalar no Ubuntu 24.04**, no seu computador ou numa máquina virtual que você já
tenha. Precisa de uns 700 MB de disco e de mais nada rodando. Uma **máquina virtual** (VirtualBox, ou
Multipass no Windows e no macOS) custa alguns gigabytes de disco e 2 GB de memória enquanto roda, e
lhe dá um Ubuntu limpo para quebrar. Um **ambiente online** como o GitHub Codespaces não precisa de
instalação e lhe dá um terminal no navegador, ao preço de uma cota mensal de horas que vale conferir
antes de depender dela. A lição 1 do `aws-foundations` percorre os três; os comandos abaixo são os
mesmos em cada um.

## Os comandos

Os pacotes vêm do arquivo do próprio Ubuntu, e este é o único passo que precisa de `sudo`:

```sh
sudo apt-get update
sudo apt-get install -y python3 python3-venv curl unzip jq
```

A linha de comando da AWS, versão 2.37.4, instalada no seu diretório pessoal. Num processador Arm, o
que inclui uma máquina virtual num Mac com Apple silicon, o nome do arquivo termina em `aarch64` em
vez de `x86_64`:

```sh
mkdir -p ~/aws ~/.local/bin
cd ~/aws
curl -sS -o awscliv2.zip https://awscli.amazonaws.com/awscli-exe-linux-x86_64-2.37.4.zip
unzip -q awscliv2.zip
./aws/install -i ~/.local/aws-cli -b ~/.local/bin
rm -rf aws awscliv2.zip
```

O moto, num ambiente virtual só dele, para não mexer em mais nada da máquina:

```sh
python3 -m venv ~/aws/venv
~/aws/venv/bin/pip install -q 'moto[server]==5.2.3'
```

**Toda vez que você abrir um terminal para trabalhar**, estas linhas vêm primeiro. Elas põem as duas
ferramentas no seu path, apontam a linha de comando para o moto em vez da AWS, dão a ela as duas
palavras que o moto aceita como credenciais e escolhem São Paulo como região:

```sh
cd ~/aws
source venv/bin/activate
export PATH="$HOME/.local/bin:$PATH"
export AWS_ENDPOINT_URL=http://localhost:4567
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=sa-east-1 AWS_PAGER=
```

`AWS_PAGER=` impede a linha de comando de abrir respostas longas num paginador, então o que você vê é
o que as lições mostram. O seu prompt ganha `(venv)` na frente; as transcrições o deixam de fora.

E o próprio moto roda **num terminal só dele**, que você deixa aberto enquanto trabalha:

```sh
~/aws/venv/bin/moto_server -p 4567
```

Ele imprime uma linha dizendo que está rodando em `http://127.0.0.1:4567` e fica esperando. Pará-lo
com Ctrl+C o esvazia, e isso é uma vantagem: **toda lição começa de um moto vazio**, e as transcrições
foram gravadas assim.

## Verificando que ele responde

No seu terminal de trabalho:

```
ana@laptop:~/aws$ aws --version
aws-cli/2.37.4 Python/3.14.6 Linux/6.18.44-fc-v139 exe/x86_64.ubuntu.24
ana@laptop:~/aws$ aws sts get-caller-identity
{
    "UserId": "AKIAIOSFODNN7EXAMPLE",
    "Account": "123456789012",
    "Arn": "arn:aws:sts::123456789012:user/moto"
}
```

**`123456789012` é a conta do moto**, aquela a que pertence todo recurso deste curso, e
`AKIAIOSFODNN7EXAMPLE` é a chave de exemplo da própria documentação da AWS, que nenhuma conta real
tem. A parte `Linux/` mostra o seu próprio kernel e vai ser diferente.

## Quando ele não responde

Três falhas cobrem quase tudo. **O moto não está rodando**, ou está rodando num terminal que você
fechou:

```
ana@laptop:~/aws$ aws sts get-caller-identity

aws: [ERROR]: Could not connect to the endpoint URL: "http://localhost:4567/"
```

Inicie-o de novo num terminal só dele. **A porta está ocupada**, porque já há um `moto_server`
rodando em algum lugar, e o novo para na hora:

```
ana@laptop:~/aws$ ~/aws/venv/bin/moto_server -p 4567
Address already in use
Port 4567 is in use by another program. Either identify and stop that program, or start the server with a different port.
```

O outro provavelmente está num terminal esquecido; `ss -ltnp | grep 4567` mostra o processo.

E a terceira é a que vale entender. **A linha do endpoint não foi digitada neste terminal**, então a
linha de comando foi para a AWS real, que não conhece a palavra `test`:

```
ana@laptop:~/aws$ aws sts get-caller-identity

aws: [ERROR]: An error occurred (InvalidClientTokenId) when calling the GetCallerIdentity operation: The security token included in the request is invalid.
```

Essa recusa é da AWS, não do moto, e é inofensiva: nada foi criado e nada foi cobrado. É também o
motivo de **você nunca dar uma chave real a esta linha de comando durante o curso**. Todo comando aqui
é escrito para o moto, e a única linha entre ele e uma conta real é uma variável de ambiente que um
terminal novo esquece.
