---
title: O laboratório, e três jeitos de montá-lo
version: 1
---

**Toda aula deste curso é algo que você digita e vê acontecer.** Um erro de broadcasting, uma
junção que dobra as suas linhas, um gráfico com os rótulos cortados: cada um se aprende no segundo
em que aparece na sua própria tela, e nenhuma leitura substitui esse segundo. Então você precisa de
uma máquina com a pilha científica instalada, e esta seção monta uma. A plataforma não fornece
nenhuma, e o curso nunca supõe uma.

O laboratório é pequeno. É uma pasta, `~/pydata`, com:

- **um ambiente virtual**, `.venv`: um Python só dele com as sete bibliotecas que este curso usa,
  instaladas nas versões com que todas as saídas daqui foram gravadas;
- **o JupyterLab**, o aplicativo de notebooks que a próxima seção abre;
- **os dados**, três arquivos CSV que um programa curto escreve, mostrado por inteiro na seção
  seguinte.

Nada roda em segundo plano, nada é instalado no sistema todo além do próprio Python, e apagar a
pasta remove tudo.

## Três jeitos de ter um

| caminho | o que você ganha | quanto custa ao seu computador | as saídas |
|---|---|---|---|
| **instalado** (recomendado) | o Python e a pasta no computador que você já usa | cerca de 650 MB de disco; memória só enquanto o JupyterLab está aberto | iguais no Ubuntu 24.04; os mesmos números nos outros |
| **uma máquina virtual** | um Ubuntu 24.04 separado do seu sistema | alguns gigabytes de disco, e 2 GB de memória enquanto roda | iguais ao impresso |
| **online** | uma máquina Linux, ou um notebook, no navegador | nada no seu computador; horas da cota de alguém | parecidas, não idênticas |

**Instalado é o caminho recomendado.** Um ambiente virtual já mantém as bibliotecas separadas de
todo o resto do computador, e esse isolamento é o que uma máquina virtual compraria em outros
casos. O JupyterLab roda no navegador que você já tem, os gráficos aparecem nele, e os arquivos que
você cria são arquivos no seu disco, que você abre com o que quiser.

As transcrições deste curso foram gravadas no Ubuntu 24.04. O Python imprime os mesmos números no
Windows e no macOS, então a saída de uma célula vai bater com a sua; o que muda é o shell em volta,
e a próxima parte diz onde.

**Uma máquina virtual** é o caminho se você prefere manter até o Python fora do computador em que
trabalha. A aula 4 de `virtualization` monta uma no VirtualBox; dê a ela o Ubuntu 24.04 com
ambiente gráfico, para que o navegador que o JupyterLab abre esteja lá dentro junto. No Windows, o
**WSL** com Ubuntu 24.04 também é uma máquina virtual, e os comandos abaixo funcionam nele como
impressos; o endereço do JupyterLab então abre no seu navegador do Windows. Nenhum dos dois foi
usado neste curso além do Ubuntu de dentro.

**Online**, o GitHub Codespaces dá uma máquina Linux com terminal no navegador, onde os comandos
abaixo funcionam, e o Google Colab dá um notebook sem nenhuma instalação. Os dois não custam nada
ao seu computador e os dois são a cota de uma empresa, em termos que ela define e pode mudar. O
Colab ainda traz as próprias versões de cada biblioteca, o oposto do que a aula 3 defende, e a
própria interface em vez da do JupyterLab. Nenhum dos dois foi usado neste curso. Se usar um,
confira as versões primeiro com o último comando da próxima parte.

## Montando

Você precisa do **Python 3.12 ou mais novo**, porque o NumPy que este curso fixa não instala em
nada mais antigo. Veja o que você tem, num terminal:

```
ana@lab:~$ python3 --version
Python 3.12.3
```

No Ubuntu 24.04 esse é o Python que o sistema já tem, e a peça que falta é o módulo que cria
ambientes virtuais, que o Ubuntu distribui num pacote à parte:

