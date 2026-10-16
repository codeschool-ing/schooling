---
title: Instalando o Python e as bibliotecas
version: 1
---

Estes passos são para o Ubuntu 24.04, que é o que você tem nos dois primeiros caminhos da seção
anterior: direto no Linux, dentro do WSL no Windows, ou na máquina virtual. Um Mac e o Windows
começam com um passo diferente e depois seguem os mesmos, e o fim desta seção diz onde eles se
separam.

Abra um terminal. Tudo abaixo é digitado nele.

## Três pacotes do sistema

```sh
sudo apt update
sudo apt install -y python3-venv git sqlite3
```

**`python3-venv`** deixa o Python criar um ambiente isolado para as bibliotecas do curso, que é o
próximo passo. **`git`** guarda o histórico do projeto a partir da lição 7, onde o DVC registra
versões dos dados ao lado dele. **`sqlite3`** é um comando que abre o banco da loja e responde ao SQL
digitado nele, o jeito mais rápido de olhar uma tabela.

## Um ambiente para o curso

O Python do Ubuntu pertence ao sistema, e o sistema não deixa o `pip` escrever nele. As bibliotecas
do curso vão então para um **ambiente virtual** próprio, um diretório com a sua própria cópia do
Python e os seus próprios pacotes:

```sh
python3 -m venv ~/mlenv
source ~/mlenv/bin/activate
pip install numpy==2.5.3 pandas==3.0.6 scikit-learn==1.9.1 scipy==1.18.1
```

**As versões são fixadas** porque essas bibliotecas mudam a cada poucos meses, e uma lição escrita
contra uma versão e rodada contra outra imprime números diferentes, ou falha de um jeito que parece
erro seu. `numpy` são vetores de números, `pandas` são tabelas deles, `scikit-learn` são os
algoritmos de aprendizado, e `scipy` é a estatística que a lição 10 usa. As lições seguintes
acrescentam o MLflow, o DVC e as bibliotecas que servem um modelo, cada uma com uma linha
`pip install` onde for preciso pela primeira vez.

`source ~/mlenv/bin/activate` é o que coloca o Python do ambiente em primeiro lugar no seu caminho.
**Todo terminal novo começa com ele.** O prompt passa a começar com `(mlenv)`, o que as transcrições
deste curso omitem.

A verificação de que tudo se encaixa:

```
ana@dev:~$ python --version
Python 3.12.3
ana@dev:~$ pip list 2>/dev/null | grep -E '^(numpy|pandas|scikit-learn|scipy) '
numpy           2.5.3
pandas          3.0.6
scikit-learn    1.9.1
scipy           1.18.1
```

## Num Mac

Instale o Python 3.12 de `python.org`, e as ferramentas de linha de comando com
`xcode-select --install`, que trazem o `git`; o `sqlite3` já está lá. Depois abra o Terminal e siga
cada passo a partir de "Um ambiente para o curso". O shell do macOS é o `zsh`, e o comando de
ativação funciona nele sem mudança. **Isto não foi rodado para este curso**, que foi gravado em
Linux.

## No Windows

Abra o PowerShell como administrador e instale o WSL com o Ubuntu:

```sh
wsl --install -d Ubuntu-24.04
```

Reinicie quando ele pedir, abra o *Ubuntu 24.04* pelo menu Iniciar, escolha um nome de usuário e uma
senha, e siga esta seção desde o começo, lá dentro. Mantenha o projeto dentro da pasta pessoal do
próprio WSL em vez de `/mnt/c`, onde toda operação de arquivo atravessa para o Windows e fica mais
lenta. **Este comando também não foi rodado para este curso.**
