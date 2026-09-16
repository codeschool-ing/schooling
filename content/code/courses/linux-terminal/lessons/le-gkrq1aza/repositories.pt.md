---
title: Repositórios, e por que `update` não é `upgrade`
version: 1
---

Um repositório é um servidor web com pacotes nele e um **índice** descrevendo-os. A sua máquina
guarda uma lista de repositórios, uma cópia de cada índice, e nada mais até você pedir algo.

É esse o modelo inteiro, e ele explica o comando que as pessoas erram primeiro:

| | |
|---|---|
| `apt update` | buscar os **índices** de novo. Não muda nenhum pacote instalado |
| `apt upgrade` | instalar versões mais novas do que você já tem |

**O `update` baixa um catálogo; o `upgrade` age sobre ele.** Rodar o `upgrade` sem o `update` usa o
catálogo de ontem e não reporta nada a fazer, que é de onde vem o "mas eu atualizei".

## Onde a lista mora

```
root@vm:~# ls /etc/apt/sources.list.d/
deadsnakes-ubuntu-ppa-noble.sources  docker.list  ondrej-ubuntu-php-noble.sources  ubuntu.sources
root@vm:~# cat /etc/apt/sources.list.d/docker.list
deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu   n
oble stable
```

Uma linha, e cada parte dela importa:

| | |
|---|---|
| `deb` | pacotes binários. `deb-src` seria fonte |
| `[arch=amd64 signed-by=…]` | opções: qual arquitetura, e **qual chave assina isto** |
| `https://download.docker.com/linux/ubuntu` | o servidor |
| `noble` | a **suíte** — aqui, a versão do Ubuntu para a qual isto é |
| `stable` | o **componente**. Os do Ubuntu são `main`, `universe`, `restricted`, `multiverse` |

Nas fontes do próprio Ubuntu os quatro componentes valem ser conhecidos: o `main` tem suporte da
Canonical, o `universe` é mantido pela comunidade, o `restricted` são drivers não livres, o
`multiverse` é todo o resto. **O `cowsay` da seção 02 veio do `universe`**, que é a resposta honesta
para "isto tem suporte" numa quantidade enorme do que as pessoas instalam.

Os arquivos `.sources` mais novos guardam os mesmos campos um por linha em vez de um por arquivo.
Mesma informação, mais fácil de ler, e você vai encontrar os dois.

## O `signed-by`, que é a segurança de repositório inteira

Todo índice é assinado. A sua máquina confere a assinatura contra uma chave que já tem, e recusa o
repositório se não conseguir. **É por isso que acrescentar um repositório de terceiro são dois
passos** — a chave, e depois a linha de fonte — e por que as instruções que você copia da página de
um fornecedor sempre têm os dois.

O `signed-by=` prende uma chave a um repositório, que é a parte que mudou e que importa: uma chave no
antigo `trusted.gpg` global podia assinar pacotes para *qualquer* repositório da máquina. Agora o
`/etc/apt/keyrings/docker.asc` responde pelo repositório do Docker e por mais nada.

**Você vai ver `apt-key add` em instruções antigas na internet. Ele está obsoleto e é o que o
`signed-by` substituiu.** Se uma página manda rodá-lo, a página é velha o bastante para o resto dela
também merecer conferência.

## O `apt update`, lido linha por linha

```
root@vm:~# apt update
Err:1 https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu noble InRelease
  403  Forbidden [IP: 185.125.189.187 443]
Err:2 https://ppa.launchpadcontent.net/ondrej/php/ubuntu noble InRelease
  403  Forbidden [IP: 185.125.189.187 443]
Get:3 https://download.docker.com/linux/ubuntu noble InRelease [48.5 kB]
Hit:4 http://archive.ubuntu.com/ubuntu noble InRelease
Get:5 http://archive.ubuntu.com/ubuntu noble-updates InRelease [126 kB]
Get:6 http://security.ubuntu.com/ubuntu noble-security InRelease [126 kB]
Hit:7 http://archive.ubuntu.com/ubuntu noble-backports InRelease
Get:8 http://archive.ubuntu.com/ubuntu noble-updates/main amd64 Packages [1566 kB]
Get:9 http://archive.ubuntu.com/ubuntu noble-updates/universe amd64 Packages [2152 kB]
Reading package lists... Done
E: Failed to fetch https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu/dists/noble/InRelease  403
  Forbidden [IP: 185.125.189.187 443]
E: The repository 'https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu noble InRelease' is no lon
ger signed.
N: Updating from such a repository can't be done securely, and is therefore disabled by default.
N: See apt-secure(8) manpage for repository creation and user configuration details.
E: Failed to fetch https://ppa.launchpadcontent.net/ondrej/php/ubuntu/dists/noble/InRelease  403  Fo
rbidden [IP: 185.125.189.187 443]
E: The repository 'https://ppa.launchpadcontent.net/ondrej/php/ubuntu noble InRelease' is no longer
signed.
N: Updating from such a repository can't be done securely, and is therefore disabled by default.
N: See apt-secure(8) manpage for repository creation and user configuration details.
```

Três palavras carregam a listagem inteira:

| | |
|---|---|
| `Hit` | sem mudança desde a última vez; nada baixado |
| `Get` | mudou, então foi buscado, com o tamanho |
| `Err` | não funcionou, e tudo depois do `E:` é o porquê |

**E esta execução tem duas falhas reais**, o que é mais sorte do que parece, porque este erro é um
dos dois que você de fato vai encontrar.

O que aconteceu aqui é específico: esta máquina alcança a rede por um proxy que devolve `403
Forbidden` para aquelas duas PPAs. O apt não conseguiu buscar o `InRelease` — o arquivo assinado — e
`no longer signed` é o que o apt diz quando o índice assinado está faltando, seja qual for o motivo.
**A mensagem nomeia a consequência, não a causa.**

Isso vale saber porque as mesmas quatro linhas aparecem quando a causa é completamente outra: um
repositório cuja chave de assinatura expirou, um espelho servindo uma cópia sem assinatura, uma URL
que agora redireciona para uma página de erro. A mensagem é idêntica e o conserto não é.

Então, quando você vir `is no longer signed`, **leia primeiro a linha `E: Failed to fetch` acima
dela**. `403` e `404` são respostas de rede e um problema de chave não é. Um problema de chave mostra
`NO_PUBKEY` e um id de chave em hexadecimal.

**E repare no que não aconteceu: nada foi instalado nem atualizado.** Dois repositórios falharam,
sete funcionaram, e a máquina está exatamente como estava. O `update` só escreve num cache.

## O resto do vocabulário

```
apt update                 # refresh the indexes
apt upgrade                # newer versions of what is installed
apt full-upgrade           # the same, but allowed to remove things to do it
apt list --upgradable      # what upgrade would do, before doing it
```

**O `apt list --upgradable` é o que rodar primeiro**, toda vez. É a simulação, é instantâneo, e
transforma "168 not upgraded" de um número numa lista que dá para ler.

O `full-upgrade` — `dist-upgrade` em instruções mais antigas — difere do `upgrade` num ponto e é
importante: o `upgrade` puro nunca vai remover um pacote para viabilizar uma atualização, e o
`full-upgrade` vai. Num servidor, rode o `upgrade`, leia o que ele segurou, e decida sobre esses à
mão.

Do lado rpm a mesma divisão existe com outras palavras: o `dnf check-update` lista, o `dnf upgrade`
age, e não há passo de `update` separado porque o dnf atualiza os metadados sozinho quando o cache
está velho. A seção 10 é essa diferença por inteiro.
