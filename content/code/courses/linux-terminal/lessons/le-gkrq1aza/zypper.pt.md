---
title: `zypper`, no SUSE e no openSUSE
version: 1
---

O SUSE usa arquivos `.rpm` e o `rpm` por baixo, exatamente como a seção 112 descreveu — e uma
ferramenta diferente por cima. Tudo o que você aprendeu sobre `rpm -q` se aplica aqui sem mudança; só
a camada de cima tem palavras novas.

**A mesma ressalva da seção 112**: estas transcrições foram capturadas no Ubuntu com o `zypper`
instalado e o repositório da aula configurado. Os comandos e a saída deles são reais; a distribuição
não é SUSE, e o único lugar em que isso aparece é apontado abaixo.

## Repositórios

```
root@vm:~# zypper repos
Repository priorities are without effect. All enabled repositories share the same priority.

# | Alias    | Name     | Enabled | GPG Check | Refresh
--+----------+----------+---------+-----------+--------
1 | teaching | teaching | Yes     | (  ) No   | No
```

O `zypper repos` — `zypper lr` para encurtar — é o `dnf repolist`. Repare nas colunas: **o zypper
mostra prioridade e estado de refresh na listagem**, o que o dnf não faz, e a primeira linha é ele te
dizendo que com um repositório só as prioridades não podem importar.

Acrescentar e atualizar:

```
zypper addrepo <url> <alias>        # zypper ar
zypper refresh                      # zypper ref — this one IS like apt update
zypper removerepo <alias>           # zypper rr
zypper modifyrepo --disable <alias>
```

**O `zypper refresh` é mais parecido com o `apt update` do que o comportamento do dnf é.** O zypper
atualiza automaticamente quando um repositório está marcado `Refresh: Yes`, e o da aula não está,
então foi feito à mão. Numa máquina SUSE normal os repositórios da distribuição vêm com auto-refresh.

Todo comando do zypper tem uma forma curta de duas letras — `lr`, `ar`, `ref`, `in`, `rm`, `se`,
`if`, `up`, `dup`. **A documentação do SUSE é escrita nelas**, então as formas longas abaixo são para
ler e as curtas são o que você vai ver.

## Achar e ler

```
root@vm:~# zypper search greet
Loading repository data...
Reading installed packages...

S | Name        | Summary                                         | Type
--+-------------+-------------------------------------------------+--------
  | greet       | Print a greeting, for teaching package managers | package
  | greet-tools | Extra commands that need greet                  | package
```

**A coluna `S` é o estado**, e é o que ler: em branco é disponível, `i` é instalado, `i+` é instalado
porque você pediu e não como dependência. Ela aparece de novo abaixo.

```
root@vm:~# zypper info greet
Information for package greet:
------------------------------
Repository     : teaching
Name           : greet
Version        : 1.2.0-1
Arch           : noarch
Vendor         :
Installed Size : 66 B
Installed      : No
Status         : not installed
Source package : greet-1.2.0-1.src
Summary        : Print a greeting, for teaching package managers
Description    :
    A two-line shell script that prints a greeting. It exists so that a
    package manager has something real to install, remove and query.
```

O `Installed: No` e o `Status: not installed` dizem a mesma coisa duas vezes, o que é o zypper sendo
explícito e não confuso. O `Vendor` está vazio aqui porque estes pacotes foram construídos sem um;
num sistema real ele diz `SUSE LLC` ou o terceiro que o construiu, e **o `zypper` usa o vendor para
decidir se uma atualização pode trocar a origem de um pacote.**

## Instalar

```
root@vm:~# zypper install greet-tools
Loading repository data...
Reading installed packages...
Resolving package dependencies...

The following 2 NEW packages are going to be installed:
  greet greet-tools

2 new packages to install.
Overall download size: 12.6 KiB. Already cached: 0 B. After the operation, additional 89.0 B will be
used.
Continue? [y/n/v/...? shows all options] (y): y
Retrieving: greet-1.2.0-1.noarch (teaching)                                     (1/2),   6.4 KiB
Retrieving: greet-tools-0.3.0-1.noarch (teaching)                               (2/2),   6.2 KiB

Checking for file conflicts: .................................................................[done]
rpm: RPM should not be used directly install RPM packages, use Alien instead!
rpm: However assuming you know what you are doing...
(1/2) Installing: greet-1.2.0-1.noarch .......................................................[done]
rpm: RPM should not be used directly install RPM packages, use Alien instead!
rpm: However assuming you know what you are doing...
(2/2) Installing: greet-tools-0.3.0-1.noarch .................................................[done]
root@vm:~# greet-twice
hello from greet 1.2.0
hello from greet 1.2.0
```

A dependência foi resolvida e trazida junto, como em todo lugar. Três coisas são do zypper:

**`Continue? [y/n/v/...? shows all options] (y)`** — o padrão é `y`, como no apt e diferente do dnf,
e o `v` mostra os números de versão completos antes de você decidir. Digitar `?` lista o resto.

