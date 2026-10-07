---
title: Três lugares para ter um Python, e qual escolher
version: 1
---

Todo programa deste curso é digitado, rodado e lido num computador, e a plataforma não roda nenhum
deles por você. Então o Python em que você digita é um que você mesmo colocou em algum lugar. Há
três lugares para colocá-lo.

| caminho | o que você ganha | quanto custa ao seu computador |
|---|---|---|
| **instalado** (recomendado) | Python no computador que você já usa | o disco que um programa ocupa, e nada rodando enquanto você não o usa |
| **numa máquina virtual** | Ubuntu Server 24.04, com o seu próprio Python 3.12, à parte do seu sistema | alguns gigabytes de disco, e 2 GB de memória enquanto ela roda |
| **online** | uma máquina Linux com terminal, no navegador | nada no seu computador; horas de uma cota mensal que outra pessoa define |

## Instalado, que é o que se escolhe

**Um interpretador é um programa como outro qualquer.** Instalar um não muda mais nada no
computador nem deixa nada rodando em segundo plano. E toda aula depois desta supõe que o Python
está na máquina à sua frente: o editor no fim desta aula, os ambientes virtuais da aula 18. No
Ubuntu a biblioteca padrão, todos os módulos que vêm com ele, ocupa 54 MB. A próxima seção mostra
como instalar no Windows, no macOS e no Linux.

## Numa máquina virtual

Escolha este caminho se você quer Linux de qualquer jeito, ou se o computador é um em que você não
pode instalar programas, como um notebook do trabalho. Uma máquina virtual é um segundo computador
inteiro dentro de uma janela: custa disco e memória e, em troca, nada do que você fizer lá dentro
encosta no seu sistema.

1. **Um hipervisor**, o programa que a roda. VirtualBox no Windows e no Linux; UTM no Mac; no
   Windows, o Hyper-V, se ele já estiver ligado.
2. **O Ubuntu Server 24.04 LTS**, baixado do ubuntu.com. Num Mac com Apple silicon, pegue a imagem
   ARM, e não a de `amd64`.
3. **Uma máquina nova** com 2 GB de memória, 2 processadores e um disco de 20 GB que cresce conforme
   é escrito, para ocupar só o que usa. Ligue-a com a imagem no drive virtual e aceite o que o
   instalador propõe.
4. **Entre**, e digite `python3 --version`. O Ubuntu Server já vem com o Python 3.12, e daqui em
   diante as instruções de Linux da próxima seção valem para você.

No Windows, o **WSL** rodando o Ubuntu 24.04 é a versão mais leve da mesma coisa: um terminal Linux
ao lado dos seus programas do Windows. `wsl --install -d Ubuntu-24.04`, num PowerShell aberto como
administrador, instala, e as instruções de Linux valem para ele também.

Antes de começar o curso, tire um **snapshot**, a palavra do hipervisor para um estado salvo da
máquina inteira. Um experimento que dá errado fica a um clique de ser desfeito. O curso
`virtualization` monta e ajusta uma dessas direito, no VirtualBox, na aula 4.

## Online

O **GitHub Codespaces** dá uma máquina Linux com editor e terminal no navegador, e a máquina que
ele liga já vem com um Python. Não custa nada ao seu computador, o que faz dele o caminho para um
computador que não aceita instalação, como o de uma escola ou de uma biblioteca. O GitHub dá às
contas pessoais uma cota mensal de horas e cobra o que passar dela, em termos que ele define e pode
mudar. Ele não foi usado neste curso.

Qualquer máquina que dê um terminal e um `python3` serve, de qualquer empresa; nada aqui depende de
uma delas. Confira antes de começar:

```
python3 --version
```

Qualquer coisa de **3.10** para cima basta para todas as aulas.
