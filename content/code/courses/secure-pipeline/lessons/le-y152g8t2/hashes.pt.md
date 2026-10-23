---
title: Um hash que recusa um arquivo
version: 1
---

Uma versão fixada diz **qual release** instalar: `blinker==1.9.0`. Ela não diz **quais bytes**. Se o
arquivo servido com esse nome mudar, porque um índice foi comprometido, um mirror serviu outra coisa ou
a conta de um mantenedor publicou por cima de uma release, a versão fixada continua satisfeita e o
instalador continua instalando. O script da Codecov e os tarballs do xz foram ambos arquivos com o nome
certo e o conteúdo errado.

Um hash fixa os bytes. **O modo `--require-hashes` do pip só instala um arquivo se o SHA-256 dele for um
dos que o arquivo de requirements lista**, e recusa qualquer outro antes que uma linha dele rode. A aula
15 transforma os requirements do linkbox num lock com um hash para cada arquivo; esta seção mostra o
mecanismo num pacote só, num diretório de rascunho, para você ver a recusa com os próprios olhos.

### Uma versão fixada com hash

Trabalhe num diretório só para isso, com um ambiente virtual que tenha o pip (`--seed` o põe lá):

```
ana@vm:~$ mkdir ~/supply && cd ~/supply
ana@vm:~/supply$ uv venv --seed -q && . .venv/bin/activate
(supply) ana@vm:~/supply$ pip --version
pip 26.2.2 from /home/ana/supply/.venv/lib/python3.13/site-packages/pip (python 3.13)
```

`pip download` baixa um arquivo sem instalá-lo, e `pip hash` imprime a linha de que um arquivo de
requirements precisa:

```
(supply) ana@vm:~/supply$ pip download -q --no-deps -d wheels blinker==1.9.0
(supply) ana@vm:~/supply$ ls wheels
blinker-1.9.0-py3-none-any.whl
(supply) ana@vm:~/supply$ pip hash wheels/blinker-1.9.0-py3-none-any.whl
wheels/blinker-1.9.0-py3-none-any.whl:
--hash=sha256:ba0efaa9080b619ff2f3459d1d500c57bddea4a6b424b60a91141db6fd2f08bc
```

Esse hash é um fato sobre este arquivo. A mesma wheel baixada em qualquer máquina, de qualquer mirror,
tem o mesmo SHA-256, e um arquivo com um único byte mudado tem um completamente diferente. Ponha a linha
num arquivo de requirements e instale com o modo ligado:

```
(supply) ana@vm:~/supply$ echo "blinker==1.9.0 $(pip hash wheels/*.whl | tail -n 1)" > requirements.txt
(supply) ana@vm:~/supply$ cat requirements.txt
blinker==1.9.0 --hash=sha256:ba0efaa9080b619ff2f3459d1d500c57bddea4a6b424b60a91141db6fd2f08bc
(supply) ana@vm:~/supply$ pip install --require-hashes --no-deps -r requirements.txt
Collecting blinker==1.9.0 (from -r requirements.txt (line 1))
  Using cached blinker-1.9.0-py3-none-any.whl (8.5 kB)
Installing collected packages: blinker
Successfully installed blinker-1.9.0
(supply) ana@vm:~/supply$ pip uninstall -q -y blinker
```

Instalou: o arquivo, baixado do PyPI pelo download de um momento antes e reaproveitado do cache do pip, tem exatamente o hash que o arquivo de requirements nomeia. **O hash veio do seu próprio download, e esse é o passo que merece cuidado**: um hash copiado de
um arquivo já adulterado fixa o arquivo adulterado. A aula 15 tira os hashes dos registros do próprio
índice com um resolvedor, e numa data, por esse motivo.

### O modo é tudo ou nada

Com `--require-hashes`, um requisito sem hash também é recusado, e o pip imprime o hash que teria
aceitado:

