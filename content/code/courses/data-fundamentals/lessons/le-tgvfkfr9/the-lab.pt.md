---
title: O laboratório, e três jeitos de montá-lo
version: 1
---

**Este curso é um mapa, e um mapa que você só lê se esquece fácil.** Por isso a maioria das aulas, da
aula 3 em diante, termina com alguma coisa rodando: uma fonte feita por um programa curto, um arquivo
escrito em quatro formatos, um fluxo com um evento chegando atrasado, duas cópias de um valor que param
de concordar. Cada programa é mostrado por inteiro na aula que o usa, e você o roda numa máquina que
você mesmo monta. A plataforma não roda nada por você. Esta seção monta a máquina.

Ela é pequena de propósito. O laboratório é **um diretório e um Python**:

- `~/roda`, um diretório onde todo programa do curso é salvo e rodado;
- **Python 3.11 ou mais novo**, o que você instalou na aula 1 de `python`. Aquele curso aceita o 3.10,
  e este precisa de uma versão a mais, porque o pyarrow 26 precisa;
- um **ambiente virtual** em `~/roda/.venv` com duas bibliotecas: **pyarrow**, que lê e escreve Parquet
  e ORC, e **fastavro**, que faz o mesmo com Avro. A aula 6 usa as duas. Todo o resto do curso é a
  biblioteca padrão do próprio Python.

Não há servidor de banco de dados para instalar, nem contêiner. Onde uma aula precisa de um banco, ela
usa o SQLite, que é um arquivo e já vem dentro do Python.

## Três jeitos de ter um

| caminho | o que você ganha | quanto custa ao seu computador | as transcrições |
|---|---|---|---|
| **instalado** (recomendado) | o laboratório no computador que você já usa | 195 MB de disco, e nada rodando quando você não está usando | iguais no Ubuntu 24.04; parecidas nos outros |
| **uma máquina virtual** | o Ubuntu 24.04 separado do seu sistema | alguns gigabytes de disco, e 2 GB de memória enquanto roda | iguais ao impresso |
| **online** | uma máquina Linux no navegador | nada no seu computador; horas de uma cota mensal | parecidas, não idênticas |

**Instalado é o caminho recomendado.** Um ambiente virtual é um diretório: não muda mais nada no
computador, não deixa nada rodando em segundo plano, e apagar `~/roda` remove todo rastro deste curso.
O pyarrow e o fastavro publicam pacotes prontos para Windows, macOS e Linux, então o `pip` não precisa
de compilador em nenhum deles. No Windows dois dos comandos abaixo se escrevem de outro jeito, e a seção
diz quais.

**Uma máquina virtual** é o caminho se você prefere deixar o seu sistema intocado, ou se o computador é
um em que você não pode instalar software. A aula 1 de `python` monta uma com o Ubuntu Server 24.04, e a
aula 4 de `virtualization` monta uma direito no VirtualBox. No Windows, o WSL com o Ubuntu 24.04 também é
uma máquina virtual, e os comandos de Linux abaixo funcionam nele como estão. Toda transcrição deste
curso foi gravada no Ubuntu 24.04 com o Python 3.12, numa máquina chamada `lab`, por um usuário chamado
`ana`. A sua vai mostrar os seus próprios nomes.

**Online**, o GitHub Codespaces dá uma máquina Linux com terminal no navegador, e não custa nada ao seu
computador. O GitHub dá às contas pessoais uma cota mensal de horas e cobra o que passar dela, em termos
que ele define e pode mudar; qualquer serviço que dê um terminal e um `python3` serve. Ele não foi
usado neste curso, e `python3 --version` diz o que você tem antes de começar.

## Montando

No Ubuntu e no Debian, o módulo que cria ambientes virtuais é um pacote à parte. Instale-o primeiro:

```sh
sudo apt-get update
sudo apt-get install -y python3-venv
```

No Windows e no macOS, o Python do python.org já vem com ele, e você pula essas duas linhas.

Depois o diretório, o ambiente e as duas bibliotecas. As versões são fixas, porque a aula 6 mostra o
tamanho dos arquivos que cada uma escreve, e uma versão mais nova pode escrever outro número de bytes:

```sh
mkdir ~/roda
cd ~/roda
python3 -m venv .venv
source .venv/bin/activate
pip install pyarrow==26.0.0 fastavro==1.13.1
```

No Windows, no PowerShell, a quarta linha é `.venv\Scripts\Activate.ps1`, e `python3` é `py`.

`source` **ativa** o ambiente: daí em diante, naquele terminal, `python` e `pip` são os que estão dentro
de `.venv`, e o prompt começa com `(.venv)`. As transcrições deste curso deixam esse prefixo de fora,
para as linhas ficarem mais curtas; tudo o que vem depois dele é o que você vai ver.

Por último, três linhas no fim do `~/.bashrc`, para que todo terminal novo comece no relógio da empresa
e com o ambiente já ativo:

```sh
cat >> ~/.bashrc <<'EOF'
# data-fundamentals
export TZ=America/Sao_Paulo
source ~/roda/.venv/bin/activate
EOF
```

O `TZ` importa a partir da aula 3, onde uma viagem começa a uma hora do dia, e sobretudo na aula 8, onde
a hora de um evento é o assunto inteiro. No Windows, pule este passo e ative o ambiente à mão em cada
terminal novo. Abra um terminal novo e confira:

```
ana@lab:~/roda$ python --version
Python 3.12.3
ana@lab:~/roda$ which python
/home/ana/roda/.venv/bin/python
ana@lab:~/roda$ python -c "import pyarrow, fastavro; print(pyarrow.__version__, fastavro.__version__)"
26.0.0 1.13.1
ana@lab:~/roda$ date +%Z
-03
```

Esse é o laboratório. Ele custou este tanto de disco:

```
ana@lab:~/roda$ du -sh .venv
195M	.venv
ana@lab:~/roda$ du -sh .venv/lib/python3.12/site-packages/* | sort -h | tail -3
13M	.venv/lib/python3.12/site-packages/fastavro
16M	.venv/lib/python3.12/site-packages/pip
167M	.venv/lib/python3.12/site-packages/pyarrow
```

Quase tudo é o pyarrow, que traz dentro dele um motor colunar escrito em C++. Se você está numa máquina
virtual, tire um snapshot agora: um experimento que der errado mais tarde fica a um clique de ser
desfeito.
