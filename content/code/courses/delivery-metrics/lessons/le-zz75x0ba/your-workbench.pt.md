---
title: O computador em que você vai medir
version: 1
---

**A maior parte deste curso é julgamento**: ler um gráfico, decidir o que um número aguenta, conduzir um incidente. Isso não precisa de software. O resto é aritmética sobre o histórico de um time, e essa aritmética é feita por programas curtos que você roda no seu computador. Nada neste curso fica hospedado para você, e nada precisa ficar.

Você precisa de **uma coisa: Python 3**, versão 3.8 ou mais nova. Todo programa do curso usa só o que vem com o próprio Python, então não há nada para instalar com `pip`, nenhuma conta para criar e nenhuma biblioteca cuja versão possa mudar por baixo. Você não precisa ser programador. Cada aula imprime os programas inteiros, diz o que cada parte faz, e pede que você os rode, mude um número e rode de novo.

## Três jeitos de ter um ambiente funcionando

| caminho | o que custa ao seu computador | quando escolher |
|---|---|---|
| **instalado no seu computador** (recomendado) | uns 100 MB de disco; funciona offline | você tem um notebook ou desktop em que pode instalar software |
| **numa máquina virtual** | 25 GB de disco e 4 GB de memória para uma máquina Ubuntu no VirtualBox | o computador não é seu para mexer, ou você já trabalha dentro de uma máquina virtual Linux |
| **online** | nada instalado; precisa de uma conta e de conexão | você está num computador emprestado ou travado |

**O caminho recomendado é o primeiro.** É o menor, funciona num trem, e os seus arquivos ficam onde você os põe. As aulas foram gravadas em Linux, e cada comando abaixo é o que foi digitado lá.

## Instalado: o caminho recomendado

- **Linux**: o Python 3 quase certamente já está lá, porque o sistema usa. Se não estiver, `sudo apt install python3` no Debian ou Ubuntu, `sudo dnf install python3` no Fedora.
- **macOS**: baixe o instalador em `python.org`. Versões recentes do macOS também oferecem um `python3` quando você instala as ferramentas de linha de comando da Apple; é mais antigo, e ainda novo o bastante.
- **Windows**: baixe o instalador em `python.org`. Ele instala um lançador chamado `py`, então **no Windows, digite `py` onde as aulas digitam `python3`**.

Depois crie uma pasta chamada `delivery`, abra um terminal nela e pergunte ao Python qual é a versão:

```
ana@laptop:~/delivery$ python3 --version
Python 3.13.16
```

Qualquer versão a partir da 3.8 imprime os mesmos resultados em todos os programas deste curso. Se a sua disser 2.7, você achou o Python antigo que alguns sistemas ainda guardam para uso próprio, e precisa de `python3` em vez de `python`.

## Numa máquina virtual

Se você prefere não instalar nada no seu sistema, uma máquina virtual Ubuntu no VirtualBox tem Python 3 desde o primeiro boot. Dê a ela 4 GB de memória e 25 GB de disco, instale o Ubuntu pela imagem oficial e siga a linha do Linux acima lá dentro. Esse caminho é o que mais custa e compra isolamento, o que só importa se o seu computador pertence ao departamento de TI de outra pessoa.

## Online

Dois serviços dão um Python com terminal no navegador, cada um com uma cota mensal grátis quando este curso foi escrito: o **GitHub Codespaces**, que pede uma conta no GitHub, e o **Google Colab**, que pede uma conta Google. No Codespaces, abra o terminal e digite os comandos como as aulas mostram. No Colab, ponha `%%writefile billing.py` na primeira linha de uma célula, cole o programa embaixo e rode a célula para salvar o arquivo; depois rode um programa em outra célula com um ponto de exclamação na frente, `!python3 billing.py`.

Nenhum dos dois é obrigatório, e o curso não depende de nenhum: se um mudar os termos, o outro caminho, ou o instalado, dá exatamente os mesmos números. O que você perde online é o hábito de rodar as coisas na sua própria máquina, e os arquivos quando a sessão acaba, então guarde uma cópia de tudo o que mudar.
