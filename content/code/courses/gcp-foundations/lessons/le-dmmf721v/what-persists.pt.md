---
title: O que persiste, e o que não
version: 1
---

**O seu diretório home persiste; a máquina não.** Cada sessão roda numa máquina nova feita da imagem do Google,
e o seu diretório home, um pequeno disco persistente de alguns gigabytes, é preso a ela. Tudo o que você salva
em `~` está lá da próxima vez. Todo o resto, um pacote instalado com `apt`, um arquivo em `/tmp`, um programa
deixado rodando, some quando a sessão acaba, porque a máquina em que estava some.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l23-sessions\" aria-label=\"Três sessões do Cloud Shell, segunda, terça e sexta, cada uma desenhada como uma máquina separada iniciada da imagem do Google. Cada uma guarda coisas que se perdem quando ela acaba: pacotes instalados com apt, arquivos em /tmp, programas rodando. Embaixo das três, um diretório home, um pequeno disco persistente, é preso a cada máquina por vez e guarda o que foi salvo nele, inclusive o .customize_environment, que roda como root a cada início. Uma nota diz que depois de muitas semanas sem uso o diretório home também é apagado.\"><rect x=\"20.0\" y=\"20.0\" width=\"210.0\" height=\"100.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"125.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">uma máquina nova</text><text x=\"125.0\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">segunda</text><text x=\"125.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">pacotes apt, /tmp,</text><text x=\"125.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">programas rodando: perdidos</text><path d=\"M125.0 122.0 L125.0 156.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"255.0\" y=\"20.0\" width=\"210.0\" height=\"100.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"360.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">uma máquina nova</text><text x=\"360.0\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">terça</text><text x=\"360.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">pacotes apt, /tmp,</text><text x=\"360.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">programas rodando: perdidos</text><path d=\"M360.0 122.0 L360.0 156.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"490.0\" y=\"20.0\" width=\"210.0\" height=\"100.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"595.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">uma máquina nova</text><text x=\"595.0\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">sexta</text><text x=\"595.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">pacotes apt, /tmp,</text><text x=\"595.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">programas rodando: perdidos</text><path d=\"M595.0 122.0 L595.0 156.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"20.0\" y=\"158.0\" width=\"680.0\" height=\"50.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"360.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">um diretório home, preso a cada uma por vez</text><text x=\"360.0\" y=\"194.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">~/.bashrc · ~/.config/gcloud · ~/.customize_environment</text><text x=\"360.0\" y=\"232.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">guardado entre sessões; apagado depois de muitas semanas sem uso</text></svg>", "caption": "A máquina é nova toda vez; só o diretório home volta."}
```

| | sobrevive à sessão |
|---|---|
| arquivos em `~`, inclusive `~/.bashrc` e `~/.config` | **sim** |
| as configurações do gcloud, que vivem em `~/.config/gcloud` | **sim** |
| pacotes instalados com `apt`, qualquer coisa fora de `~` | **não** |
| processos, inclusive um servidor que você iniciou | **não** |
| o próprio diretório home, depois de muitas semanas sem uso | **não**: o Google o apaga, depois de avisar por e-mail |

Essa última linha é a que as pessoas descobrem tarde demais. **O home do Cloud Shell não é um backup**: é um
espaço de rascunho que por acaso dura, e tudo o que importa pertence a um repositório ou a um bucket.

## Deixando-o do seu jeito a cada início

Um arquivo chamado `.customize_environment` no seu diretório home roda **como root, toda vez que a máquina
inicia**, em segundo plano. É assim que um pacote que a imagem não tem está lá em toda sessão sem ser instalado
à mão cada vez. Os engenheiros do planner mantêm este:

```sh
#!/bin/sh
# Run as root by Cloud Shell each time the machine starts.
apt-get update -qq
apt-get install -y -qq bind9-dnsutils jq
```

Ele não roda aqui: não há Cloud Shell neste curso para rodá-lo. Num real, a saída dele vai para um log em
`/var/log`, e um comando digitado antes de ele terminar pode ainda não achar o que ele instala.

## O laboratório deste curso caberia?

Uma pergunta que vale responder com uma medida em vez de um palpite. O que a lição 1 instalou no home do
laboratório, e tudo o que as lições desde então escreveram lá:

```
ana@laptop:~/gcp$ cd ~ && du -sh .local gcp
1008M	.local
268M	gcp
```

Cerca de um gigabyte e um quarto, a maior parte a instalação do gcloud, que o Cloud Shell já tem. O laboratório
caberia no home dele. O que não sobreviveria é o runtime Java de que o emulador precisa, instalado com `apt` fora
de `~`, que é o tipo de coisa para que o `.customize_environment` existe. E o curso continua sem usá-lo, pelo
motivo da lição 1.