```
(supply) ana@vm:~/supply$ pip install --require-hashes blinker==1.9.0
Collecting blinker==1.9.0
  Using cached blinker-1.9.0-py3-none-any.whl (8.5 kB)
ERROR: Hashes are required in --require-hashes mode, but they are missing from some requirements. Here is a list of those requirements along with the hashes their downloaded archives actually had. Add lines like these to your requirements files to prevent tampering. (If you did not enable --require-hashes manually, note that it turns on automatically when any package has a hash.)
    blinker==1.9.0 --hash=sha256:ba0efaa9080b619ff2f3459d1d500c57bddea4a6b424b60a91141db6fd2f08bc
```

Esse rigor é o ponto. Um lock em que quase todo arquivo tem hash e um não tem é um lock com uma porta aberta, e o pip não deixa você tê-lo. A última frase da mensagem diz mais uma coisa que vale saber: o modo se liga sozinho assim que qualquer linha de um arquivo de requirements traz um hash.

### Um arquivo que mudou

Agora monte um índice que serve um arquivo diferente com o mesmo nome. Copie a wheel para um diretório
organizado como índice, acrescente um byte a ela, a menor mudança que existe, e sirva o diretório com
`python3 -m http.server 8081 --bind 127.0.0.1 --directory mirror` num segundo terminal. Depois instale o
mesmo arquivo de requirements a partir desse índice:

```
(supply) ana@vm:~/supply$ mkdir -p mirror/simple/blinker
(supply) ana@vm:~/supply$ cp wheels/blinker-1.9.0-py3-none-any.whl mirror/simple/blinker/
(supply) ana@vm:~/supply$ printf "x" >> mirror/simple/blinker/blinker-1.9.0-py3-none-any.whl
(supply) ana@vm:~/supply$ pip install --require-hashes --no-deps --index-url http://127.0.0.1:8081/simple/ -r requirements.txt
Looking in indexes: http://127.0.0.1:8081/simple/
Collecting blinker==1.9.0 (from -r requirements.txt (line 1))
  Downloading blinker-1.9.0-py3-none-any.whl (8.5 kB)
ERROR: THESE PACKAGES DO NOT MATCH THE HASHES FROM THE REQUIREMENTS FILE. If you have updated the package versions, please update the hashes. Otherwise, examine the package contents carefully; someone may have tampered with them.
    blinker==1.9.0 from http://127.0.0.1:8081/simple/blinker/blinker-1.9.0-py3-none-any.whl (from -r requirements.txt (line 1)):
        Expected sha256 ba0efaa9080b619ff2f3459d1d500c57bddea4a6b424b60a91141db6fd2f08bc
             Got        15cc4b75d6aec4b6e546a4efaa1e60ef06aac0191d77e4cc95db00ed1066e421
```

**O pip baixou o arquivo e o recusou.** O nome estava certo, a versão estava certa, o índice respondeu
normalmente, e a instalação parou na única checagem que olha o conteúdo. Leia a mensagem: `Expected` é o
hash que você fixou, `Got` é o hash do que chegou. Nada foi desempacotado e nada rodou.

### O que um hash não faz

- **Ele não julga o primeiro arquivo.** Se a release que você fixou era maliciosa no dia em que você
  calculou o hash, como as três versões do ua-parser-js foram nas horas em que ficaram no ar, o hash
  fixa fielmente o arquivo malicioso. Um período de espera antes de adotar uma release nova é a defesa
  para isso, e a aula 15 o acrescenta.
- **Ele não cobre o que não está no arquivo.** Uma imagem base, um script baixado com `curl` num
  Dockerfile, uma GitHub Action: cada um precisa da sua própria fixação por digest ou commit, que as
  aulas 15 e 16 acrescentam.
- **Ele não diz quem fez o arquivo.** Um hash prova que este é o arquivo que você revisou; uma
  assinatura e a proveniência, na aula 14, dizem quem o construiu e a partir de quê.

A Codecov é o caso em que um hash bastava. O cliente que descobriu comparou o script que tinha baixado
com o SHA-256 publicado ao lado, e essa comparação é exatamente o que o pip fez acima.
