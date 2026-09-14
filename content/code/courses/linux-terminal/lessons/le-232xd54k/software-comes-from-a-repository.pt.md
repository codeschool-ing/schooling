---
title: Software que você não baixa
version: 1
---

No Windows e no macOS, instalar algo é achar o site, baixar um arquivo, executar, e confiar em quem
o fez. **No Linux esse é o caminho incomum, não o normal.**

O normal é que a sua máquina já conhece um catálogo de software, assinado por pessoas em quem a sua
distribuição confia, e instalar é um comando que nomeia o que você quer.

```
sudo apt install htop
```

Sem navegador, sem site, sem arquivo em `Downloads`, sem instalador com botão Avançar.

## O que é um repositório

Um **repositório** é um servidor com milhares de pacotes e um índice do que há nele. A sua máquina
tem uma lista dos repositórios em que confia e — esta é a parte que importa — **o índice é assinado
criptograficamente.**

Então instalar faz quatro coisas em que você não precisou pensar:

1. procura o nome num índice que ele já tem;
2. descobre do que mais aquele pacote precisa, e traz também;
3. confere a assinatura — software adulterado no caminho não instala;
4. registra o que instalou, para poder remover por completo depois.

Compare com baixar um `.exe`: você conferiu que o site era o certo, e esse era o modelo de
segurança inteiro.

## Três consequências que você sente na hora

**Atualizar é um comando para tudo.** Não um atualizador por programa, cada um com o próprio
horário e a própria janelinha insistente. O navegador, o banco de dados, o kernel e o editor de
texto são atualizados pelos mesmos dois comandos, num momento que você escolheu.

**Desinstalar remove de verdade.** O gerenciador de pacotes sabe cada arquivo que colocou, porque
foi ele que colocou. Não fica pasta sobrando nem resíduo de registro — não existe registro nenhum,
como disse a seção 13.

**E a atualização não te reinicia.** Essa é a diferença que as pessoas mais notam. Atualizar um
programa no Linux troca arquivos e, quando há um serviço envolvido, reinicia aquele serviço. A
máquina continua rodando. **Só uma atualização de kernel precisa mesmo de reboot**, e mesmo essa
pode ser adiada para um momento que você escolhe, em vez de anunciada por uma contagem regressiva.

É por isso que os servidores que rodam a internet são servidores Linux. Um sistema operacional que
decide sozinho quando se reiniciar não pode ser o que segura o seu banco de dados.

## Para onde o risco se mudou

Ele não sumiu, mudou de forma, e ser claro sobre isso faz parte da aula.

Tudo acima é verdade **dentro do repositório**. No instante em que você sai dele — um repositório
de terceiros, um `.deb` de um site, ou a instrução que você vai encontrar com certeza:

```
curl -sSL https://exemplo.com/install.sh | sh
```

…você está de volta ao modelo do Windows, e pior: essa linha baixa um script e o executa na hora,
com o usuário que você for, sem assinatura e sem chance de ler antes.

É muito comum, parte vem de projetos respeitáveis, e continua sendo algo para se fazer com
deliberação em vez de por reflexo. A aula 7 ordena as opções por risco. O hábito que vale começar
agora: **prefira o repositório; quando sair dele, saiba que saiu.**

## Os dois comandos, para orientação

Você vai encontrar estes direito na aula 7 — e na aula 2, que explica por que a mesma ideia tem
três nomes.

| | Debian, Ubuntu | Red Hat, Rocky, Alma | SUSE |
|---|---|---|---|
| atualizar o índice | `apt update` | *(automático)* | `zypper refresh` |
| instalar | `apt install X` | `dnf install X` | `zypper install X` |
| atualizar tudo | `apt upgrade` | `dnf upgrade` | `zypper update` |
| remover | `apt remove X` | `dnf remove X` | `zypper remove X` |

**O `apt update` não atualiza o seu software.** Ele atualiza o catálogo. O `apt upgrade` é o que
instala versões novas, e rodar o segundo sem o primeiro é o motivo de a máquina de alguém estar "em
dia" há um ano.
