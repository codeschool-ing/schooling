---
title: A sua máquina
version: 1
---

Nada neste curso roda numa máquina que a gente hospeda. **Você monta a máquina, e todo comando de toda
aula é digitado nela.** É uma máquina Ubuntu 24.04 com Python, `curl`, SQLite e algumas bibliotecas
instaladas do próprio repositório do Ubuntu. Dá para jogá-la fora e montar de novo em uns vinte
minutos, e essa é a propriedade que mais importa: uma aula que deixa algo quebrado é uma aula que você
pode recomeçar do zero.

Há três jeitos de ter essa máquina. Escolha a máquina virtual, a não ser que tenha um motivo para não
escolher.

| | o que é | quanto custa |
|---|---|---|
| instalado | os pacotes direto num Ubuntu 24.04, seja um computador só para isso, seja o WSL no Windows | nada a mais, e todos os pacotes da próxima seção ficam nesse sistema para sempre |
| **uma máquina virtual com Multipass** (recomendado) | a ferramenta da Canonical que cria uma VM Ubuntu com um comando, no Windows, no macOS e no Linux | 2 processadores, 2 GB de memória e 10 GB de disco enquanto roda |
| online | uma pequena máquina Linux alugada por hora num provedor de nuvem | dinheiro, e uma máquina na internet desde o primeiro minuto |

**A máquina virtual** é a recomendada porque ela é igual em qualquer lugar. As transcrições destas
aulas foram gravadas num Ubuntu 24.04 com exatamente os pacotes que a próxima seção instala, e uma VM é
o único jeito de ter isso em qualquer computador sem mexer no sistema em que você trabalha. Qualquer
outro hipervisor serve no lugar do Multipass, VirtualBox, UTM num Mac com Apple silicon, Hyper-V ou
GNOME Boxes, ao preço de meia hora de telas de instalação.

**Instalado** é uma boa escolha se você já usa Ubuntu 24.04, ou o WSL com a distribuição Ubuntu 24.04
no Windows. No macOS, ou em outro Linux, os mesmos programas existem, mas as versões vão ser diferentes
das transcrições, e as bibliotecas vão vir do `pip` em vez do `apt`; espere ler uma saída que não é
exatamente a impressa aqui. **Online** aparece para você saber que existe, não como recomendação: os
servidores deste curso escutam só em `127.0.0.1`, então ficam seguros numa máquina pública, mas você
estaria pagando por hora por algo que o seu computador faz de graça.

## Com o Multipass

Instale o Multipass pelo site dele e, no terminal do seu próprio computador:

```sh
multipass launch 24.04 --name api --cpus 2 --memory 2G --disk 10G
multipass shell api
```

**Esses dois comandos não foram executados para este curso**, porque o computador em que ele foi
gravado não roda um hipervisor; a máquina das transcrições foi montada com a mesma versão do Ubuntu e os
mesmos pacotes, sem um. O primeiro comando cria a máquina virtual e o segundo abre um shell dentro
dela. Tudo o que vem depois acontece nesse shell.

Duas pequenas diferenças em relação às transcrições são esperadas e inofensivas. O prompt aqui mostra
`ana@api`, e o seu vai mostrar `ubuntu@api`, porque o Multipass chama o usuário dele de `ubuntu`. E o
comando `multipass shell api` também é como você abre o segundo terminal de que o servidor da aula 1
precisa: rode de novo em outra janela e você está na mesma máquina duas vezes.
