---
title: Instalando as ferramentas
version: 1
---

Tudo a seguir roda num terminal no Ubuntu 24.04, como o seu próprio usuário, e só o primeiro bloco
pede `sudo`. **Todo o resto vai para dois lugares: o diretório `~/cloud`, onde você trabalha pelo
resto do curso, e o `~/.local`, onde fica a linha de comando da AWS.** Apagar esses dois, e o
`~/.cache/cloud-prices` depois que a próxima seção o encher, remove o laboratório por completo.

## Os pacotes do Ubuntu

Python, `curl` e `jq` vêm do repositório do próprio Ubuntu, com `unzip` e `git` para buscar as duas
ferramentas que não vêm de lá:

```sh
sudo apt-get update
sudo apt-get install -y python3 python3-venv curl jq unzip git
```

**O `python3-venv` é o que as pessoas esquecem**, porque o Ubuntu vem com o Python sem ele. Sem ele o
ambiente virtual do terceiro bloco falha, e a seção sobre falhas mostra a mensagem.

## A linha de comando da AWS

A AWS publica a sua linha de comando como um arquivo zip com um instalador dentro. Estes comandos
baixam uma versão fixa, a mesma com que todas as transcrições deste curso foram gravadas, e a
instalam na sua pasta pessoal, então ela não pede `sudo`:

```sh
mkdir -p ~/cloud ~/.local/bin
cd ~/cloud
curl -sS -o awscliv2.zip https://awscli.amazonaws.com/awscli-exe-linux-x86_64-2.37.4.zip
unzip -q awscliv2.zip
./aws/install -i ~/.local/aws-cli -b ~/.local/bin
rm -rf aws awscliv2.zip
```

Uma versão mais nova serve para tudo o que este curso faz. A linha de versão e o texto de algumas
mensagens de erro vão diferir das aulas, e nada mais. Num computador com processador Arm, o que
inclui uma máquina virtual num Mac com Apple silicon, o arquivo é
`awscli-exe-linux-aarch64-2.37.4.zip`.

**Você nunca vai dar uma chave a esta linha de comando.** Ela é usada no que consegue fazer sem
nenhuma: imprimir o formato de um pedido, conferir um arquivo, recusar uma chamada que não consegue
assinar, e conversar com a imitação do S3 que a aula 5 sobe.

## Duas ferramentas em Python, num ambiente virtual

Um ambiente virtual é um diretório com a sua própria cópia do instalador de pacotes do Python, então
o que você instala ali não mexe em mais nada da máquina. Duas ferramentas vão neste. O **moto** imita
a interface do S3 para a aula 5, e os pacotes de que o **cloud-init** precisa para conferir uma
configuração de inicialização na aula 4. O cloud-init em si não é publicado no PyPI, então ele vem do
próprio código-fonte, na versão 26.2, com um script de três linhas que o roda:

```sh
python3 -m venv ~/cloud/venv
git clone -q --depth 1 --branch 26.2 https://github.com/canonical/cloud-init ~/cloud/cloud-init
~/cloud/venv/bin/pip install -q 'moto[server]==5.2.3' -r ~/cloud/cloud-init/requirements.txt
cat > ~/.local/bin/cloud-init <<'EOF'
#!/bin/sh
PYTHONPATH="$HOME/cloud/cloud-init" exec "$HOME/cloud/venv/bin/python3" -m cloudinit.cmd.main "$@"
EOF
chmod +x ~/.local/bin/cloud-init
```

O script põe em `PYTHONPATH` o diretório do código-fonte, para que o Python encontre ali o código do
cloud-init, e o inicia com o Python do ambiente, que tem os pacotes de que o cloud-init depende.

## Toda vez que você abrir um terminal

Duas linhas põem as ferramentas no seu caminho, e toda aula supõe que você as digitou:

```sh
cd ~/cloud
export PATH="$HOME/.local/bin:$PATH" && source venv/bin/activate
```

A primeira é onde ficam os arquivos do curso. A segunda acrescenta o `~/.local/bin`, onde estão
`aws` e `cloud-init`, e entra no ambiente virtual, o que põe o `moto_server` no caminho e faz do
`python3` o do próprio ambiente. O seu prompt ganha `(venv)` na frente; as transcrições das aulas o
deixam de fora.

Depois confira se cada ferramenta responde:

```
ana@laptop:~/cloud$ aws --version
aws-cli/2.37.4 Python/3.14.6 Linux/6.18.44-fc-v77 exe/x86_64.ubuntu.24
ana@laptop:~/cloud$ jq --version
jq-1.7
ana@laptop:~/cloud$ python3 --version
Python 3.12.3
ana@laptop:~/cloud$ moto_server --help | head -1
usage: moto_server [-h] [-H HOST] [-p PORT] [-r] [-s] [-c SSL_CERT]
ana@laptop:~/cloud$ cloud-init schema --help | head -1
usage: /home/ana/cloud/cloud-init/cloudinit/cmd/main.py schema
ana@laptop:~/cloud$ du -sh ~/cloud ~/.local/aws-cli
319M	/home/ana/cloud
273M	/home/ana/.local/aws-cli
```

**O `aws` traz o seu próprio Python**, 3.14.6, dentro dos 273 MB que instalou, e é por isso que a
linha de versão dele cita outro, diferente do 3.12.3 do Ubuntu. **Uns 600 MB de disco é o custo até
aqui.** A próxima seção acrescenta a lista de preços, que é maior.
