---
title: `python3`, e os três que você provavelmente vai encontrar
version: 1
---

Provavelmente já existe um Python na sua máquina, e provavelmente não é o que você quer usar para o
seu próprio trabalho. Três chegam por caminhos diferentes.

| | de onde veio | o que fazer com ele |
|---|---|---|
| **o do sistema** | veio com o macOS ou com a sua distribuição Linux | deixe quieto; coisas que você não instalou dependem dele |
| **o do python.org** | você baixou e instalou | é esse que se usa |
| **o de um gerenciador** | `pyenv`, Homebrew, `uv`, a Microsoft Store | tudo bem, e saiba qual deles está respondendo |

## Veja o que você tem

```
python3 --version
```

Qualquer coisa de **3.10** para cima basta para tudo neste curso. Abaixo disso, parte da sintaxe das
aulas seguintes nem vai ser lida.

## `python3` e não `python`

Na maioria das máquinas o `python` ou não existe ou é o 2.x antigo que alguns scripts velhos ainda
querem. O Python 2 está sem suporte desde 2020 e o seu `print` é um comando em vez de uma função, que
é por que um exemplo copiado de uma resposta de quinze anos atrás às vezes falha na primeira linha.

**Digite `python3`.** No Windows o lançador é `py`, e `py -3` é a mesma ideia.

## Instalando um

**Windows:** o instalador do python.org, e **marque "Add python.exe to PATH"** na primeira tela. Essa
caixinha é o motivo mais comum de uma instalação nova do Windows responder
`'python' is not recognized`.

**macOS:** o instalador do python.org, ou `brew install python`.

**Linux:** você já tem um. `sudo apt install python3-venv python3-pip` no Debian e no Ubuntu traz as
duas peças que vêm empacotadas à parte e de que a aula 18 precisa.

## A única coisa a não fazer ainda

Não comece a instalar bibliotecas dentro de qualquer Python que responda. Isso é a aula 18, e ela tem
uma seção própria sobre por que o interpretador do sistema não é seu para encher.
