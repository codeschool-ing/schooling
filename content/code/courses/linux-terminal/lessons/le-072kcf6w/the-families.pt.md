---
title: Quatro famílias e as independentes
version: 1
---

Cem distribuições não são cem coisas para aprender. Quase todas descendem de um punhado de
ancestrais, e **o que você herda de uma família é o gerenciador de pacotes, os nomes dos serviços e
o layout** — que é quase tudo o que você precisava saber.

Aprenda as famílias e uma distribuição desconhecida deixa de ser desconhecida.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Quatro cabeças de família no topo — Debian com apt, Red Hat com dnf, SUSE com zypper e Arch com pacman — cada uma com uma seta para baixo até um descendente: Ubuntu, Fedora, openSUSE e Manjaro. Duas seguem mais uma geração, até o Linux Mint e até Rocky e Alma. Uma faixa no pé lista as independentes, que não descendem de ninguém.\"><defs><marker id=\"ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"18\" y=\"26\" width=\"162\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"99.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" font-weight=\"600\" fill=\"var(--paper)\">Debian</text><text x=\"99.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">apt · .deb</text><rect x=\"192\" y=\"26\" width=\"162\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"273.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" font-weight=\"600\" fill=\"var(--paper)\">Red Hat</text><text x=\"273.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">dnf · .rpm</text><rect x=\"366\" y=\"26\" width=\"162\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"447.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" font-weight=\"600\" fill=\"var(--paper)\">SUSE</text><text x=\"447.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">zypper · .rpm</text><rect x=\"540\" y=\"26\" width=\"162\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"621.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" font-weight=\"600\" fill=\"var(--paper)\">Arch</text><text x=\"621.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">pacman</text><path d=\"M99 68 L99 104\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah)\"></path><rect x=\"18\" y=\"106\" width=\"162\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"99.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Ubuntu</text><path d=\"M273 68 L273 104\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah)\"></path><rect x=\"192\" y=\"106\" width=\"162\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"273.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Fedora</text><text x=\"273.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">upstream</text><path d=\"M447 68 L447 104\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah)\"></path><rect x=\"366\" y=\"106\" width=\"162\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"447.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">openSUSE</text><path d=\"M621 68 L621 104\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah)\"></path><rect x=\"540\" y=\"106\" width=\"162\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"621.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Manjaro</text><path d=\"M99 144 L99 178\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah)\"></path><rect x=\"18\" y=\"180\" width=\"162\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"99.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">Linux Mint · Pop!_OS</text><path d=\"M273 144 L273 178\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah)\"></path><rect x=\"192\" y=\"180\" width=\"162\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"273.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">Rocky · Alma</text><text x=\"273\" y=\"232\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">reconstruídas do RHEL, fonte por fonte</text><rect x=\"18\" y=\"252\" width=\"684\" height=\"34\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect><text x=\"40\" y=\"273\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">Sem pai</text><text x=\"232\" y=\"273\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Alpine · Gentoo · NixOS · Void · Slackware</text><text x=\"360\" y=\"306\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a família decide seu gerenciador de pacotes, seus serviços e metade dos caminhos</text></svg>", "caption": "Cem distribuições, quatro famílias e um punhado de independentes. O que você herda de uma família é o gerenciador de pacotes, o formato do pacote, os nomes dos serviços e o arcabouço de segurança — que é quase tudo o que você precisava saber."}
```

## As quatro que importam

**Debian**, e o descendente enorme dele, o Ubuntu. `apt` e pacotes `.deb`. Tocado por voluntários,
com uma constituição e um lançamento famosamente lento e cuidadoso. O Ubuntu é o produto de uma
empresa construído em cima dele, e entre os dois estão a suposição da maioria dos tutoriais. Seção
04.

**Red Hat**, e as reconstruções — Rocky e Alma — mais o Fedora rio acima de todas elas. `dnf` e
pacotes `.rpm`. Esta é a família corporativa: contratos de suporte, certificações, e os fabricantes
de software que publicam para ela e para mais nada. Seção 05, e ela tem uma história.

**SUSE**, com o openSUSE ao lado. `zypper` e `.rpm`. Menor que as outras duas e forte na Europa de
língua alemã, na indústria e em ambientes SAP. Seção 06.

**Arch**, e o Manjaro abaixo dele. `pacman`, lançamento contínuo, e a suposição de que você quer
montar a máquina você mesmo. A documentação dele — a Arch Wiki — é usada por gente que roda todas
as outras distribuições, que é a coisa mais útil de saber sobre ele.

## E as que não têm pai

Algumas distribuições foram escritas do zero em vez de derivadas:

| | por que existe |
|---|---|
| **Alpine** | para ser minúsculo. 5 MB, busybox, musl — e a razão de estar em contêiner em todo lugar. Seção 07 |
| **Gentoo** | você compila tudo, e escolhe as opções enquanto compila |
| **NixOS** | a máquina inteira é um arquivo declarativo, e mudanças voltam atrás |
| **Void, Slackware** | respostas próprias, e o Slackware é mais velho que tudo isso |

É improvável que te entreguem uma dessas no trabalho, e o Alpine é a exceção que você vai encontrar
na primeira semana em que tocar em Docker.

## O que "família" de fato te dá

Não é sentimento. Saber a família te diz quatro coisas antes de você olhar qualquer outra:

1. **O gerenciador de pacotes** — `apt` do lado do Debian, `dnf` do Red Hat, `zypper` do SUSE.
2. **O formato do pacote** — `.deb` ou `.rpm`, que decide o que a página de download de um
   fabricante oferece.
3. **As convenções de serviço e caminho** — `apache2` contra `httpd`, e qual diretório guarda.
4. **O arcabouço de segurança** — AppArmor do lado do Debian, SELinux do Red Hat. Aula 4.

É por isso que o `ID_LIKE` da seção 11 é o campo útil. Uma distribuição que você nunca ouviu falar e
que diz `ID_LIKE=debian` é uma cujos comandos você já conhece.

## Duas coisas que as pessoas acreditam e não são verdade

**Elas não são compatíveis no sentido de pacotes.** Um `.deb` não instala no Rocky, e `.rpm` não
instala no Ubuntu. Existem ferramentas para converter; são último recurso e a aula 7 diz isso.

**E derivada não quer dizer idêntica.** O Ubuntu é derivado do Debian e diverge de formas reais —
ciclo de lançamento próprio, repositórios próprios, snaps, e um `/etc/debian_version` que nomeia um
lançamento do Debian que você não está rodando. A seção 04 mostra esse arquivo mentindo para você
numa listagem.
