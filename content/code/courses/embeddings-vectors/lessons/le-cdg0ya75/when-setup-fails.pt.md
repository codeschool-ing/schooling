---
title: Quando a instalação falha
version: 1
---

A preparação é onde desiste a maioria das pessoas que desistem de um curso como este, e quase
sempre por causa de uma entre poucas mensagens. Cada uma abaixo foi provocada de propósito, na
máquina em que o curso foi gravado, desfazendo um passo da preparação. Procure a que bate com o que
você está vendo.

## `externally-managed-environment`

```
ana@lab:~/emb$ pip install numpy
error: externally-managed-environment

× This environment is externally managed
╰─> To install Python packages system-wide, try apt install
    python3-xyz, where xyz is the package you are trying to
    install.
    
    If you wish to install a non-Debian-packaged Python package,
    create a virtual environment using python3 -m venv path/to/venv.
    Then use path/to/venv/bin/python and path/to/venv/bin/pip. Make
    sure you have python3-full installed.
    
    If you wish to install a non-Debian packaged Python application,
    it may be easiest to use pipx install xyz, which will manage a
    virtual environment for you. Make sure you have pipx installed.
    
    See /usr/share/doc/python3.12/README.venv for more information.

note: If you believe this is a mistake, please contact your Python installation or OS distribution provider. You can override this, at the risk of breaking your Python installation or OS, by passing --break-system-packages.
hint: See PEP 668 for the detailed specification.
```

**O `pip` rodou fora do ambiente do curso.** O Ubuntu protege o Python que usa para si mesmo e se
recusa a instalar pacotes nele. O ambiente que o `setup.sh` criou tem um `pip` próprio, e a linha
que ele acrescentou ao `~/.bashrc` põe esse em primeiro lugar, mas só num terminal aberto depois.
Digite `source ~/.bashrc`, ou abra um terminal novo, e `which python` deve responder
`~/.venvs/emb/bin/python` com o seu diretório pessoal na frente.

## `ensurepip is not available`

```
ana@lab:~/emb$ python3 -m venv ~/.venvs/try
The virtual environment was not created successfully because ensurepip is not
available.  On Debian/Ubuntu systems, you need to install the python3-venv
package using the following command.

    apt install python3.12-venv

You may need to use sudo with that command.  After installing the python3-venv
package, recreate your virtual environment.

Failing command: /home/ana/.venvs/try/bin/python3
```

**Falta o pacote que deixa o Python criar ambientes.** Instale-o, apague o ambiente feito pela
metade e rode a preparação de novo:

```bash
sudo apt install -y python3-venv
rm -rf ~/.venvs/emb
bash setup.sh
```

## `Is the server running locally`

```
ana@lab:~/emb$ psql -c "SELECT 1"
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
```

**O PostgreSQL não está rodando.** O Ubuntu o inicia quando ele é instalado e, normalmente, sempre
que o computador liga, então isto costuma aparecer depois de reiniciar um sistema que não inicia os
seus serviços sozinho. Inicie-o com `sudo service postgresql start`. Se o `psql` disser, em vez
disso, que um **papel** (*role*) não existe, a linha do `createuser` da seção anterior ficou para
trás; rode-a, e depois `createdb shop`.

## `extension "vector" is not available`

```
ana@lab:~/emb$ psql -c "CREATE EXTENSION vector"
ERROR:  extension "vector" is not available
DETAIL:  Could not open extension control file "/usr/share/postgresql/16/extension/vector.control": No such file or directory.
HINT:  The extension must first be installed on the system where PostgreSQL is running.
```

**O PostgreSQL está rodando, mas o pgvector não está instalado ao lado dele.** A extensão é um
pacote separado, e o banco só a encontra depois que ela está no disco:

```bash
sudo apt install -y postgresql-16-pgvector
```

Nada precisa ser reiniciado. O mesmo `CREATE EXTENSION` funciona logo em seguida.

## `No module named 'minilm'`

```
ana@lab:~$ python -c "from minilm import embed"
Traceback (most recent call last):
  File "<string>", line 1, in <module>
ModuleNotFoundError: No module named 'minilm'
```

**O programa rodou no diretório errado.** O Python encontra o `minilm.py` porque ele está no
diretório de onde você roda, e esse diretório é o `~/emb`. Digite `cd ~/emb` e rode de novo. A mesma
mensagem para `numpy`, `chromadb` ou qualquer outra biblioteca quer dizer que o terminal está fora
do ambiente: é o primeiro caso acima.

## Todo o resto

Dois hábitos resolvem quase todo o resto. Leia primeiro a **última** linha de um erro comprido,
porque um traceback do Python lista cada chamada no caminho para baixo, e a causa vem no fim. E
compare o seu comando com a página caractere por caractere: uma aspa que virou aspa curva ao passar
por um programa de chat, ou uma linha de um bloco colado que ficou para trás, explicam muitos dos
que sobram. Quando um passo inteiro deu errado, o `setup.sh` pode ser rodado de novo sem medo: ele
instala no mesmo ambiente, baixa e confere o modelo outra vez, e só acrescenta as suas linhas ao
`~/.bashrc` uma vez.