```sh
sudo apt-get update
sudo apt-get install -y python3-venv
```

No Windows e no macOS, instale o Python do python.org se `python3 --version` (no Windows,
`py --version`) responder com algo mais antigo que 3.12 ou não responder nada. O instalador já
traz o `venv`. Nenhum dos dois sistemas foi usado para gravar este curso.

Depois a pasta, o ambiente e as bibliotecas:

```sh
mkdir pydata
cd pydata
python3 -m venv .venv
source .venv/bin/activate
pip install jupyterlab==4.6.4 numpy==2.5.3 pandas==3.0.6 matplotlib==3.11.2 seaborn==0.13.2 pyarrow==26.0.0 openpyxl==3.1.5
```

No Windows a terceira e a quarta linhas são `py -m venv .venv` e `.venv\Scripts\activate`; o resto
é igual.

`python3 -m venv .venv` cria o ambiente: um diretório com o próprio `python` e o próprio `pip`.
`source .venv/bin/activate` faz este terminal usá-los, e o prompt avisa pondo o nome do ambiente
na frente, `(.venv)`. **Todo terminal que você abrir para este curso precisa dessa linha uma
vez**, dentro da pasta, antes de qualquer outra coisa. A aula 3 trata do que é o ambiente e de por
que as versões são fixadas; por enquanto, fixar quer dizer que o seu pandas imprime o que o pandas
deste curso imprimiu.

O `pip install` leva um ou dois minutos e termina com uma longa linha `Successfully installed`
com cerca de cem pacotes, porque cada uma das sete bibliotecas traz aquilo de que depende.
Confira:

```
(.venv) ana@lab:~/pydata$ python --version
Python 3.12.3
(.venv) ana@lab:~/pydata$ python -c "import numpy, pandas, matplotlib, seaborn; print(numpy.__version__, pandas.__version__, matplotlib.__version__, seaborn.__version__)"
2.5.3 3.0.6 3.11.2 0.13.2
(.venv) ana@lab:~/pydata$ jupyter lab --version
4.6.4
```

## Iniciando o JupyterLab

```sh
jupyter lab
```

O JupyterLab é um programa que serve páginas web ao seu navegador, e ao iniciar ele abre uma. O
terminal continua imprimindo o que o servidor está fazendo, e entre as primeiras linhas estão
estas:

```
[I 2026-10-10 04:06:02.538 ServerApp] Serving notebooks from local directory: /home/ana/pydata
[I 2026-10-10 04:06:02.538 ServerApp] Jupyter Server 2.21.1 is running at:
[I 2026-10-10 04:06:02.538 ServerApp] http://localhost:8888/lab?token=ea4dc1071297d10dd55cd029eda14770290d8dc83041108c
[I 2026-10-10 04:06:02.538 ServerApp]     http://127.0.0.1:8888/lab?token=ea4dc1071297d10dd55cd029eda14770290d8dc83041108c
[I 2026-10-10 04:06:02.538 ServerApp] Use Control-C to stop this server and shut down all kernels (twice to skip confirmation).
```

Três linhas importam. **O endereço** termina num `token` longo, uma senha que o servidor inventou
para esta execução e pôs no link, para que outro programa no seu computador não possa usá-lo. Se o
navegador não abriu sozinho, copie esse endereço para ele. **A porta**, `8888`, é onde o servidor
escuta. E **`Use Control-C to stop this server`** é como ele termina: o terminal fica ocupado
enquanto o JupyterLab roda, então abra um segundo terminal para o resto.

Ele ocupou este tanto de disco, além do próprio Python:

```
(.venv) ana@lab:~/pydata$ du -sh .venv
635M	.venv
```

## Começando de novo

Cada vez que voltar ao curso:

```sh
cd pydata
source .venv/bin/activate
jupyter lab
```

A seção sobre falhas, no fim desta aula, começa pela primeira dessas linhas esquecida.
