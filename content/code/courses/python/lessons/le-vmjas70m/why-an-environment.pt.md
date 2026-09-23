---
title: O interpretador que é do sistema operacional
version: 2
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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 256\" role=\"img\" aria-label=\"O Python da máquina é do sistema operacional e tem as ferramentas que dependem dele. Cada projeto tem um diretório próprio com as próprias cópias das suas bibliotecas, então dois projetos podem querer duas versões do mesmo pacote e nenhum toca no sistema.\"> <rect x=\"20\" y=\"30\" width=\"680\" height=\"36\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"360\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">o Python da própria máquina</text> <text x=\"360\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">o gerenciador de pacotes, a ferramenta de firewall, as configurações de impressão</text> <rect x=\"20\" y=\"112\" width=\"344\" height=\"34\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"192\" y=\"129\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">projeto a — .venv</text> <rect x=\"50\" y=\"154\" width=\"284\" height=\"30\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"192\" y=\"169\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">requests 2.31</text> <rect x=\"50\" y=\"192\" width=\"284\" height=\"30\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"192\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pandas 3.0</text> <rect x=\"376\" y=\"112\" width=\"344\" height=\"34\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"548\" y=\"129\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">projeto b — .venv</text> <rect x=\"406\" y=\"154\" width=\"284\" height=\"30\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"548\" y=\"169\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">requests 2.26</text> <rect x=\"406\" y=\"192\" width=\"284\" height=\"30\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"548\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">flask 3.1</text> <text x=\"360\" y=\"238\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">nenhum destes está no caminho do outro, e nenhum está no do sistema</text> </svg>", "caption": "A recusa em instalar no Python do sistema é o recurso. O que depende dele não é o seu programa."}
```

Distribuições mais antigas deixavam você fazer isso. O que acontecia então é a razão da mensagem:
um `pip install --upgrade requests` para o seu script, e uma ferramenta do sistema que parou de
funcionar uma hora depois, sem nenhuma ligação que alguém enxergasse entre as duas coisas.

## E a outra razão, que é sua

```localised
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
