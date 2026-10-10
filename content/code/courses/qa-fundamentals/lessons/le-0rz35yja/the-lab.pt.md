---
title: O laboratório, e três jeitos de montá-lo
version: 1
---

**A maior parte deste curso é pensar, e uma parte precisa ser feita com as mãos.** Você vai ler um
programa pequeno do jeito que quem testa lê, rodá-lo com entradas que você escolheu, pegá-lo dando uma
resposta errada e, mais adiante, ver serem escritos os testes que o teriam pegado antes. A plataforma
não roda nada por você. Esta seção monta a máquina em que você faz isso, e é a única instalação que o
curso pede.

**Você não precisa saber programar.** Todo programa do curso aparece inteiro na aula que o usa, com uma
nota ao lado de cada parte dizendo o que ela faz. O que você digita é um comando que roda um programa,
nunca o programa em si; a partir da aula 15 você também copia testes da página e os roda. Ler um
programa bem o bastante para duvidar dele é uma habilidade de quem testa, e este curso a ensina;
escrever um é assunto de um curso posterior.

O laboratório é **um diretório, um Python e uma ferramenta**:

- `~/aurora`, um diretório onde todo programa do curso é salvo e rodado;
- **Python 3.10 ou mais novo**, que roda os programas. Tudo no curso usa a biblioteca padrão do próprio
  Python, menos uma ferramenta;
- um **ambiente virtual** em `~/aurora/.venv` com essa ferramenta, o **behave**, que lê os cenários de
  teste em linguagem comum das aulas 16 e 17 e os executa.

Você também precisa de um **editor de texto puro** para salvar os programas: um que grave exatamente os
caracteres que você digitou e nada mais. O Visual Studio Code é gratuito em todo sistema e é um bom; o
gedit no Linux, o TextEdit em modo de texto simples no macOS e o Notepad++ no Windows também servem. Um
processador de texto não serve, porque acrescenta formatação que um programa não consegue ler.

## Três jeitos de ter um

| caminho | o que você ganha | o que custa ao seu computador | as transcrições |
|---|---|---|---|
| **instalado** (recomendado) | o laboratório no computador que você já usa | 19 MB para o ambiente, mais o próprio Python onde o sistema não o tem; nada rodando quando você não está usando | iguais no Ubuntu 24.04; parecidas nos outros |
| **uma máquina virtual** | Ubuntu 24.04 separado do seu sistema | alguns gigabytes de disco, e 2 GB de memória enquanto roda | iguais ao impresso |
| **online** | uma máquina Linux no navegador | nada no seu computador; horas de uma cota mensal | parecidas, não idênticas |

**Instalado é o caminho recomendado.** O laboratório é um diretório: não muda mais nada no computador,
não deixa nada rodando em segundo plano, e apagar `~/aurora` remove todo rastro deste curso. O Python
roda igual no Windows, no macOS e no Linux, e o behave é escrito em Python, então não há nada para
compilar em nenhum deles. No Windows, dois dos comandos abaixo se escrevem de outro jeito, e a seção diz
quais.

**Uma máquina virtual** é o caminho se você prefere deixar seu sistema intocado, ou se o computador é um
em que você não pode instalar programas. O VirtualBox é gratuito e roda o Ubuntu Server 24.04 em 2 GB de
memória; a aula 4 de `virtualization` monta uma passo a passo. No Windows, o WSL com Ubuntu 24.04 também
é uma máquina virtual, e os comandos de Linux abaixo funcionam nele como estão impressos. Toda transcrição
deste curso foi gravada num Ubuntu 24.04 com Python 3.12, numa máquina chamada `lab`, por um usuário
chamado `lia`. A sua vai mostrar os seus nomes.

**Online**, o GitHub Codespaces dá uma máquina Linux com terminal no navegador, e não custa nada ao seu
computador. O GitHub dá às contas pessoais uma cota mensal de horas e cobra além dela, em termos que ele
define e pode mudar; qualquer serviço que dê um terminal e um `python3` serve. Esse caminho não foi
executado para este curso, e `python3 --version` diz o que você tem antes de começar.

## Montando

O Python já vem no Ubuntu. No Windows e no macOS, instale-o pelo python.org, e no Windows marque, na
primeira tela do instalador, a opção que o acrescenta ao `PATH`. Qualquer versão a partir da 3.10 serve.

No Ubuntu e no Debian, o módulo que cria ambientes virtuais é um pacote à parte. Instale-o primeiro:

```sh
sudo apt-get update
sudo apt-get install -y python3-venv
```

No Windows e no macOS o Python do python.org já o traz, e você pula essas duas linhas.

Depois, o diretório, o ambiente e a ferramenta. A versão é fixada, porque as aulas 16 e 17 mostram o que
o behave imprime, e uma versão mais nova pode escrever seu resumo de outro jeito:

```sh
mkdir ~/aurora
cd ~/aurora
python3 -m venv .venv
source .venv/bin/activate
pip install behave==1.3.3
```

No Windows, no PowerShell, a quarta linha é `.venv\Scripts\Activate.ps1`, e `python3` é `py`.

O `source` **ativa** o ambiente: daí em diante, naquele terminal, `python` e `pip` são os de dentro do
`.venv`, e o prompt começa com `(.venv)`. As transcrições deste curso omitem esse prefixo, para as linhas
ficarem mais curtas; tudo o que vem depois dele é o que você vai ver.

Por último, duas linhas no fim do `~/.bashrc`, para que todo terminal novo já comece com o ambiente
ativo e no diretório do curso:

```sh
printf 'source ~/aurora/.venv/bin/activate\ncd ~/aurora\n' >> ~/.bashrc
```

No Windows, pule este passo e ative o ambiente à mão em cada terminal novo. Abra um terminal novo e
confira:

```
lia@lab:~/aurora$ python --version
Python 3.12.3
lia@lab:~/aurora$ which python
/home/lia/aurora/.venv/bin/python
lia@lab:~/aurora$ behave --version
behave 1.3.3
```

Esse é o laboratório. Ele custou este tanto de disco:

```
lia@lab:~/aurora$ du -sh .venv
19M	.venv
```

Se você está numa máquina virtual, tire um snapshot agora: um experimento que der errado mais tarde
fica a um clique de ser desfeito.
