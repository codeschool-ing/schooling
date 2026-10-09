---
title: Onde o modelo roda, e o caminho a escolher
version: 1
---

Este curso manda e-mails para modelos de linguagem e lê o que volta, e a plataforma não roda modelo
nenhum para você. O que você usa é um que você mesmo põe em algum lugar. A recomendação é a mesma em
todos os cursos de IA daqui: o **Ollama**, um programa gratuito que roda modelos abertos no seu
próprio computador, com o **`llama3.2:3b`**, um modelo de três bilhões de parâmetros da Meta. O
Ollama não pede conta nem cartão, e nada do que você manda para ele sai da máquina.

Ele pode morar em três lugares:

| caminho | o que você ganha | quanto custa ao seu computador |
|---|---|---|
| **instalado** (recomendado) | Ollama e Python no computador que você já usa | 2,0 GB de disco para o modelo, e 2,6 GB de memória enquanto ele responde |
| **numa máquina virtual** | Ubuntu Server 24.04, com o Ollama dentro, separado do seu sistema | uma imagem de disco de 30 GB, e 6 GB de memória enquanto ela roda, os 2,6 GB do modelo entre eles |
| **online** | uma máquina Linux alugada, acessada pelo navegador ou por um terminal | nada no seu computador; um preço por hora definido por quem aluga |

Os dois tamanhos vêm das transcrições da próxima seção: o `ollama list` informa quanto o modelo
ocupa em disco, e o `ollama ps`, quanto ocupa em memória depois de carregado.

## Instalado, que é o caminho a escolher

O Ollama roda no Windows, no macOS e no Linux, e toda aula depois desta supõe que ele está na
máquina à sua frente, respondendo em `http://127.0.0.1:11434`. Um computador com **8 GB de memória**
roda o `llama3.2:3b` com folga para um navegador e um editor. Não precisa de placa de vídeo: as
transcrições deste curso foram feitas numa máquina sem nenhuma, com quatro processadores e 16 GB, e
toda resposta voltou em poucos segundos. Uma placa de vídeo deixa tudo mais rápido, e o Ollama a
encontra sozinho.

**Com 4 GB, use o modelo menor**, o `llama3.2:1b`: 1,3 GB em disco e 1,5 GB em memória. Ele
responde às mesmas perguntas pior, coisa que a aula 5 mede, e todo programa do curso roda com ele se
você trocar o nome do modelo.

## Numa máquina virtual

Escolha este caminho se o computador é um em que você não pode instalar programas, ou se quer
Linux de qualquer jeito.

1. **Um hipervisor**, o programa que roda a máquina: VirtualBox no Windows e no Linux, UTM no Mac,
   ou Hyper-V no Windows, se já estiver ligado.
2. **Ubuntu Server 24.04 LTS**, de ubuntu.com. Num Mac com Apple silicon, a imagem ARM.
3. **Uma máquina com 6 GB de memória**, 4 processadores e um disco de 30 GB que cresce conforme é
   escrito. O modelo precisa dos seus 2,6 GB dentro da máquina convidada, e a convidada precisa de
   memória própria além disso.
4. **Entre, e siga as instruções de Linux** das próximas seções, que foram gravadas exatamente
   nesse sistema.

Uma máquina virtual não alcança a sua placa de vídeo, então o modelo roda no processador e fica mais
lento que o mesmo modelo instalado. No Windows, o **WSL** com Ubuntu 24.04 é a versão mais leve:
`wsl --install -d Ubuntu-24.04` num PowerShell aberto como administrador, e depois as instruções de
Linux. O curso `virtualization` monta e ajusta uma máquina virtual direito, na aula 4.

## Online

Uma máquina Linux alugada por hora de qualquer empresa de nuvem funciona como o caminho da máquina
virtual, sem usar o seu computador: Ubuntu Server 24.04, pelo menos 8 GB de memória, e as instruções
de Linux. Desligue-a entre uma sessão e outra, porque ela é cobrada enquanto roda. Nenhuma aula
depende da oferta de uma empresa, gratuita ou paga.

## E uma chave no lugar de um modelo

Há um segundo jeito de obter respostas, e ele substitui o Ollama, não o computador: **uma chave de
API sua**, de um provedor como a Anthropic ou a OpenAI. Todo programa do curso lê o endereço e a
chave de um arquivo só, o `desk.env`, que a seção 04 escreve, então uma chave é uma troca de duas
linhas. Ela **nunca é obrigatória**, é cobrada por requisição, e as aulas 6 a 9 dizem quanto cada
provedor cobra. As transcrições daqui são todas do `llama3.2:3b`, e com uma chave as suas respostas
vêm de outro modelo, então vão diferir mais do que o próximo parágrafo prevê.

**A resposta de um modelo muda de uma execução para outra.** A mesma pergunta lhe dá outra redação,
e às vezes outra resposta, diferente da que está impressa numa aula. Isso não é defeito na sua
montagem. A aula 5 seção 08 mede isso e diz quando importa.
