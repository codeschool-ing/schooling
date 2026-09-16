---
title: O mesmo comando em três dialetos
version: 1
---

Esta é a página para voltar. Nada aqui é novo; são as seções 04 a 11 postas lado a lado, para que
saber uma coluna signifique conseguir trabalhar nas outras duas.

## Os comandos do dia a dia

| | **apt** (Debian, Ubuntu) | **dnf** (RHEL, Rocky, Alma, Fedora) | **zypper** (SUSE) |
|---|---|---|---|
| atualizar os índices | `apt update` | *automático*; `dnf --refresh` | `zypper refresh` |
| instalar | `apt install X` | `dnf install X` | `zypper install X` |
| remover | `apt remove X` | `dnf remove X` | `zypper remove X` |
| remover com a configuração | `apt purge X` | *nenhum* — veja abaixo | *nenhum* |
| atualizar tudo | `apt upgrade` | `dnf upgrade` | `zypper update` |
| atualizar, podendo remover | `apt full-upgrade` | `dnf distro-sync` | `zypper dup` |
| o que seria atualizado | `apt list --upgradable` | `dnf check-update` | `zypper list-updates` |
| buscar | `apt search X` | `dnf search X` | `zypper search X` |
| detalhes | `apt show X` | `dnf info X` | `zypper info X` |
| o que está instalado | `apt list --installed` | `dnf list installed` | `zypper search -i` |
| largar dependências não usadas | `apt autoremove` | `dnf autoremove` | `zypper packages --unneeded` |
| listar repositórios | `apt policy` | `dnf repolist` | `zypper repos` |
| acrescentar um repositório | editar `sources.list.d/` | editar `yum.repos.d/` | `zypper addrepo` |
| segurar uma versão | `apt-mark hold X` | `dnf versionlock add X` | `zypper addlock X` |
| qual pacote possui um arquivo | `dpkg -S /caminho` | `rpm -qf /caminho` | `rpm -qf /caminho` |
| qual pacote **forneceria** | `apt-file search X` | `dnf provides '*/X'` | `zypper se --provides X` |
| arquivos de um pacote | `dpkg -L X` | `rpm -ql X` | `rpm -ql X` |
| instalar um arquivo local | `apt install ./f.deb` | `dnf install ./f.rpm` | `zypper install ./f.rpm` |
| a camada de baixo | `dpkg -i f.deb` | `rpm -i f.rpm` | `rpm -i f.rpm` |
| registro de transações | `/var/log/apt/history.log` | `dnf history` | `/var/log/zypp/history` |

**As linhas do `rpm -qf` e do `rpm -ql` se repetem de propósito.** O dnf e o zypper são duas
interfaces sobre um banco de dados, então toda consulta `rpm` da seção 10 funciona sem mudança no
SUSE.

## As quatro diferenças que não são só grafia

**1. O `purge` existe só do lado Debian.** O apt distingue "remova o programa" de "remova o programa
e a configuração dele", e acompanha o estado intermediário como `rc`. O rpm não tem esse estado: ele
remove o pacote e deixa arquivos de configuração editados para trás como `.rpmsave`. A seção 08 tem
os dois.

**2. O `apt update` é um passo separado e o do `dnf` não é.** O dnf expira os próprios metadados num
temporizador, então um `dnf install` depois de uma semana busca índices novos sozinho. Não existe
equivalente de rodar o `upgrade` contra o catálogo de ontem.

**3. O padrão da confirmação difere.** O apt pergunta `[Y/n]` e o zypper pergunta `(y)` — Enter quer
dizer sim. O dnf pergunta `[y/N]` — Enter quer dizer não. **Três ferramentas, e um hábito construído
numa delas está errado noutra**, o que vale um instante de cuidado nas primeiras vezes num sistema
desconhecido.

**4. O `zypper dup` numa versão rolling.** Seção 11: no Tumbleweed a atualização de rotina é o
`dup`, não o `up`, e usar o errado por meses produz uma máquina genuinamente quebrada. Não há nada
parecido nas outras duas.

## Os arquivos

| | apt | dnf | zypper |
|---|---|---|---|
| definições de repositório | `/etc/apt/sources.list.d/` | `/etc/yum.repos.d/` | `/etc/zypp/repos.d/` |
| chaves de assinatura | `/etc/apt/keyrings/` | `gpgkey=` no arquivo do repo | `/etc/pki/trust/` |
| o banco do que está instalado | `/var/lib/dpkg/` | `/var/lib/rpm/` | `/var/lib/rpm/` |
| pacotes baixados | `/var/cache/apt/archives/` | `/var/cache/dnf/` | `/var/cache/zypp/` |
| pins e prioridades | `/etc/apt/preferences.d/` | `priority=` no arquivo do repo | `priority=` no arquivo do repo |

**Os diretórios de cache valem ser conhecidos por um motivo**: eles enchem. O `apt clean`, o `dnf
clean all` e o `zypper clean` os esvaziam, e num sistema de arquivos raiz pequeno isso é às vezes a
diferença entre uma atualização funcionar e não.

## Lendo um comando que você nunca viu

Quase tudo se reduz a quatro perguntas, e as formas são estáveis nos três:

| | |
|---|---|
| **um verbo** | install, remove, search, update, info |
| **um alvo** | um nome de pacote, ou um caminho, ou nada |
| **uma opção de escopo** | `-i`/`--installed`, `--available`, `-a` |
| **uma opção de "não faça de verdade"** | `apt --dry-run`, `dnf --assumeno`, `zypper install --dry-run` |

**Essa última linha é a de usar num sistema desconhecido.** Quando você não tem certeza do que um
comando vai fazer numa distribuição que não usa todo dia, peça que ele te conte em vez de adivinhar
— cada um dos três tem um jeito de imprimir o plano e parar.
