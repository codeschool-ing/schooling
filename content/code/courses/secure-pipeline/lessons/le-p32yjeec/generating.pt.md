---
title: syft, na imagem do registry
version: 1
---

O syft é o gerador de SBOM da Anchore. Ele lê os mesmos registros que um scanner lê, bancos de pacotes
e metadados de linguagem, e os escreve como uma lista em vez de compará-los com avisos de segurança.

### Instalando

Do jeito que a aula 1 instalou o uv: a release do GitHub, o checksum publicado, `install`. A partir do
seu diretório pessoal:

```
ana@vm:~$ curl -fsSLO https://github.com/anchore/syft/releases/download/v1.54.1/syft_1.54.1_linux_amd64.tar.gz
ana@vm:~$ curl -fsSL https://github.com/anchore/syft/releases/download/v1.54.1/syft_1.54.1_checksums.txt | grep " syft_1.54.1_linux_amd64.tar.gz$" | sha256sum --check
syft_1.54.1_linux_amd64.tar.gz: OK
ana@vm:~$ tar -xzf syft_1.54.1_linux_amd64.tar.gz syft
ana@vm:~$ install -m 755 syft ~/.local/bin/ && rm syft syft_1.54.1_linux_amd64.tar.gz
ana@vm:~$ syft --version
syft 1.54.1
```

O `sha256sum --check` só imprime `OK` para o arquivo que o projeto publicou, e a aula 12 mostrou quanto
vale essa checagem.

### A imagem que ele lê

O SBOM deveria descrever a imagem que é entregue, que para o linkbox é a do registry. Se o registry
estiver vazio, porque o laboratório foi reconstruído ou o container do registry foi recriado, rode o
pipeline no laptop primeiro, com o branch definido para que o `push` mova a tag `main`:

```
ana@vm:~$ cd linkbox
ana@vm:~/linkbox$ CI_COMMIT=$(git rev-parse --short=7 HEAD) CI_BRANCH=main ci/pipeline.sh
secrets: passed in 0s
test: passed in 2s
sast: passed in 3s
sca: passed in 12s
build: passed in 1s
image: passed in 0s
push: passed in 1s
pipeline passed with 0 warning(s)
```

### A tabela

Sem formato de saída, o syft imprime uma tabela, uma linha por pacote. A imagem tem mais linhas do que
cabem numa página, então aqui estão as doze primeiras, a contagem de pacotes do Debian e os de Python
por inteiro:

```
ana@vm:~/linkbox$ syft -q localhost:5000/linkbox:main | head -n 12
NAME                   VERSION                      TYPE    
base-files             13.8+deb13u7                 deb     
blinker                1.9.0                        python  
ca-certificates        20250419+deb13u1             deb     
click                  8.1.7                        python  
flask                  3.1.3                        python  
gcc-14-base            14.2.0-19                    deb     
gunicorn               22.0.0                       python  
itsdangerous           2.2.0                        python  
jinja2                 3.1.6                        python  
libbz2-1.0             1.0.8-6                      deb     
libc-bin               2.41-12+deb13u4              deb     
ana@vm:~/linkbox$ syft -q localhost:5000/linkbox:main | awk "\$NF == \"deb\"" | wc -l
38
ana@vm:~/linkbox$ syft -q localhost:5000/linkbox:main | grep " python "
blinker                1.9.0                        python  
click                  8.1.7                        python  
flask                  3.1.3                        python  
gunicorn               22.0.0                       python  
itsdangerous           2.2.0                        python  
jinja2                 3.1.6                        python  
markupsafe             2.1.3                        python  
packaging              26.3                         python  
werkzeug               3.1.9                        python  
```

**Trinta e oito pacotes do Debian e nove de Python.** Os do Debian vêm de `/var/lib/dpkg/status.d`
na base distroless, os mesmos registros em que o Trivy contou 162 achados. Os de Python vêm dos
diretórios `dist-info` em `/packages`, onde o Dockerfile da aula 8 os pôs. Oito dos nove estão fixados
no `requirements.txt`. O nono, `packaging 26.3`, é o que esta aula se propôs a explicar.

### Os dois formatos, numa execução só

Uma tabela é para pessoas. Para ferramentas, o syft escreve os dois formatos padrão, e uma execução
consegue escrever os dois: cada `-o` nomeia um formato e um arquivo.

```
ana@vm:~/linkbox$ mkdir ~/sbom
ana@vm:~/linkbox$ syft -q localhost:5000/linkbox:main -o cyclonedx-json=$HOME/sbom/linkbox.cdx.json -o spdx-json=$HOME/sbom/linkbox.spdx.json
ana@vm:~/linkbox$ ls -l ~/sbom
total 2344
-rw-r--r-- 1 ana ana  678631 Oct 23 08:54 linkbox.cdx.json
-rw-r--r-- 1 ana ana 1716646 Oct 23 08:54 linkbox.spdx.json
```

Os dois arquivos descrevem os mesmos 47 pacotes e um sistema operacional, e diferem em tamanho em cerca de um megabyte. A próxima seção abre os dois e mostra de onde vem a diferença.

### Qual imagem, exatamente

O SBOM nomeia o seu objeto: `localhost:5000/linkbox` com a versão `main`, como a próxima seção mostra.
**Uma tag é um nome que se move.** O push de amanhã move `main` para outra imagem, e um SBOM que diz só
"main" vai então descrever uma imagem para a qual `main` já não aponta. O estágio do pipeline no fim
desta aula lê a imagem pela tag de um commit, que nada no pipeline jamais move. A aula 14 vai o resto do caminho e amarra o SBOM ao digest da imagem
com uma assinatura.
