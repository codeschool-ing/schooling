---
title: O seu laboratório
version: 1
---

Toda checagem deste curso roda numa máquina que você controla, contra um serviço que você
escreveu. **A plataforma não fornece máquina para isso, e é de propósito:** os scanners, o servidor
de CI, o registry e o cluster são coisas que um engenheiro de DevSecOps monta no primeiro dia de
qualquer emprego, e montá-las faz parte do que o curso ensina. Você monta o laboratório uma vez,
aqui, e cada aula seguinte diz o que acrescenta a ele.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"sp-l01-lab\" aria-label=\"O laboratório que este curso monta na sua própria máquina. Você faz commit em ~/linkbox e envia para ~/ci/linkbox.git, um repositório bare cujo hook post-receive roda o ci/pipeline.sh do commit enviado. Cada execução guarda o checkout e os logs em ~/ci/runs/N e constrói uma imagem no Docker. A aula 8 acrescenta um registry em localhost:5000 e a aula 10 um cluster kind que puxa imagens dele.\"><defs><marker id=\"sp-l01-lab-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"sp-l01-lab-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"sp-l01-lab-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"310\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"24\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a sua máquina</text><rect x=\"30\" y=\"60\" width=\"170\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"115.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">~/linkbox</text><text x=\"115.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o projeto</text><rect x=\"290\" y=\"60\" width=\"190\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"385.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">~/ci/linkbox.git</text><text x=\"385.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">hooks/post-receive</text><rect x=\"540\" y=\"60\" width=\"150\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"615.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">~/ci/runs/N</text><text x=\"615.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">uma por execução</text><path d=\"M200 88 L288 88\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l01-lab-ah-phosphor)\"></path><text x=\"244\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">git push</text><path d=\"M480 88 L538 88\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l01-lab-ah-paper-dim)\"></path><text x=\"385\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">clone + ci/pipeline.sh</text><rect x=\"290\" y=\"170\" width=\"190\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"385.0\" y=\"187.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Docker Engine</text><text x=\"385.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">linkbox:&lt;commit&gt;</text><path d=\"M385 116 L385 168\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l01-lab-ah-paper-dim)\"></path><rect x=\"40\" y=\"250\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"140.0\" y=\"267.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">registry</text><text x=\"140.0\" y=\"284.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">localhost:5000</text><rect x=\"480\" y=\"250\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"580.0\" y=\"267.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">cluster kind</text><text x=\"580.0\" y=\"284.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">kubectl</text><text x=\"150\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">aula 8</text><text x=\"580\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">aula 10</text><path d=\"M320 220 L320 230 L140 230 L140 248\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#sp-l01-lab-ah-amber)\"></path><path d=\"M242 285 L478 285\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#sp-l01-lab-ah-amber)\"></path><text x=\"360\" y=\"275\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">puxa</text></svg>", "caption": "Tudo o que o curso executa fica numa máquina só: o projeto, um servidor que roda o pipeline dele e o Docker.", "same": ["Docker Engine", "registry"]}
```

### Do que ele precisa

**Docker, git, Python 3.11 ou mais novo, uv, curl e jq.** Todo o resto, os scanners incluídos, é
instalado pela aula que o usa pela primeira vez, a partir da release do próprio projeto, com o
checksum conferido. Nada no curso exige conta em lugar nenhum, assinatura de nuvem ou cartão.

### Escolha onde ele roda

| caminho | do que você precisa | quanto custa ao seu computador |
|---|---|---|
| **no seu próprio computador (recomendado)** | Linux como está; no Windows, WSL 2 com Ubuntu; no macOS, Docker Desktop ou Colima | cerca de 15 GB de disco para imagens e bancos dos scanners; 8 GB de memória é confortável, 4 GB funcionam com uma coisa rodando por vez |
| numa máquina virtual | VirtualBox, UTM ou Hyper-V, e uma imagem do Ubuntu 24.04 | os mesmos 15 GB dentro da máquina mais o sistema dela, então dê 40 GB de disco, 4 GB de memória e 2 processadores |
| online | uma conta no GitHub e um Codespace num repositório vazio seu | nada local; um Codespace de 4 núcleos tem Docker, e as horas gratuitas do mês acabam quatro vezes mais rápido que num de 1 núcleo |

**O primeiro caminho é o recomendado** porque o Docker no Linux roda contêineres nativamente, e
toda transcrição do curso foi gravada assim: Ubuntu 24.04, um usuário chamado `ana` numa máquina
chamada `vm`. A máquina virtual é para um computador cujo dono não permite instalar o Docker, como
um gerenciado por um empregador. O caminho online funciona num computador emprestado, e depende da
cota gratuita de uma única empresa, o que é um motivo para manter o seu trabalho num repositório que
você poderia levar para outro lugar.

A peça mais pesada é a imagem do OWASP ZAP, o scanner dinâmico da aula 4, com 3,8 GB. O cluster da
aula 10 também roda em contêineres e é a segunda mais pesada, e nenhuma aula precisa das duas
rodando ao mesmo tempo.

### Docker

Se o Docker ainda não está instalado, a aula 5 de `docker` faz isso passo a passo e diz para que
serve cada passo. No Ubuntu são o repositório de pacotes do próprio Docker e cinco comandos, que não
foram executados na gravação, porque a máquina já tinha o Docker Engine:

```sh
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update && sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin
sudo usermod -aG docker $USER
```

A última linha deixa o seu usuário falar com o Docker sem `sudo`, e vale a partir do próximo login.
A aula 16 volta a ela, porque estar nesse grupo vale tanto quanto ser root na máquina. git, curl e jq
vêm da distribuição: `sudo apt-get install git curl jq`.

Confira o que você tem. O grupo `docker` na segunda resposta é o que importa:

```
ana@vm:~$ docker version --format "client {{.Client.Version}}, server {{.Server.Version}}"
client 29.9.1, server 29.9.1
ana@vm:~$ id -nG
ana docker
ana@vm:~$ git --version
git version 2.43.0
ana@vm:~$ python3 --version
Python 3.13.16
```

### uv

O uv é um gerenciador de pacotes e projetos Python, e o curso o usa para criar ambientes virtuais e
instalar pacotes, porque ele é rápido e porque a aula 15 precisa dos arquivos de lock dele. O script
de instalação dele fica em astral.sh; a release no GitHub, com o checksum, faz a mesma coisa e
mostra cada passo:

```
ana@vm:~$ curl -fsSLO https://github.com/astral-sh/uv/releases/download/0.11.32/uv-x86_64-unknown-linux-gnu.tar.gz
ana@vm:~$ curl -fsSL https://github.com/astral-sh/uv/releases/download/0.11.32/uv-x86_64-unknown-linux-gnu.tar.gz.sha256 | sha256sum --check
uv-x86_64-unknown-linux-gnu.tar.gz: OK
ana@vm:~$ tar -xzf uv-x86_64-unknown-linux-gnu.tar.gz
ana@vm:~$ mkdir -p ~/.local/bin && install -m 755 uv-x86_64-unknown-linux-gnu/uv uv-x86_64-unknown-linux-gnu/uvx ~/.local/bin/
ana@vm:~$ rm -r uv-x86_64-unknown-linux-gnu*
ana@vm:~$ uv --version
uv 0.11.32 (x86_64-unknown-linux-gnu)
```

`~/.local/bin` entra no path de todo shell de login do Ubuntu assim que o diretório existe. Se `uv
--version` responder `command not found`, saia e entre de novo, ou rode `export
PATH=~/.local/bin:$PATH` no shell que você tem.

Os scanners das aulas seguintes vão para o mesmo diretório, do mesmo jeito: a release, o checksum,
`install`. Quando uma aula diz "instale", é isso que ela quer dizer, e ela mostra os comandos.

### Quem você é para o git

Todo commit registra um nome e um endereço. Configure os seus; a gravação usou os da Ana:

```
ana@vm:~$ git config --global user.name "Ana Lima"
ana@vm:~$ git config --global user.email ana@example.org
ana@vm:~$ git config --global init.defaultBranch main
```

A terceira linha faz de `main` o nome do primeiro branch de todo repositório novo, que é o nome que
o servidor de CI dos últimos passos desta aula espera.
