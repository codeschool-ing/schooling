---
title: Seu laboratório, montado uma vez
version: 1
---

**A plataforma não dá nenhuma máquina para este curso. Você monta o laboratório, uma vez, aqui**, e
cada aula seguinte acrescenta uma pasta a ele. Ele é pequeno: Python 3.10 ou mais novo, git, dois
pacotes Python, um terminal e um navegador. Nenhum servidor de banco, nenhum contêiner, nenhuma conta
em lugar nenhum.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l01-workspace\" aria-label=\"O espaço de trabalho que este curso monta. Uma pasta chamada sc no seu diretório pessoal guarda um ambiente virtual Python, .venv, com Flask 3.1.3 e pytest 9.1.1 instalados, e uma pasta por aula. Cada pasta de aula é um repositório git próprio, com um app.py e um test_app.py. A pasta da aula 1 é cancel.\"><defs><marker id=\"l01-workspace-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"30\" y=\"100\" width=\"140\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"100.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">~/sc</text><rect x=\"240\" y=\"20\" width=\"450\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"256\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">.venv</text><text x=\"256\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Flask 3.1.3 e pytest 9.1.1, com versão fixa</text><rect x=\"240\" y=\"100\" width=\"450\" height=\"130\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"256\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">cancel/</text><text x=\"256\" y=\"142\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">app.py   test_app.py   .git/</text><text x=\"256\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">uma pasta por aula, cada uma um repositório git</text><text x=\"256\" y=\"204\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">… e mais uma por aula</text><path d=\"M170 116 L205 116 L205 50 L240 50\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-workspace-ah-paper-dim)\"></path><path d=\"M170 128 L240 128\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-workspace-ah-paper-dim)\"></path></svg>", "caption": "Um ambiente compartilhado por todas as aulas, e uma aplicação pequena por aula, que você pode quebrar e restaurar."}
```

### Escolha onde ele roda

| caminho | o que você precisa | quanto custa ao seu computador |
|---|---|---|
| **no seu computador (recomendado)** | Linux ou macOS como estão; no Windows, o WSL com Ubuntu | quase nada: uma pasta de uns 35 MB |
| numa máquina virtual | VirtualBox, UTM ou Hyper-V, e uma imagem do Ubuntu 24.04 | 2 GB de memória enquanto roda, 10 GB de disco |
| online | um ambiente de desenvolvimento na nuvem, como GitHub Codespaces ou Gitpod, sobre um repositório vazio | nada localmente; roda no computador de outra empresa, dentro da cota gratuita dela ou pago por você |

**O primeiro caminho é o recomendado** porque nada neste curso precisa ficar isolado do seu
computador. As aplicações com falha são suas, são pequenas e ouvem só em `127.0.0.1`, que nada fora
da sua máquina alcança. Não há malware e nada para baixar além de dois pacotes conhecidos.

A máquina virtual é para um computador gerenciado por um empregador que proíbe instalar programas,
ou para quem prefere guardar o trabalho do curso numa caixa que pode apagar. O caminho online
funciona num computador emprestado. **Mantenha privadas as portas encaminhadas**: um ambiente online
publica uma porta na internet com um clique, e uma aplicação com falha proposital nunca deve ser uma
delas. Cotas gratuitas mudam conforme os termos do fornecedor, então confira a atual antes de contar
com ela.

As transcrições deste curso foram gravadas no Ubuntu 24.04, como um usuário chamado `ana` numa
máquina chamada `vm`. No Ubuntu ou no Debian, os pacotes do sistema vêm primeiro:

```sh
sudo apt install python3 python3-venv git curl
```

Esse comando não foi executado na gravação: a máquina já tinha os quatro. No macOS, `git` e `curl`
chegam com as ferramentas de linha de comando (`xcode-select --install`) e o Python 3 pelo
python.org ou pelo Homebrew. Qualquer Firefox, Chrome ou Edge atual serve de navegador; as aulas 7 a
9 usam as ferramentas de desenvolvedor dele.

### Monte

Confira as duas versões primeiro. O Flask 3.1 precisa do Python 3.9 ou mais novo e este curso usa
recursos do 3.10; o Ubuntu 24.04 traz o 3.12, e a máquina da gravação tinha o 3.13.

```
ana@vm:~$ python3 --version
Python 3.13.16
ana@vm:~$ git --version
git version 2.43.0
```

Crie uma pasta para o curso e um **ambiente virtual** dentro dela, para que Flask, pytest e tudo o
que as próximas aulas acrescentam morem em `~/sc/.venv` e em nenhum outro lugar do sistema. Ativar o
ambiente muda o prompt, e é assim que você sabe depois se ele está ativo:

```
ana@vm:~$ mkdir sc
ana@vm:~$ cd sc
ana@vm:~/sc$ python3 -m venv .venv
ana@vm:~/sc$ . .venv/bin/activate
(.venv) ana@vm:~/sc$ pip install --progress-bar off flask==3.1.3 pytest==9.1.1
Collecting flask==3.1.3
  Downloading flask-3.1.3-py3-none-any.whl.metadata (3.2 kB)
