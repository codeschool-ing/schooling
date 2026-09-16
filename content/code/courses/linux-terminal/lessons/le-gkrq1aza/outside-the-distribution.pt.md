---
title: Tudo o que você instala e o gerenciador de pacotes desconhece
version: 1
---

Os repositórios da distribuição não têm tudo, e o que eles têm muitas vezes é mais antigo do que você
quer. Então as pessoas instalam software de outros lugares, e isso é normal e está tudo bem — desde
que você saiba o que está assumindo.

**A frase para guardar: tudo nesta seção é software que a sua máquina não vai atualizar, não vai
remover, e não vai mencionar quando ele for o motivo de algo quebrar.**

## Repositórios de terceiros

Esta é a opção *boa*, porque o gerenciador de pacotes continua gerenciando. Dois passos, e a seção 03
mostrou o que eles produzem:

```
root@vm:~# cat /etc/apt/sources.list.d/docker.list
deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu   n
oble stable
```

Uma chave em `/etc/apt/keyrings/`, e uma linha de fonte que a nomeia. Daí em diante o `apt upgrade`
atualiza o Docker como qualquer outra coisa.

**O risco não é segurança, é sobreposição.** Um repositório de terceiro pode também carregar versões
de pacotes que a sua distribuição já fornece — uma biblioteca mais nova, um compilador mais novo — e
uma vez que um seja instalado de lá, aquele repositório passa a ser dono dele. O pin da seção 09 é a
defesa:

```
Package: *
Pin: origin download.docker.com
Pin-Priority: 100
```

"Nada desta origem a menos que eu peça pelo nome." Em qualquer repositório que não seja o da própria
distribuição, isso vale cinco minutos.

**PPAs no Ubuntu são repositórios de terceiros com um nome mais bonito.** O `add-apt-repository
ppa:nome/x` escreve o arquivo de fonte e busca a chave por você. A mesma cautela se aplica e mais
uma: uma PPA é a build de uma pessoa, e quando ela para, aquilo para — e os pacotes que você instalou
de lá ficam, sem suporte, até você notar. A transcrição da seção 03 tem duas PPAs nesta máquina que
não buscam mais nada.

## Snap e Flatpak

Modelo diferente: a aplicação vem com as próprias bibliotecas, num sandbox próprio, e não depende do
que está no seu sistema.

| | |
|---|---|
| **snap** | da Canonical. No Ubuntu, `snap list`, `snap install`, `snap refresh` |
| **flatpak** | entre distribuições, mais desktop. `flatpak list`, `flatpak install` |

**Eles têm o próprio mecanismo de atualização e a própria ideia do que está instalado**, que é a
parte que importa aqui: o `apt list --installed` não mostra um snap, e o `dpkg -S` não é dono dos
arquivos dele. Dois gerenciadores de pacotes numa máquina, cada um alheio ao outro.

No Ubuntu especificamente, **alguns comandos `apt install` agora instalam um snap no lugar** —
Firefox e Chromium são os conhecidos. O `apt install firefox` funciona e o `dpkg -L firefox` mostra um
pacote de transição que instalou outra coisa. Quando os arquivos de um programa não estão onde o
`dpkg` diz, é por isso.

A troca é real nos dois sentidos: um snap fica atualizado numa distribuição antiga e inicia mais
devagar, usa mais disco, e é mais difícil de inspecionar. Para um servidor, prefira o repositório.
Para uma aplicação de desktop que você quer na versão atual, o sandbox é um preço razoável.

## Gerenciadores de pacote de linguagem

`pip`, `npm`, `gem`, `cargo`, `go install`. Cada um é um gerenciador de pacotes completo para uma
linguagem, com um registro próprio, e **nenhum deles conhece o do sistema**.

A colisão específica que vale nomear, porque produz uma máquina quebrada:

```
pip install --user requests          # fine: your account only
pip install requests                 # on a modern distribution, refused
sudo pip install requests            # the one that breaks things
```

