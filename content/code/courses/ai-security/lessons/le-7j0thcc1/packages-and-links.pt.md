---
title: Nomes que ainda não existem
version: 2
---

O jeito mais direto de uma alucinação virar ataque é por um nome. Um modelo a quem se pede código sugere
um pacote para instalar, e às vezes o pacote que ele nomeia nunca foi publicado. A sugestão parece
exatamente uma real. **Um nome que ninguém possui é um nome que qualquer um pode registrar**, e se um
modelo sugere sempre o mesmo nome inventado, quem registrá-lo primeiro decide o que o próximo
desenvolvedor que confiar na sugestão vai instalar. Pesquisadores mediram modelos inventando nomes de
pacotes numa taxa perceptível, e o truque de registrá-los ganhou um apelido próprio, *slopsquatting*.

A defesa é a mesma dos links da aula 9: **um nome que um modelo produziu é conferido contra uma lista
confiável antes de qualquer coisa agir sobre ele.** Dois arquivos, ambos escritos pelo curso: os pacotes
que um modelo poderia sugerir para um recurso de QR code Pix, e um substituto curto dos pacotes que a
Tarefa já revisou:

```sh
cat > ~/guard/data/suggested-deps.txt <<'EOF'
requests
python-dateutil
pix-qrcode-br
qrcode
brazil-cpf-validator-pro
EOF
cat > ~/guard/data/registry-snapshot.txt <<'EOF'
django
fastjsonschema
flask
httpx
numpy
pandas
pillow
pydantic
python-dateutil
qrcode
requests
validate-docbr
EOF
```

A verificação é uma consulta num conjunto. Salve-a como `~/guard/tools/deps.py`:

```python
# deps.py: suggested packages against the list Tarefa has already reviewed.
#
#   guard deps FILE
#
# FILE has package names, one or more per line; a leading `pip install` is
# ignored, so a model's reply can be checked as it came. Every name not in
# data/registry-snapshot.txt is printed as one not to install, and the exit
# status is 1 if there is any.
import os
import sys

with open(os.path.expanduser("~/guard/data/registry-snapshot.txt")) as f:
    reviewed = {line.strip().lower() for line in f if line.strip()}

names = []
with open(sys.argv[1]) as f:
    for line in f:
        words = line.split()
        if words[:2] == ["pip", "install"]:
            words = words[2:]
        names += words

missing = 0
for name in names:
    known = name.lower() in reviewed
    missing += not known
    print("%-26s %s" % (name, "in the snapshot" if known
                        else "NOT IN THE SNAPSHOT: do not install"))
sys.exit(1 if missing else 0)
```

```
ana@lab:~/guard$ cat data/suggested-deps.txt
requests
python-dateutil
pix-qrcode-br
qrcode
brazil-cpf-validator-pro
ana@lab:~/guard$ guard deps data/suggested-deps.txt; echo "exit $?"
requests                   in the snapshot
python-dateutil            in the snapshot
pix-qrcode-br              NOT IN THE SNAPSHOT: do not install
qrcode                     in the snapshot
brazil-cpf-validator-pro   NOT IN THE SNAPSHOT: do not install
exit 1
```

Dois nomes não estão no snapshot. A verificação não diz se eles existem no índice público, porque essa
não é a pergunta que protege a Tarefa: um nome que existe não é por isso o pacote que o modelo quis
dizer, e o resultado seguro é o mesmo nos dois casos. **Uma pessoa procura o pacote**, lê quem o
publica, há quanto tempo existe e quão usado é, e o acrescenta à lista revisada ou não o instala.

## O que o modelo sugeriu de fato

A lista acima foi escrita para mostrar a verificação. Faça ao modelo de verdade o mesmo tipo de
pergunta, e guarde a resposta como veio:

```
ana@lab:~/guard$ guard ask "Which Python packages would I install to generate a Pix QR code for a Brazilian payment, and to validate a CPF? Reply with package names only, one per line, nothing else." > data/model-deps.txt
ana@lab:~/guard$ cat data/model-deps.txt
pip install qrcode
pip install pyzbar
pip install python-cpf
ana@lab:~/guard$ guard deps data/model-deps.txt; echo "exit $?"
qrcode                     in the snapshot
pyzbar                     NOT IN THE SNAPSHOT: do not install
python-cpf                 NOT IN THE SNAPSHOT: do not install
exit 1
ana@lab:~/guard$ guard ask "Which Python packages would I install to generate a Pix QR code for a Brazilian payment, and to validate a CPF? Reply with package names only, one per line, nothing else." --temperature 0.8 --seed 2
pip install python-qrcode
pip install py-cpf
```

Pediu-se a ele só os nomes, e ele respondeu com comandos de instalação; é por isso que o `deps.py`
ignora um `pip install` no começo: uma verificação que lê a saída de um modelo tem de lê-la como ela
vem, não como foi pedida. O `qrcode` é um pacote real, e a Tarefa o revisou. O `pyzbar` e o
`python-cpf` não estão na lista revisada, e a verificação os barra ali. Se existe hoje um pacote com
cada nome no índice público, e quem o publicou, é exatamente o que a pessoa que o revisar vai
descobrir. (O `pyzbar` lê QR codes em vez de gerá-los, o que é uma segunda pergunta para a mesma
pessoa.)

O modelo deu os três nomes com a mesma confiança, e esse é o problema inteiro: nada na resposta marca
qual nome é qual. A última execução, com temperatura 0.8, nomeou outros dois pacotes, nenhum deles na
lista revisada. Uma lista do que uma execução sugeriu não substitui conferir toda execução.

Três hábitos fazem isso valer numa equipe:

- **Instalar a partir da lista revisada, com versões fixadas e hashes conferidos**, para que um nome novo
  exija uma decisão e um nome conhecido não mude por baixo de você.
- **Tratar um nome de pacote no código de um modelo como entrada não confiável**, igual a uma URL na
  resposta dele.
- **Ficar atento ao mesmo nome inventado se repetindo.** Uma sugestão errada uma vez é ruído; uma errada
  do mesmo jeito para muitos desenvolvedores é o nome que alguém vai registrar.

## Links também são nomes

O `out-6` da aula 9 tinha um link para `pay-tarefa.example`, um host que parecia o da Tarefa. Um modelo
que inventa um link plausível produz o mesmo risco que um que inventa um pacote: um nome que outra pessoa
pode possuir. A lista de hosts da aula 9 é a mesma defesa que o snapshot de registro daqui, uma para o
navegador do cliente e outra para a máquina de quem desenvolve.
