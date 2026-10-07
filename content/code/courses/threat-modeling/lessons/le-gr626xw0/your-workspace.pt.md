---
title: O seu ambiente de trabalho
version: 1
---

A maior parte deste curso acontece no papel ou num quadro branco, e isso não é atalho: um modelo de
ameaças é um jeito de pensar sobre um desenho. Uma parte acontece num terminal, porém. A aula 2
escreve o diagrama do portal como código, a aula 3 roda uma ferramenta sobre ele, as aulas 9 a 11
calculam risco com programas curtos em Python, e as aulas 12 e 15 guardam decisões e verificações
num repositório git. **A plataforma não lhe dá máquina nenhuma para isso. Você monta o ambiente,
uma vez, aqui**, e cada aula seguinte diz qual arquivo acrescenta a ele.

O ambiente é pequeno: **Python 3.11 ou mais recente, git e um pacote Python, o `pytm`**, o projeto
da OWASP que descreve os fluxos de dados de um sistema como código Python e lista ameaças para ele.
Não precisa de servidor, de banco de dados nem de conta em lugar nenhum.

### Escolha onde ele roda

| caminho | do que você precisa | quanto custa ao seu computador |
|---|---|---|
| **no seu próprio computador (recomendado)** | Linux ou macOS como estão; no Windows, WSL com Ubuntu | quase nada: uma pasta de uns 60 MB |
| numa máquina virtual | VirtualBox, UTM ou Hyper-V, e uma imagem do Ubuntu 24.04 | 2 GB de memória enquanto roda, 10 GB de disco |
| online | uma conta no GitHub e um Codespace num repositório vazio | nada localmente; as horas gratuitas do mês bastam para este curso |

O primeiro caminho é o recomendado porque nada neste curso precisa de isolamento: não há malware,
não há alvo, nada escuta numa porta. A máquina virtual é para quem usa um computador gerenciado por
um empregador que não permite instalar programas. O caminho online funciona num computador
emprestado e é o mais lento para digitar.

As transcrições deste curso foram gravadas num Ubuntu 24.04, como uma usuária chamada `ana` numa
máquina chamada `vm`. No Ubuntu ou no Debian, os pacotes do sistema vêm primeiro:

```sh
sudo apt install python3 python3-venv git
```

Esse comando não foi rodado na gravação: a máquina já tinha os três. No macOS, o `git` chega com
as ferramentas de linha de comando (`xcode-select --install`), e o Python 3 vem do python.org ou do
Homebrew.

### Monte o ambiente

Confira as duas versões primeiro. O pytm 1.4.0 precisa do Python 3.11 ou mais recente; o Ubuntu
24.04 traz o 3.12, e a máquina da gravação tinha o 3.13.

```
ana@vm:~$ python3 --version
Python 3.13.16
ana@vm:~$ git --version
git version 2.43.0
```

Crie uma pasta para o curso e um **ambiente virtual** dentro dela, para que o pytm e as suas
bibliotecas fiquem em `~/tm/.venv` e em nenhum outro lugar do sistema. Ativar o ambiente muda o
prompt, e é assim que você sabe depois se ele está ativo:

```
ana@vm:~$ mkdir tm
ana@vm:~/tm$ python3 -m venv .venv
ana@vm:~/tm$ . .venv/bin/activate
(.venv) ana@vm:~/tm$ pip install --progress-bar off pytm==1.4.0
Collecting pytm==1.4.0
  Downloading pytm-1.4.0-py3-none-any.whl.metadata (24 kB)
Collecting pydantic<3.0.0,>=2.10.0 (from pytm==1.4.0)
  Downloading pydantic-2.13.5-py3-none-any.whl.metadata (110 kB)
Collecting annotated-types>=0.6.0 (from pydantic<3.0.0,>=2.10.0->pytm==1.4.0)
  Downloading annotated_types-0.8.0-py3-none-any.whl.metadata (15 kB)
Collecting pydantic-core==2.46.5 (from pydantic<3.0.0,>=2.10.0->pytm==1.4.0)
  Downloading pydantic_core-2.46.5-cp313-cp313-manylinux_2_17_x86_64.manylinux2014_x86_64.whl.metadata (6.6 kB)
Collecting typing-extensions>=4.14.1 (from pydantic<3.0.0,>=2.10.0->pytm==1.4.0)
  Downloading typing_extensions-4.16.0-py3-none-any.whl.metadata (3.3 kB)
Collecting typing-inspection>=0.4.2 (from pydantic<3.0.0,>=2.10.0->pytm==1.4.0)
  Downloading typing_inspection-0.4.4-py3-none-any.whl.metadata (2.6 kB)
Downloading pytm-1.4.0-py3-none-any.whl (185 kB)
Downloading pydantic-2.13.5-py3-none-any.whl (472 kB)
Downloading pydantic_core-2.46.5-cp313-cp313-manylinux_2_17_x86_64.manylinux2014_x86_64.whl (2.1 MB)
Downloading annotated_types-0.8.0-py3-none-any.whl (13 kB)
Downloading typing_extensions-4.16.0-py3-none-any.whl (45 kB)
Downloading typing_inspection-0.4.4-py3-none-any.whl (14 kB)
Installing collected packages: typing-extensions, annotated-types, typing-inspection, pydantic-core, pydantic, pytm
Successfully installed annotated-types-0.8.0 pydantic-2.13.5 pydantic-core-2.46.5 pytm-1.4.0 typing-extensions-4.16.0 typing-inspection-0.4.4
```

