---
title: SCAP, e um guia para a versão errada
version: 1
---

**SCAP é o formato que deixa um guia ser lido por um programa.** O Security Content Automation
Protocol é uma família de padrões do NIST: o XCCDF descreve uma lista de verificação de regras
agrupadas em perfis, o OVAL descreve como testar cada regra numa máquina e o CPE dá nome às
plataformas a que uma regra se aplica. Um guia publicado como conteúdo SCAP pode ser avaliado por
qualquer scanner SCAP, e o **OpenSCAP** é o de código aberto, empacotado pelo Ubuntu como `oscap`.

O conteúdo vem do projeto ComplianceAsCode, empacotado como `ssg-debderived`. Isto é o que o pacote
do Ubuntu 24.04 traz:

```
ana@web:~$ ls /usr/share/xml/scap/ssg/content/ | grep ds.xml
ssg-ubuntu1604-ds.xml
ssg-ubuntu1804-ds.xml
ssg-ubuntu2004-ds.xml
ssg-ubuntu2204-ds.xml
ana@web:~$ oscap info --profiles /usr/share/xml/scap/ssg/content/ssg-ubuntu2204-ds.xml
xccdf_org.ssgproject.content_profile_cis_level1_server:CIS Ubuntu 22.04 Level 1 Server Benchmark
xccdf_org.ssgproject.content_profile_cis_level1_workstation:CIS Ubuntu 22.04 Level 1 Workstation Benchmark
xccdf_org.ssgproject.content_profile_cis_level2_server:CIS Ubuntu 22.04 Level 2 Server Benchmark
xccdf_org.ssgproject.content_profile_cis_level2_workstation:CIS Ubuntu 22.04 Level 2 Workstation Benchmark
xccdf_org.ssgproject.content_profile_standard:Standard System Security Profile for Ubuntu 22.04
```

Um **data stream** (`-ds.xml`) é um arquivo só com a lista de verificação, os testes e os nomes de
plataforma juntos. Há um por versão do Ubuntu até a 22.04, e nenhum para a 24.04: o pacote do
repositório foi feito antes de existir conteúdo para a versão nova. O data stream do 22.04 oferece
cinco perfis, e dois deles são os perfis CIS Nível 1 e Nível 2 para servidores.

## Avaliando o errado

É tentador supor que as regras do 22.04 servem. Avalie o perfil CIS Nível 1 de servidor no `web` e
conte os resultados:

```
ana@web:~$ sudo oscap xccdf eval --profile cis_level1_server /usr/share/xml/scap/ssg/content/ssg-ubuntu2204-ds.xml | grep ^Result | sort | uniq -c
    291 Result
	notapplicable
```

Todas as regras do perfil voltaram como **notapplicable**. Nenhuma passou e nenhuma falhou: o scanner
não testou nada. O motivo é a plataforma que cada regra declara:

```
ana@web:~$ grep -o 'cpe:/o:canonical:ubuntu_linux:[0-9.]*' /usr/share/xml/scap/ssg/content/ssg-ubuntu2204-ds.xml | sort -u
cpe:/o:canonical:ubuntu_linux:16.04
cpe:/o:canonical:ubuntu_linux:18.04
cpe:/o:canonical:ubuntu_linux:20.04
cpe:/o:canonical:ubuntu_linux:22.04
ana@web:~$ grep VERSION_ID /etc/os-release
VERSION_ID="24.04"
```

O arquivo cita quatro versões do Ubuntu, a mais nova delas a 22.04, e a máquina é 24.04. O OpenSCAP
compara as duas antes de rodar um único teste e, sem nenhuma plataforma batendo, recusa o perfil
inteiro. Essa recusa é a resposta certa, e é a lição: **um guia é escrito para uma versão, e um
scanner que o aplicasse a outra informaria resultados que não querem dizer nada**, umas regras
testando arquivos que mudaram de lugar, outras passando porque um pacote mudou de nome.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" data-fig=\"l02-wrong-release\" aria-label=\"Por que todas as regras voltaram como não aplicáveis. O data stream do 22.04 tem 291 regras para o perfil CIS Nível 1 de servidor, e cada regra cita as plataformas a que se aplica, até o Ubuntu 22.04. Antes de qualquer teste, o OpenSCAP compara essa lista com a máquina, que é Ubuntu 24.04. Nenhuma plataforma bate, então o teste nunca roda e o resultado é notapplicable, para as 291 regras.\"><defs><marker id=\"l02-wrong-release-dh-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l02-wrong-release-dh-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"50.0\" width=\"200.0\" height=\"140.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"120.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">ssg-ubuntu2204-ds.xml</text><text x=\"120.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">291 regras no perfil</text><text x=\"120.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">cada uma vale para</text><text x=\"120.0\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ubuntu_linux:22.04</text><text x=\"120.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">(e anteriores)</text><rect x=\"270.0\" y=\"80.0\" width=\"180.0\" height=\"80.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">conferência de plataforma</text><text x=\"360.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">antes de qualquer teste</text><path d=\"M220.0 120.0 L270.0 120.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l02-wrong-release-dh-ah-paper-dim)\"></path><rect x=\"500.0\" y=\"50.0\" width=\"200.0\" height=\"60.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"600.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">web</text><text x=\"600.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">VERSION_ID=&quot;24.04&quot;</text><path d=\"M500.0 85.0 L450.0 105.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l02-wrong-release-dh-ah-paper-dim)\"></path><rect x=\"500.0\" y=\"140.0\" width=\"200.0\" height=\"60.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">291 notapplicable</text><text x=\"600.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">nada foi testado</text><path d=\"M450.0 140.0 L500.0 165.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l02-wrong-release-dh-ah-amber)\"></path></svg>", "caption": "O scanner recusou antes de medir. Um guia escrito para outra versão não tem resultado a dar."}
```

Há três caminhos honestos daqui, e nenhum foi executado aqui. Usar conteúdo feito para o 24.04, que o
ComplianceAsCode publica nas próprias versões e que um pacote mais novo vai trazer. Usar o `usg` da
Canonical, que traz perfis para o 24.04 com o Ubuntu Pro. Ou escrever você mesmo as verificações dos
controles que importam, que é a próxima seção. O que não é honesto é editar a linha de plataforma do
arquivo do 22.04 para fazer o scanner rodar.

## O que o SCAP dá quando serve

Quando o conteúdo bate com a versão, o mesmo comando produz aprovado ou reprovado por regra e um
relatório HTML com `--report`, e `--remediate` aplica as correções que o conteúdo traz. O formato é o
que torna um guia portátil: um auditor pode entregar a você a lista exata que vai usar, e você pode
rodá-la antes de ele chegar.