O `sudo pip install` escreve nos mesmos diretórios em que moram os pacotes python da distribuição.
Quando a distribuição mais tarde atualiza o `python3-requests`, os dois discordam sobre o que está
instalado, e o que quebra normalmente é alguma ferramenta de sistema escrita em python e não a coisa
em que você estava trabalhando.

**Distribuições recentes recusam isso**, e a recusa é o sistema de empacotamento se protegendo:

```
root@vm:~# /usr/bin/python3 -m pip install requests 2>&1 | head -14
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
```

**Esse erro não está no seu caminho; ele é a resposta.** Ele nomeia três alternativas na ordem em que
você deveria considerá-las, que é a mesma ordem da tabela abaixo. A opção que o ignora —
`--break-system-packages` — tem um nome honesto, e as máquinas que ela quebrou são o porquê.

As respostas certas, em ordem:

| | |
|---|---|
| `apt install python3-requests` | se a distribuição tem, use |
| um **ambiente virtual** | `python3 -m venv`, e as dependências do projeto moram no projeto |
| `pipx install coisa` | para uma ferramenta de linha de comando: ambiente próprio, um comando no PATH |
| `pip install --user` | aceitável, e ainda invisível para o `apt` |

A mesma forma se aplica ao `npm -g`, ao `gem install` e ao resto: **instalações globais de um
gerenciador de linguagem vão para o `/usr/local`, onde a seção 05 mostrou o `dpkg -S` não achando
nada.**

## Um binário de uma página de release

`curl | sh`, um tarball extraído no `/opt`, um binário solto jogado no `/usr/local/bin`. Este é o mais
comum e o menos gerenciado:

- nada o atualiza;
- nada o remove;
- o `dpkg -S` e o `rpm -qf` não vão nomeá-lo;
- e ele ainda vai estar lá, na versão que você instalou, muito depois de você ter esquecido.

**Não é errado**, e é como muito software bom é distribuído. O que o torna sobrevivível é anotar o
que você fez. O `/usr/local` existe justamente para que esse software fique num lugar só, não
gerenciado, que é o que a aula 3 apontava e o que a resposta vazia do `dpkg -S` da seção 05 demonstra:

```
root@vm:~# dpkg -S /usr/local/bin/python3
dpkg-query: no path found matching pattern /usr/local/bin/python3
```

**Aquela máquina tem um python3 no `/usr/local/bin` que nenhum pacote pôs lá.** Alguém o instalou, e
o único registro é o próprio arquivo.

## Contêineres, que são a outra resposta

O motivo de o `docker` aparecer nas transcrições da seção 09 é que contêineres são como muita gente
hoje evita esta seção inteira: a aplicação e as dependências dela são empacotadas juntas, nas versões
que a aplicação escolheu, e o gerenciador de pacotes do host é responsável por exatamente uma coisa —
o runtime de contêiner.

**Isso não remove o problema, move.** A imagem tem uma distribuição dentro, com um gerenciador de
pacotes, e o `apt-get install` do Dockerfile dela está sujeito a tudo nesta aula. O
`--no-install-recommends` da seção 02 está em todo Dockerfile bem escrito por um motivo.

## O que fazer a respeito

Três hábitos, e eles são baratos:

**Anote o que você instalou fora do gerenciador de pacotes**, no repositório que descreve a máquina —
um Dockerfile, um role do Ansible, um `README`. Uma lista que existe vale mais do que uma que é
precisa.

**Confira antes de acrescentar um repositório** se a distribuição já tem o que você quer, e quão
antigo aquilo realmente é. O `apt policy coisa` responde num segundo, e a resposta muitas vezes é
"recente o bastante".

**Prefira, nesta ordem**: o repositório da distribuição, um repositório de terceiro, uma aplicação em
sandbox, um gerenciador de linguagem num ambiente local do projeto, um binário no `/usr/local`. Cada
degrau para baixo nessa lista é software mais atual e menos máquina que se atualiza sozinha.