**A versão está fixada de propósito.** A lista de ameaças do pytm muda entre versões, e a aula 3
cita quantas ele acha para o portal. Com outra versão a contagem é outro número, e o argumento da
aula continua valendo enquanto a aritmética dela deixa de valer.

O `pip show` confirma o que foi instalado e onde:

```
(.venv) ana@vm:~/tm$ pip show pytm
Name: pytm
Version: 1.4.0
Summary: A Pythonic framework for threat modeling
Home-page: https://github.com/OWASP/pytm
Author: pytm Team
Author-email: please_use_github_issues@nowhere.com
License: MIT
Location: /home/ana/tm/.venv/lib/python3.13/site-packages
Requires: pydantic
Required-by: 
```

Por último, o repositório onde o modelo vai morar. Um modelo de ameaças guardado como arquivos no
git tem histórico, pode ser revisado num pull request como código, e é o formato do qual a aula 15
depende:

```
(.venv) ana@vm:~/tm$ git init -b main portal-model
Initialized empty Git repository in /home/ana/tm/portal-model/.git/
(.venv) ana@vm:~/tm$ ls -A
.venv
portal-model
```

Esse é o ambiente inteiro. Cada vez que voltar, `cd ~/tm` e `. .venv/bin/activate` antes de
qualquer outra coisa.

### Quando não funciona

Duas falhas são comuns o bastante para terem sido reproduzidas de propósito. **Uma versão que o pip
não encontra** faz ele listar as que existem, o que mostra que o pip chegou ao PyPI e o problema é
o número que você digitou:

```
(.venv) ana@vm:~/tm$ pip install --progress-bar off pytm==9.9.9
ERROR: Could not find a version that satisfies the requirement pytm==9.9.9 (from versions: 0.3, 0.4, 0.6, 0.7, 0.8, 0.8.1, 1.0, 1.1.0, 1.1.1, 1.1.2, 1.2.0, 1.2.1, 1.3.0, 1.3.1, 1.4.0)
ERROR: No matching distribution found for pytm==9.9.9
```

Se `1.4.0` não aparecer nessa lista, o seu Python é anterior ao 3.11: o pip deixa de fora as
versões que precisam de um Python mais novo, e avisa disso numa linha própria. Se não houver lista
nenhuma e o pip reclamar da rede, o seu computador chega à internet por um proxy, e `HTTPS_PROXY`
precisa ter o endereço dele.

**Um shell onde o ambiente não está ativo** nunca ouviu falar do pytm, porque ele foi instalado
em `.venv` e em nenhum outro lugar:

```
(.venv) ana@vm:~/tm$ deactivate
ana@vm:~/tm$ python3 -c 'import pytm'
Traceback (most recent call last):
  File "<string>", line 1, in <module>
    import pytm
ModuleNotFoundError: No module named 'pytm'
```

O prompt denuncia: sem `(.venv)` no começo. Duas outras falhas são do Debian e do Ubuntu e não
foram reproduzidas aqui. Se `python3 -m venv` reclamar de `ensurepip`, falta o pacote
`python3-venv`: instale, apague `.venv` e crie de novo. Se o pip se recusar com uma mensagem sobre
um **externally managed environment**, ele rodou fora do ambiente virtual, contra o Python do
próprio sistema. Ative `.venv` e tente de novo, e nunca recorra a `sudo pip`.
