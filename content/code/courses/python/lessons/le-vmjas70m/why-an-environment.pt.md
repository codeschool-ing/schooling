---
title: O interpretador que é do sistema operacional
version: 1
---

```sh
/usr/bin/python3 -m pip install requests
```

```sh
error: externally-managed-environment

× This environment is externally managed
╰─> To install a package, create a virtual environment.

note: You can override this, at the risk of breaking your Python installation
      or OS, by passing --break-system-packages.
hint: See PEP 668 for the detailed specification.
```

**A recusa é o recurso.** No Debian, no Ubuntu e no Fedora o Python do sistema é dependência do
próprio sistema operacional — gerenciadores de pacote, configuração de impressora, ferramentas de
firewall. Atualizar uma biblioteca embaixo dele muda a versão que esses programas importam.

Distribuições mais antigas deixavam você fazer isso. O que acontecia então é a razão da mensagem:
um `pip install --upgrade requests` para o seu script, e uma ferramenta do sistema que parou de
funcionar uma hora depois, sem nenhuma ligação que alguém enxergasse entre as duas coisas.

## E a outra razão, que é sua

```sh
projeto-a/   precisa de requests 2.26
projeto-b/   precisa de requests 2.31
```

Uma instalação global guarda uma versão. Com os dois projetos instalados nela, um deles está
quebrado, e qual depende da ordem em que alguém instalou.

## O que é um ambiente

Um diretório contendo o próprio `bin`, o próprio `lib/python3.x/site-packages`, e um arquivo de
configuração pequeno. Ativá-lo põe aquele `bin` na frente do seu `PATH`, então `python` quer dizer
aquele, e o interpretador que ele inicia lê só aquele `site-packages`.

**Não é um sandbox.** Ele não isola o sistema de arquivos, a rede nem os processos — ele isola
quais bibliotecas o `import` consegue achar, que é a única coisa de que este problema trata.

## `--break-system-packages`

Existe, faz exatamente o que diz, e o único uso defensável dele é um contêiner que você montou e
vai jogar fora. Numa máquina em que você trabalha, um ambiente virtual custa cinco segundos e esta
flag custa uma tarde em algum ponto do ano que vem.
