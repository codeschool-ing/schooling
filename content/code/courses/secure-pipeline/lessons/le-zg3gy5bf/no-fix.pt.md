---
title: Achados que ninguém consegue corrigir ainda, e achados contados quatro vezes
version: 1
---

A imagem distroless é a melhor das três candidatas e o relatório dela ainda diz 162. Quem lê esse
número pela primeira vez quer saber quais corrigir nesta semana. **A resposta é nenhum, e o
relatório diz por quê, se for lido por coluna e não pelo total.** Duas colunas decidem: o status de
cada achado e o pacote em que ele foi encontrado.

### A coluna de status

```
ana@vm:~/scans$ jq -r '[.Results[].Vulnerabilities[].Status] | group_by(.) | map("\(length) \(.[0])")[]' distroless.json
149 affected
1 fix_deferred
12 will_not_fix
ana@vm:~/scans$ jq -r '.Results[].Vulnerabilities[] | select(.Status != "affected") | "\(.Status)  \(.PkgName)  \(.VulnerabilityID)  \(.Severity)"' distroless.json | sort | head -n 13
fix_deferred  libexpat1  CVE-2025-66382  MEDIUM
will_not_fix  libpython3.13-minimal  CVE-2025-12781  MEDIUM
will_not_fix  libpython3.13-minimal  CVE-2025-15366  MEDIUM
will_not_fix  libpython3.13-minimal  CVE-2025-15367  MEDIUM
will_not_fix  libpython3.13-stdlib  CVE-2025-12781  MEDIUM
will_not_fix  libpython3.13-stdlib  CVE-2025-15366  MEDIUM
will_not_fix  libpython3.13-stdlib  CVE-2025-15367  MEDIUM
will_not_fix  python3.13-minimal  CVE-2025-12781  MEDIUM
will_not_fix  python3.13-minimal  CVE-2025-15366  MEDIUM
will_not_fix  python3.13-minimal  CVE-2025-15367  MEDIUM
will_not_fix  python3.13-venv  CVE-2025-12781  MEDIUM
will_not_fix  python3.13-venv  CVE-2025-15366  MEDIUM
will_not_fix  python3.13-venv  CVE-2025-15367  MEDIUM
```

Uma distribuição não publica um pacote corrigido no dia em que um aviso aparece. Ela decide, por
versão, se e quando corrigir, e o Trivy registra essa decisão no status de cada achado:

| status | o que a distribuição disse | o que um rebuild consegue fazer |
|---|---|---|
| `fixed` | uma versão mais nova do pacote traz a correção | pegá-la: o próximo build sobre uma imagem base que a tenha |
| `affected` | o pacote é vulnerável e ainda não há correção publicada para esta versão | nada até a correção sair |
| `fix_deferred` | uma correção está prevista e foi adiada, em geral para a próxima versão pontual | nada até lá |
| `will_not_fix` | não será corrigido nesta versão, em geral porque o impacto é pequeno | nada, nunca, nesta versão |

**149 dos 162 são `affected`, e nenhum é `fixed`.** É assim que uma base atual e mantida se parece. O
time de segurança de uma distribuição publica correções para o que é grave e explorável no uso comum
de um pacote, e deixa boa parte do resto para a próxima versão; o tracker lista as duas coisas com o
mesmo peso. As treze linhas que não são `affected` são uma correção adiada na `libexpat1` e três
avisos sobre o Python 3.13, cada um reportado contra quatro pacotes. Um portão que quebrasse o build
por qualquer uma delas poderia ficar vermelho até o Debian 14, fizesse quem fizesse o que fosse, e a
aula 7 já disse o que acontece com um portão impossível de satisfazer: alguém o desliga.

### Um CVE, quatro pacotes

O mesmo CVE aparecendo em quatro linhas não são quatro vulnerabilidades:

```
ana@vm:~/scans$ jq "[.Results[].Vulnerabilities[].VulnerabilityID] | unique | length" distroless.json
64
ana@vm:~/scans$ jq -r '.Results[].Vulnerabilities[] | select(.VulnerabilityID == "CVE-2024-26458") | "\(.PkgName) \(.InstalledVersion) \(.Status)"' distroless.json
libgssapi-krb5-2 1.21.3-5+deb13u1 affected
libk5crypto3 1.21.3-5+deb13u1 affected
libkrb5-3 1.21.3-5+deb13u1 affected
libkrb5support0 1.21.3-5+deb13u1 affected
ana@vm:~/scans$ jq -r '.Results[].Packages[] | select(.SrcName == "krb5") | "\(.Name) is built from \(.SrcName)"' distroless.json
libgssapi-krb5-2 is built from krb5
libk5crypto3 is built from krb5
libkrb5-3 is built from krb5
libkrb5support0 is built from krb5
ana@vm:~/scans$ jq -r '(.Results[0].Packages | map({(.Name): .SrcName}) | add) as $src | [.Results[0].Vulnerabilities[] | $src[.PkgName]] | group_by(.) | map("\(length) \(.[0])")[]' distroless.json | sort -rn
68 python3.13
42 glibc
24 krb5
8 gcc-14
6 util-linux
4 sqlite3
4 ncurses
2 zlib
2 libtirpc
1 expat
1 bzip2
```

