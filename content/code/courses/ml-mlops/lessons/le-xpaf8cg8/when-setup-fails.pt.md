---
title: Quando a instalação falha
version: 1
---

Quase todo mundo que desiste de um curso como este desiste aqui, num erro sobre algo que acabou de
instalar. Estas são as falhas que a máquina de gravação produziu enquanto esta lição era escrita, na
ordem em que você as encontraria, cada uma como ela imprimiu e com o que significa.

## O ambiente não pode ser criado

```
ana@dev:~$ python3 -m venv ~/mlenv
The virtual environment was not created successfully because ensurepip is not
available.  On Debian/Ubuntu systems, you need to install the python3-venv
package using the following command.

    apt install python3.12-venv

You may need to use sudo with that command.  After installing the python3-venv
package, recreate your virtual environment.

Failing command: /home/ana/mlenv/bin/python3
```

O `venv` cria o ambiente e depois instala o `pip` dentro dele, e a segunda metade precisa de um
pacote que o Ubuntu deixa de fora. **A mensagem diz a correção**: `sudo apt install python3-venv`,
que é o primeiro comando da seção anterior. Ela também deixa para trás um `~/mlenv` pela metade;
apague-o com `rm -rf ~/mlenv` antes de rodar `python3 -m venv ~/mlenv` de novo.

## O pip se recusa a instalar qualquer coisa

```
ana@dev:~$ pip install scikit-learn==1.9.1
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

Este é o `pip` fora do ambiente, tentando escrever no Python do próprio sistema, e o Ubuntu recusa
de propósito: uma biblioteca instalada ali pode quebrar programas que o próprio sistema roda. **Ele
não está pedindo que você passe `--break-system-packages`.** Quer dizer que o ambiente não está ativo
neste terminal. Rode `source ~/mlenv/bin/activate`, e o mesmo `pip install` funciona.

## Um programa não acha uma biblioteca que você instalou

```
ana@dev:~$ cd ~/ml && python3 generate.py
Traceback (most recent call last):
  File "/home/ana/ml/generate.py", line 15, in <module>
    import numpy as np
ModuleNotFoundError: No module named 'numpy'
```

A mesma causa vista do outro lado: um terminal novo, o ambiente não ativado, e o `python3` é o do
sistema, que não tem nenhuma das bibliotecas do curso. `which python` responde a pergunta quando
você não tem certeza; dentro do ambiente ele imprime um caminho dentro de `~/mlenv`.

## Uma tabela que não existe, num arquivo que existe

```
ana@dev:~$ python ml/supervised.py 2>&1 | tail -n 3
FROM members m JOIN recent r USING (member_id)
GROUP BY m.member_id
': no such table: members
ana@dev:~$ ls -l shop.db
-rw-r--r-- 1 ana ana 0 Oct 10 04:09 shop.db
```

**Esta é a que custa uma tarde.** O programa foi rodado da pasta pessoal em vez de `~/ml`. Ele abre
`shop.db` por um nome relativo, então procurou o arquivo no diretório de onde foi iniciado, e o
SQLite, quando pedem que abra um arquivo que não existe, **o cria, vazio**, em vez de falhar. O erro
fala de uma tabela, o que manda você olhar o SQL. O arquivo vazio que ficou, de zero bytes, é a
prova. Apague-o e rode o programa de dentro de `~/ml`.

Todos os programas deste curso esperam ser rodados de `~/ml`. A lição 5 diz por que um pipeline deve
nomear os seus arquivos por inteiro, e daí em diante os programas fazem isso.

## O problema é a rede

O `pip` precisa alcançar `pypi.org`. Numa rede com proxy, o erro menciona um tempo esgotado, um
certificado ou `ProxyError`, e a correção é da rede, não do Python: o endereço do proxy em
`HTTPS_PROXY`, e o certificado dele onde o seu sistema guarda os confiáveis. Essa falha não foi
reproduzida para este curso, então não há transcrição dela aqui.
