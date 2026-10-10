---
title: A máquina em que você vai digitar
version: 1
---

Nada neste curso roda numa máquina nossa. **Você monta uma máquina Linux com Python e PyTorch, e
desta seção em diante todo comando é digitado nela.** Todas as transcrições do curso foram gravadas
numa assim: Ubuntu 24.04, quatro processadores, nenhuma placa de vídeo, um usuário chamado `ana` e
uma máquina chamada `vm`. O seu prompt vai trazer os seus próprios nomes.

**Nenhuma placa de vídeo é uma escolha, não um pedido de desculpas.** Deep learning é conhecido por
consumir horas de GPU, e as aulas 10 e 19 tratam exatamente desse custo. Mas toda rede deste curso é
pequena o bastante para treinar no processador de um notebook em segundos ou minutos, porque as
ideias não ficam mais claras num tamanho maior: uma taxa de aprendizado alta demais diverge em 1.797
imagens do mesmo jeito que diverge em um milhão. Onde uma aula diz algo que só uma placa de vídeo
mostra, ela avisa e diz que aquilo não foi executado.

## O que roda nela

| | o que é | por que este |
| --- | --- | --- |
| **Python 3.12** | a linguagem de todos os programas, num ambiente virtual próprio | o Ubuntu 24.04 já traz |
| **NumPy** | arrays e a aritmética sobre eles | as aulas 1 a 8 montam uma rede só com ele, para que nada fique escondido |
| **scikit-learn** | a biblioteca que `machine-learning` usou | traz os dígitos manuscritos com que este curso treina, dentro do pacote, sem download |
| **PyTorch** | o framework da aula 9 em diante: tensores, gradientes automáticos, camadas | o que a maior parte da pesquisa e dos empregos usa; as ideias valem para os outros |
| **torchvision** | a biblioteca de imagens do PyTorch | as arquiteturas clássicas da aula 12 e as aumentações da aula 13 |
| **tokenizers** | a biblioteca de tokenizadores da Hugging Face | a aula 16 treina um tokenizador próprio com ela |

## Três jeitos de ter a máquina

| | o que é | quanto custa ao seu computador |
| --- | --- | --- |
| **uma máquina virtual** (recomendado) | Ubuntu Server 24.04 LTS numa VM criada com o Multipass, e tudo instalado dentro dela | 4 processadores, 8 GB de memória e 30 GB de disco enquanto roda; no seu próprio sistema, só o hipervisor |
| instalado | os mesmos comandos num computador que já roda Ubuntu 24.04; ou o Python 3.12 do python.org no Windows ou no macOS, com a mesma linha de `pip` | uns 6 GB de disco para as bibliotecas, e mais nada |
| online | uma máquina virtual alugada de um provedor de nuvem, um GitHub Codespace, ou um serviço de notebooks com placa de vídeo | nada no seu computador; um preço por hora, ou uma cota que a empresa que oferece decide |

**A máquina virtual tem o mesmo formato da máquina de onde vieram as transcrições**, então, quando
os seus números diferirem dos da aula, a diferença está na aritmética do seu processador e não na
montagem. Ela também é descartável: um ambiente quebrado por um experimento não custa nada que os
comandos abaixo não consigam refazer.

**Instalado é o caminho para um computador com placa de vídeo NVIDIA**, porque uma VM não enxerga a
placa. No Linux, o `torch` que o `pip` instala traz as próprias bibliotecas CUDA e precisa apenas do
driver da NVIDIA; `torch.cuda.is_available()` passa então a responder `True`. No macOS com Apple
silicon, o mesmo pacote usa a GPU do próprio chip por um backend chamado `mps`. No Windows, o pacote
que o `pip` instala por padrão usa só o processador, e o site do PyTorch dá o comando de uma versão
com CUDA. Nada disso foi executado para este curso, porque a máquina dele não tem placa.

**Online aparece para você saber que existe, não como recomendação.** Um serviço de notebooks que
empresta uma placa de vídeo de graça é uma decisão de uma empresa, que ela pode mudar, e os notebooks
perdem os arquivos quando a sessão acaba. Nenhuma aula daqui depende de um, e nenhuma precisa de
placa.