**162 achados são 64 CVEs distintos.** O Debian constrói vários pacotes binários a partir de um
pacote-fonte: a biblioteca Kerberos `krb5` vira `libgssapi-krb5-2`, `libk5crypto3`, `libkrb5-3` e
`libkrb5support0`, e um aviso contra a fonte é reportado contra os quatro. Quando o Debian corrige,
um upload corrige os quatro, e quando não corrige, nenhum deles muda. O último comando agrupa os 162
achados por fonte: **onze pacotes-fonte, e dois deles, Python e glibc, concentram 110 dos achados.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"sp-l08-dupes\" aria-label=\"Um aviso, CVE-2024-26458, reportado quatro vezes: contra libgssapi-krb5-2, libk5crypto3, libkrb5-3 e libkrb5support0, quatro pacotes binários que o Debian constrói a partir de um pacote-fonte, krb5. Uma correção no krb5 corrige os quatro. Na imagem distroless inteira, 162 achados são 64 CVEs distintos em 11 pacotes-fonte.\"><defs><marker id=\"sp-l08-dupes-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"sp-l08-dupes-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"80\" width=\"160\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">CVE-2024-26458</text><text x=\"100.0\" y=\"117.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um aviso</text><rect x=\"250\" y=\"20\" width=\"450\" height=\"180\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"264\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">pacote-fonte</text><text x=\"380\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">krb5</text><rect x=\"270\" y=\"58\" width=\"195\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"367.5\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">libgssapi-krb5-2</text><rect x=\"485\" y=\"58\" width=\"195\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"582.5\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">libk5crypto3</text><rect x=\"270\" y=\"118\" width=\"195\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"367.5\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">libkrb5-3</text><rect x=\"485\" y=\"118\" width=\"195\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"582.5\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">libkrb5support0</text><path d=\"M180 108 L248 108\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l08-dupes-ah-amber)\"></path><text x=\"475\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">um upload do krb5 corrige os quatro</text><rect x=\"60\" y=\"222\" width=\"160\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"140.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">162</text><text x=\"140.0\" y=\"257.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">achados (linhas)</text><rect x=\"280\" y=\"222\" width=\"160\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">64</text><text x=\"360.0\" y=\"257.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">CVEs distintos</text><path d=\"M222 248 L278 248\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l08-dupes-ah-paper-dim)\"></path><rect x=\"500\" y=\"222\" width=\"160\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"580.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">11</text><text x=\"580.0\" y=\"257.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">pacotes-fonte</text><path d=\"M442 248 L498 248\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l08-dupes-ah-paper-dim)\"></path></svg>", "caption": "Uma linha do relatório é um par de aviso e pacote, então um aviso contra um pacote-fonte conta uma vez para cada pacote construído a partir dele."}
```

Contar linhas exagera o trabalho em cerca de duas vezes e meia aqui, e engana de um segundo jeito: um
relatório que cai de 162 para 158 pode ter corrigido um CVE, e não quatro. Quando uma métrica feita
desses relatórios importa (a aula 20 monta várias), conte CVEs distintos por pacote-fonte, e não
linhas.

### O que o portão faz com tudo isso

O estágio de imagem que esta aula acrescenta quebra o build por um achado alto ou crítico com versão
corrigida, e só conta o resto. Essa regra sai da tabela acima e do julgamento da aula 7: **um achado
que um rebuild corrige é de quem escreveu a mudança, para corrigir agora; um achado que nenhum
rebuild corrige é um fato sobre a imagem base, e pertence a quem escolhe a base.**

Contar não é ignorar. O estágio escreve o total no log de toda execução, então uma mudança na imagem
base que acrescente cinquenta achados aparece como um número que mexeu. E três tipos de evento
transformam uma contagem de volta em trabalho:

- **um status muda para `fixed`**: o Debian publicou o pacote, os mantenedores da imagem base a
  reconstroem com ele, e o próximo build do linkbox sobre a base nova o instala. A última seção desta
  aula trata de garantir que esse build aconteça;
- **sabe-se que um aviso está sendo explorado**, que é a pergunta do CISA KEV da aula 5. Um
  `will_not_fix` numa biblioteca que o linkbox carrega, com exploração conhecida, é motivo para
  trocar de imagem base ou aplicar um patch, diga o portão o que disser;
- **a imagem base deixa de ser mantida.** `affected` numa versão com suporte quer dizer que uma
  correção pode vir. Numa versão que passou do fim da vida nada vem, e o Trivy avisa que o próprio
  sistema operacional não tem mais suporte.

Leia o aviso antes de concluir que uma contagem é inofensiva, que é a pergunta de alcançabilidade da
aula 5 feita sobre o sistema operacional em vez do PyPI. Dos três avisos do Python acima, dois são
sobre `imaplib` e `poplib`, que nada no linkbox importa. O terceiro é sobre `base64.b64decode()`
aceitar `+` e `/` quando foi instruído a usar outros caracteres, e esse pede mais que uma olhada: o
`base64` é importado por boa parte do PyPI, inclusive pelo `itsdangerous`, uma das dependências do
Flask.
