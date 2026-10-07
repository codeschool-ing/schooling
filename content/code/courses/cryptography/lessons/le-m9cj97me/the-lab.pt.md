---
title: Seu laboratório, e três jeitos de montá-lo
version: 1
---

**Toda aula deste curso é executada, e você deve executá-la também.** Ler que um byte alterado faz
o GCM recusar um arquivo é uma coisa; alterar o byte você mesmo e ver a recusa é o que fixa a
ideia. Nada aqui roda numa máquina nossa. Você monta o laboratório no seu próprio computador, e
esta seção o monta.

O laboratório é uma máquina Linux com três coisas:

- **a linha de comando do OpenSSL**, que a maioria das transcrições usa e que todo Linux já tem;
- **Python 3 com duas bibliotecas**, `cryptography` e `bcrypt`, num ambiente virtual só dele, para
  o que a linha de comando não mostra;
- **`~/lab`**, um diretório de chaves, dados e programas pequenos. Os programas respondem a um
  comando, `vcrypt`, e você digita cada linha deles: cada um aparece inteiro na aula que o usa
  primeiro, então nada neste curso roda sem que você tenha lido.

Algumas aulas mais adiante instalam um pacote ou dois por conta própria: OpenSSH e um servidor LDAP
na aula 12, as ferramentas de DNSSEC do BIND na aula 13, `cryptsetup` e PostgreSQL na aula 14,
`wpa_supplicant` na aula 15, FreeRADIUS na aula 16. Cada uma avisa no ponto em que precisa.

## Três jeitos de ter um

| | o que é | o que custa ao seu computador |
|---|---|---|
| **uma máquina virtual** (recomendado) | Ubuntu Server 24.04 LTS num hypervisor | 2 GB de memória enquanto roda, uns 10 GB de disco |
| instalado | os mesmos pacotes num computador que já roda Ubuntu 24.04 | menos de 50 MB nas primeiras aulas, e os servidores das aulas 12, 14 e 16 instalados de vez |
| online | uma máquina pequena com Ubuntu 24.04 alugada de um provedor de nuvem | nada no seu computador; dinheiro, por hora |

**A máquina virtual é o caminho recomendado**, e o motivo são as aulas 12 a 16. Elas sobem um
servidor SSH, um diretório LDAP, um banco de dados e dois servidores RADIUS, criam um usuário
chamado `ana` e colocam nomes no `/etc/hosts`: o tipo de mudança que você não quer no computador em
que trabalha. Numa máquina virtual um erro custa um snapshot, e quando o curso acabar você a apaga.

Qualquer hypervisor serve: VirtualBox no Windows ou no Linux, UTM num Mac com processador da Apple,
Hyper-V no Windows Pro, GNOME Boxes no Linux. Baixe o instalador do Ubuntu Server 24.04 LTS em
ubuntu.com, crie uma máquina com 2 GB de memória e um disco de 10 GB, inicie pelo instalador e
aceite os padrões. Quando o instalador pedir um nome, chame a máquina de `lab` se quiser: toda
transcrição aqui mostra `ana@lab`, onde `ana` é a pessoa e `lab` a máquina, e a sua vai mostrar os
seus. A criação da máquina não foi gravada para este curso; tudo a partir do primeiro `apt-get`
abaixo foi.

**Instalado** serve num computador que já roda Ubuntu 24.04, com os mesmos comandos. No Windows, o
WSL com Ubuntu 24.04 também dá os mesmos comandos, e as aulas 1 a 11 não precisam de mais nada. No
macOS os comandos do OpenSSL e do Python existem, mas `sha256sum`, `date` e `apt-get` não se
comportam igual, e as aulas de servidores não vão funcionar como impresso. Nenhum dos dois foi
executado aqui.

**Online**, a menor máquina com Ubuntu 24.04 de qualquer provedor basta, e alguns provedores têm uma
cota gratuita. Esse caminho não foi executado para este curso, e nenhuma aula depende dos termos de
uma empresa. Uma máquina na internet é encontrada por varreduras em minutos, então mantenha o
firewall dela fechado, exceto para o SSH.