Collecting pytest==9.1.1
  Downloading pytest-9.1.1-py3-none-any.whl.metadata (7.6 kB)
Collecting blinker>=1.9.0 (from flask==3.1.3)
  Downloading blinker-1.9.0-py3-none-any.whl.metadata (1.6 kB)
Collecting click>=8.1.3 (from flask==3.1.3)
  Downloading click-8.5.0-py3-none-any.whl.metadata (2.6 kB)
Collecting itsdangerous>=2.2.0 (from flask==3.1.3)
  Downloading itsdangerous-2.2.0-py3-none-any.whl.metadata (1.9 kB)
Collecting jinja2>=3.1.2 (from flask==3.1.3)
  Downloading jinja2-3.1.6-py3-none-any.whl.metadata (2.9 kB)
Collecting markupsafe>=2.1.1 (from flask==3.1.3)
  Downloading markupsafe-3.0.4-cp313-cp313-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl.metadata (2.7 kB)
Collecting werkzeug>=3.1.0 (from flask==3.1.3)
  Downloading werkzeug-3.1.9-py3-none-any.whl.metadata (4.1 kB)
Collecting iniconfig>=1.0.1 (from pytest==9.1.1)
  Downloading iniconfig-2.3.1-py3-none-any.whl.metadata (2.8 kB)
Collecting packaging>=22 (from pytest==9.1.1)
  Downloading packaging-26.3-py3-none-any.whl.metadata (3.5 kB)
Collecting pluggy<2,>=1.5 (from pytest==9.1.1)
  Downloading pluggy-1.7.0-py3-none-any.whl.metadata (5.0 kB)
Collecting pygments>=2.7.2 (from pytest==9.1.1)
  Downloading pygments-2.21.0-py3-none-any.whl.metadata (2.5 kB)
Downloading flask-3.1.3-py3-none-any.whl (103 kB)
Downloading pytest-9.1.1-py3-none-any.whl (386 kB)
Downloading pluggy-1.7.0-py3-none-any.whl (27 kB)
Downloading blinker-1.9.0-py3-none-any.whl (8.5 kB)
Downloading click-8.5.0-py3-none-any.whl (125 kB)
Downloading iniconfig-2.3.1-py3-none-any.whl (7.6 kB)
Downloading itsdangerous-2.2.0-py3-none-any.whl (16 kB)
Downloading jinja2-3.1.6-py3-none-any.whl (134 kB)
Downloading markupsafe-3.0.4-cp313-cp313-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl (23 kB)
Downloading packaging-26.3-py3-none-any.whl (129 kB)
Downloading pygments-2.21.0-py3-none-any.whl (1.3 MB)
Downloading werkzeug-3.1.9-py3-none-any.whl (228 kB)
Installing collected packages: pygments, pluggy, packaging, markupsafe, itsdangerous, iniconfig, click, blinker, werkzeug, pytest, jinja2, flask
Successfully installed blinker-1.9.0 click-8.5.0 flask-3.1.3 iniconfig-2.3.1 itsdangerous-2.2.0 jinja2-3.1.6 markupsafe-3.0.4 packaging-26.3 pluggy-1.7.0 pygments-2.21.0 pytest-9.1.1 werkzeug-3.1.9
```

**As versões são fixadas de propósito.** Um Flask ou pytest mais novo roda todos os programas deste
curso, mas as transcrições citam as versões com que foram gravadas, e fixar a versão é o jeito
honesto de reproduzir uma gravação. A aula 17 trata do que fixar versão rende num projeto de verdade e
do que custa.

O pip trouxe mais dez pacotes: seis de que o Flask precisa e quatro de que o pytest precisa. O
`pip list` mostra o ambiente inteiro, e vale saber disso desde o primeiro dia, porque cada um desses
nomes é código que você agora executa:

```
(.venv) ana@vm:~/sc$ pip list
Package      Version
------------ -------
blinker      1.9.0
click        8.5.0
Flask        3.1.3
iniconfig    2.3.1
itsdangerous 2.2.0
Jinja2       3.1.6
MarkupSafe   3.0.4
packaging    26.3
pip          26.2.1
pluggy       1.7.0
Pygments     2.21.0
pytest       9.1.1
Werkzeug     3.1.9
```

Por último, a pasta da primeira aula. **A aplicação de cada aula mora numa pasta própria, e cada
pasta é um repositório git**, então a correção que você faz é um diff que dá para ler, e um
experimento quebrado está a um `git checkout .` da versão que funcionava:

```
(.venv) ana@vm:~/sc$ mkdir cancel
(.venv) ana@vm:~/sc$ cd cancel
(.venv) ana@vm:~/sc/cancel$ git init -b main
Initialized empty Git repository in /home/ana/sc/cancel/.git/
```

Esse é o laboratório inteiro. Sempre que voltar, abra um terminal, `cd ~/sc` e
`. .venv/bin/activate` antes de qualquer coisa; `deactivate` sai dele.