## A máquina virtual

Instale o Multipass pelo site da Canonical. Ele comanda um hipervisor que o sistema já tem: Hyper-V no
Windows, ou VirtualBox nas edições sem Hyper-V; QEMU sobre o hipervisor da própria Apple no macOS; e
QEMU com KVM no Linux. Depois, no terminal do seu próprio computador:

```sh
multipass launch 24.04 --name vm --cpus 4 --memory 8G --disk 30G
multipass shell vm
```

**Esses dois comandos não foram executados para este curso**, porque a máquina em que ele foi gravado
é ela mesma uma máquina virtual e não consegue iniciar outra. O primeiro cria a VM e o segundo abre
um shell dentro dela. Tudo daqui em diante acontece nesse shell. Qualquer outro hipervisor serve no
lugar do Multipass, VirtualBox, UTM num Mac com Apple silicon, Hyper-V ou GNOME Boxes, com um
instalador do Ubuntu Server 24.04 LTS e os mesmos tamanhos. Custa meia hora de telas de instalação em
vez de um comando.

## O diretório de trabalho

Tudo o que o curso escreve fica em `~/dl`, com um Python só dele:

```sh
sudo apt-get update
sudo apt-get install -y python3-venv
mkdir ~/dl && cd ~/dl
python3 -m venv .venv
```

O Ubuntu deixa de fora a parte do Python que cria ambientes virtuais, e é ela que a segunda linha
devolve. Salve o próximo bloco como `~/dl/requirements.txt`. Ele nomeia toda biblioteca que uma aula
importa, na versão com que as transcrições foram gravadas:

```
# requirements.txt: the libraries this course imports, at the versions it was recorded with
numpy==2.5.3
scikit-learn==1.9.1
torch==2.14.1
torchvision==0.29.1
tokenizers==0.23.3
```

Depois ative o ambiente, instale, e faça todo terminal novo ativá-lo também:

```sh
. .venv/bin/activate
pip install -r requirements.txt
echo 'export VIRTUAL_ENV_DISABLE_PROMPT=1' >> ~/.bashrc
echo '. ~/dl/.venv/bin/activate' >> ~/.bashrc
```

A instalação baixa vários gigabytes e leva alguns minutos. O primeiro `echo` mantém o prompt curto:
um ambiente ativo normalmente põe `(.venv)` na frente dele, e as transcrições deste curso não o
mostram. `which python` é o jeito honesto de perguntar em qual Python você está, e as verificações
abaixo usam isso.

## Verificando que funciona

Quatro verificações: o Python, qual Python é, o PyTorch e se ele enxerga uma placa de vídeo, e quanto
disco o ambiente custou.

```
ana@vm:~/dl$ python --version
Python 3.12.3
ana@vm:~/dl$ which python
/home/ana/dl/.venv/bin/python
ana@vm:~/dl$ python -c "import torch; print(torch.__version__, torch.cuda.is_available())"
2.14.1+cu130 False
ana@vm:~/dl$ du -sh .venv
5.7G	.venv
```

`2.14.1+cu130` é o PyTorch compilado com CUDA 13.0, a versão que o `pip` instala no Linux. `False`
diz que ele não achou placa onde usá-la, o que está certo para esta máquina e para a sua VM. A maior
parte dos 5,7 GB é código para placas NVIDIA, que vem junto haja placa ou não.

**Esse tamanho é o preço do padrão, e existe uma versão menor.** O PyTorch publica uma versão só para
processador, sem as bibliotecas da NVIDIA, no seu próprio índice de pacotes:
`pip install torch==2.14.1 torchvision==0.29.1 --index-url https://download.pytorch.org/whl/cpu`,
antes da linha do `requirements.txt`. Ela não foi executada para este curso, porque a máquina de onde
vieram as transcrições não alcançava esse índice; todo número aqui vem da versão padrão. Numa VM sem
placa, as duas calculam os mesmos resultados.