## Os pacotes e o Python

Tudo daqui em diante é digitado num terminal da máquina que você escolheu. Primeiro os programas,
do próprio repositório do Ubuntu:

```sh
sudo apt-get update
sudo apt-get install -y openssl xxd python3-venv
```

Depois o diretório do laboratório, e um **ambiente virtual** dentro dele: um Python próprio, em
`~/lab/venv`, com as próprias bibliotecas, para que nada aqui mexa no Python de que o próprio Ubuntu
depende. As versões são fixas, porque outra versão poderia imprimir algo diferente das transcrições.
O último comando acrescenta três linhas ao `~/.bashrc`, para que todo terminal novo encontre o
`vcrypt` e esse Python sem que ninguém precise dizer:

```sh
mkdir -p ~/lab/bin ~/lab/tools ~/lab/keys ~/lab/data
python3 -m venv ~/lab/venv
~/lab/venv/bin/pip install cryptography==50.0.2 bcrypt==5.0.0
cat >> ~/.bashrc <<'EOF'
# cryptography course
export PATH="$HOME/lab/bin:$PATH"
source "$HOME/lab/venv/bin/activate"
EOF
```

Feche o terminal e abra outro, ou digite `source ~/.bashrc`, para que essas linhas passem a valer.

## O `vcrypt` e os dois primeiros programas

O `vcrypt` não é um programa que se instala. São cinco linhas de shell que rodam um arquivo Python:
`vcrypt seal ...` roda `~/lab/tools/seal.py` com o Python do laboratório. Cada aula acrescenta a
`~/lab/tools` os arquivos de que precisa, então na aula 17 são uns vinte, todos mostrados.

Para criar um arquivo, abra-o num editor, cole o bloco inteiro e salve: `nano ~/lab/bin/vcrypt`,
cole, depois `Ctrl+O` e `Enter` para salvar e `Ctrl+X` para sair. A primeira linha de cada bloco é
o caminho do arquivo, como comentário.

```sh
#!/usr/bin/env bash
# ~/lab/bin/vcrypt
# vcrypt NAME ARGS... runs ~/lab/tools/NAME.py with the lab's own Python.
lab=$(cd "$(dirname "$0")/.." && pwd)
name=${1:?usage: vcrypt NAME [ARGS...]}
shift
exec "$lab/venv/bin/python" "$lab/tools/$name.py" "$@"
```

O próximo arquivo é de onde vem cada chave do laboratório, e ele **trapaceia de propósito**. Uma
chave de verdade são bytes aleatórios do sistema operacional, diferentes a cada vez. Assim as suas
chaves seriam diferentes das impressas aqui, e também cada texto cifrado, cada assinatura e cada
certificado de dezessete aulas. Então o laboratório deriva cada chave de um rótulo público, e as
suas saem idênticas às da aula. Qualquer um que leia este arquivo reconstrói todas as chaves do
laboratório, o que as torna inúteis como segredo. A aula 17 mostra como esse mesmo erro aparece em
código de verdade.

```py
# ~/lab/tools/drbg.py
"""Bytes that look random and are not: every key in ~/lab comes from here.

stream(label, n) is HMAC-SHA256 of the label under a seed printed below, so
the same label gives the same bytes on every machine, and your keys are the
keys in the lessons. That is what a course needs and exactly what a real key
must never have: anybody who reads this file can rebuild every key in the
lab. Lesson 17 says why. No key from here belongs anywhere but ~/lab.
"""
import hashlib
import hmac

SEED = b"cryptography course lab, not a secret"


def stream(label: str, n: int) -> bytes:
    out, counter = b"", 0
    while len(out) < n:
        out += hmac.new(SEED, label.encode() + counter.to_bytes(4, "big"), hashlib.sha256).digest()
        counter += 1
    return out[:n]


def integer(label: str, bits: int) -> int:
    return int.from_bytes(stream(label, (bits + 7) // 8), "big") >> ((-bits) % 8)
```

O HMAC dentro dele é o assunto da aula 6; por enquanto, é uma máquina que transforma um rótulo em
bytes. O segundo programa mostra esses bytes:

```py
# ~/lab/tools/derive.py
"""vcrypt derive LABEL N: N bytes from drbg.py, as hex on one line.
With --raw, the bytes themselves, for a file that stands in for data."""
import sys

import drbg

raw = "--raw" in sys.argv
label, n = [a for a in sys.argv[1:] if a != "--raw"]
data = drbg.stream(label, int(n))
if raw:
    sys.stdout.buffer.write(data)
else:
    print(data.hex())
```

## As chaves e os dados desta aula

Quatro chaves: duas chaves AES-256 de 32 bytes e dois vetores de inicialização de 16 bytes, que a
seção 07 explica. Depois uma carta de encaminhamento e o arquivo de agendamentos de segunda: 32
horários de quinze minutos das 08:00 às 16:45, pulando o almoço, cada um num registro de exatamente
dezesseis bytes, e a seção 05 diz por quê.

```sh
cd ~/lab
chmod +x bin/vcrypt
vcrypt derive aes-256 32 > keys/aes-256.hex
vcrypt derive aes-256-b 32 > keys/aes-256-b.hex
vcrypt derive iv-a 16 > keys/iv-a.hex
vcrypt derive iv-b 16 > keys/iv-b.hex
cat > data/referral.txt <<'EOF'
Referral 2026-0417. Patient: Marina Duarte, 41.
Lower back pain after lifting, eight weeks. Eight sessions of physiotherapy.
Dr. Paulo Nogueira, CRM-SP 000000 (invented)
EOF
for h in 08 09 10 11 13 14 15 16; do
  for m in 00 15 30 45; do
    case $h$m in
      0815|0900|0930|1000|1100|1330|1345|1500|1600|1630) printf 'room1 BOOKED   \n' ;;
      *) printf 'room1 free     \n' ;;
    esac
  done
done > data/slots.dat
```

O `chmod +x` faz do `vcrypt` algo que o shell consegue executar. A Vereda, seus pacientes e seu
médico são inventados, e todo nome deste curso também.

## Conferindo

Num terminal novo, as versões devem ser estas:

```
ana@lab:~$ openssl version
OpenSSL 3.0.13 30 Jan 2024 (Library: OpenSSL 3.0.13 30 Jan 2024)
ana@lab:~$ python3 --version
Python 3.12.3
ana@lab:~$ python3 -c 'import cryptography, bcrypt; print(cryptography.__version__, bcrypt.__version__)'
50.0.2 5.0.0
```

O `python3` é o 3.12 e encontra as duas bibliotecas porque a linha no `~/.bashrc` pôs o Python do
laboratório na frente. E os arquivos devem ter exatamente estes bytes. Um resumo SHA-256, assunto
da aula 4, muda por completo se um único byte do arquivo mudar, então comparar os primeiros
caracteres de cada linha basta:

```
ana@lab:~$ cd ~/lab
ana@lab:~/lab$ sha256sum keys/* data/*
e3c71c1722537cedf7d918f3a3d2ccb44c1ab732f98a679debbacfe6498d4c28  keys/aes-256-b.hex
50ca6e257529c4a3daaf38397347d105c4a618599cb53106d7c0c165485506e8  keys/aes-256.hex
afa184b52da6b03f4a26305a8e5adb1301a24c5c5436ac664e9ff8033141c32e  keys/iv-a.hex
467a7750f8816d8e9820633cecaac16e0ef07479c5d1f1331af4059f4298a409  keys/iv-b.hex
7c55ba550e02c3e33d50f2e4627f5e855b6cc9692e91eb72d15e5905f32abc4c  data/referral.txt
5e832af18cbeab6bd7bb6d2931668e0296498d2e5837980aee5e5d49ae3f8750  data/slots.dat
```

Tudo isso, as bibliotecas do Python incluídas, ocupa este espaço em disco:

```
ana@lab:~/lab$ du -sh ~/lab
34M	/home/ana/lab
```

Quase tudo é o ambiente virtual; as chaves e os dados são poucos kilobytes.

Se uma linha for diferente, ou um comando não fizer o que esta seção diz, a próxima seção é para
você.