**`Checking for file conflicts:`** é um passo que nem o apt nem o dnf anunciam. O zypper verifica que
nenhum par de pacotes quer escrever o mesmo caminho antes de escrever qualquer coisa.

**Aquelas linhas `rpm:` são o artefato de Ubuntu**, o mesmo aviso de invólucro da seção 112. O zypper
está chamando o `rpm`, e o `rpm` do Debian está o repreendendo. No SUSE elas não estão lá.

## Qual pacote possui um arquivo

```
root@vm:~# zypper search --provides --file-list /usr/bin/greet
Loading repository data...
Reading installed packages...

S  | Name        | Summary                                         | Type
---+-------------+-------------------------------------------------+--------
i  | greet       | Print a greeting, for teaching package managers | package
i+ | greet-tools | Extra commands that need greet                  | package
```

O `zypper se --provides --file-list` — normalmente escrito `zypper se --provides` — busca em listas
de arquivos em vez de nomes. **E agora a coluna `S` tem conteúdo**: `i` para o `greet`, que entrou
como dependência, e `i+` para o `greet-tools`, que foi o pedido.

Aquele `+` é a mesma distinção do `apt-mark showmanual` da seção 108, guardada na listagem onde dá
para ver em vez de num comando separado.

O `rpm -qf /usr/bin/greet` também funciona aqui, e é mais curto.

## Remover

```
root@vm:~# zypper remove greet
Reading installed packages...
Resolving package dependencies...

The following 2 packages are going to be REMOVED:
  greet greet-tools

2 packages to remove.
After the operation, 89.0 B will be freed.
Continue? [y/n/v/...? shows all options] (y): y
(1/2) Removing greet-tools-0.3.0-1.noarch ....................................................[done]
(2/2) Removing greet-1.2.0-1.noarch ..........................................................[done]
Problem occurred during or after installation or removal of packages:
Failed to cache rpm database (1).
History:
 - 'rpmdb2solv' '-r' '/' '-D' '/var/lib/rpm' '-X' '-p' '/etc/products.d' '/var/cache/zypp/solv/@Syst
em/solv' '-o' '/var/cache/zypp/solv/@System/solvpCAveU'
   rpmdb2solv: no error

Please see the above error message for a hint.
root@vm:~# greet-twice
bash: greet-twice: command not found
```

Os dois pacotes removidos, pelo motivo que a seção 108 deu, e então **um erro que é desta máquina e
não do zypper**. O `rpmdb2solv` constrói o cache do zypper para o banco de dados de pacotes
instalados, e ele precisa do `/etc/products.d` — um diretório que descreve quais produtos SUSE estão
instalados, que uma máquina Ubuntu não tem.

Ele fica aí porque a alternativa é citar uma transcrição com uma linha removida. **A remoção em si
funcionou**: o `greet-twice` sumiu logo em seguida. No SUSE este bloco não aparece.

## O `up` contra o `dup`, que é a única diferença de verdade

```
zypper update              # zypper up  — newer versions, without changing vendors
zypper dist-upgrade        # zypper dup — the whole distribution, vendor changes allowed
```

Numa versão fixa — Leap, SLES — o `zypper up` é o de rotina e se comporta como o `apt upgrade`.

**No Tumbleweed, a versão rolling, o `zypper dup` é o de rotina e o `up` está errado.** Uma
distribuição rolling substitui conjuntos inteiros de pacotes de uma vez, e o `up` recusa as mudanças
de vendor e arquitetura que isso exige. Rodar o `up` no Tumbleweed por alguns meses produz uma
máquina meio atualizada de um jeito que nada mais nesta aula consegue produzir.

Esse é o fato mais específico de SUSE desta seção, e é o que as pessoas erram.

## O resto

```
zypper patches             # security patches specifically, as a list
zypper patch               # apply them, and only them
zypper ps                  # what is running that needs restarting after an update
zypper addlock <package>   # the hold from section 111; zypper locks lists them
zypper packages --unneeded # the autoremove candidates
```

**O `zypper ps` merece a linha dele.** Depois de uma atualização, ele lista os processos ainda
rodando código de arquivos que foram substituídos — os serviços que precisam ser reiniciados antes de
a atualização realmente valer:

```
root@vm:~# zypper --non-interactive ps 2>&1 | head -6
No processes using deleted files found.

No core libraries or services have been updated since the last system boot.
Reboot is probably not necessary.
```

Nada a fazer aqui, que é a resposta que você quer — e leia a primeira linha contra a seção 98.
**"Processos usando arquivos apagados" é exatamente a situação do descritor aberto num arquivo
apagado**, e é assim que ela fica quando um gerenciador de pacotes a usa de propósito: uma biblioteca
substituída no disco enquanto algo ainda tem a antiga aberta é um serviço rodando código que não
existe mais.

O pacote `needrestart` do Debian faz o mesmo trabalho; o zypper já vem com ele.
