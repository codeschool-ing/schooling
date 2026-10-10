---
title: A sua máquina
version: 1
---

Nada neste curso roda numa máquina que a gente hospeda. **Você monta a máquina, e todo comando de
toda aula é digitado nela.** É uma máquina Ubuntu 24.04 chamada `nft`, e ao longo do curso ela junta
uma aplicação para testar e as ferramentas que a testam: quatro geradores de carga e dois menores, o
Lighthouse, um navegador que o Playwright dirige, um caçador de segredos, um auditor de dependências e
o Prometheus. Cada ferramenta é instalada na aula que a usa primeiro. Esta aula monta a máquina,
instala a base e digita a aplicação.

Dá para jogar a máquina fora e montá-la de novo em mais ou menos meia hora. Essa é a propriedade que
mais importa: uma aula que deixa algo quebrado é uma aula que você pode recomeçar do zero, e um teste
de carga é um bom jeito de deixar algo quebrado.

Há três jeitos de ter essa máquina. Escolha a máquina virtual, a não ser que tenha um motivo para não
escolher.

| | o que é | quanto custa |
|---|---|---|
| instalado | os pacotes direto num Ubuntu 24.04, seja um computador só para isso, seja o WSL no Windows | nada a mais, e todas as ferramentas do curso ficam nesse sistema |
| **uma máquina virtual com Multipass** (recomendado) | a ferramenta da Canonical que cria uma VM Ubuntu com um comando, no Windows, no macOS e no Linux | 4 processadores, 4 GB de memória e 20 GB de disco enquanto roda |
| online | uma pequena máquina Linux alugada por hora num provedor de nuvem | dinheiro, e uma máquina na internet desde o primeiro minuto |

**A máquina virtual** é a recomendada porque é igual em qualquer lugar, e porque um teste de carga
precisa de uma caixa com limites conhecidos. As transcrições destas aulas foram gravadas num Ubuntu
24.04 com exatamente os pacotes que cada aula instala. Uma VM é o único jeito de ter isso em qualquer
computador sem mexer no sistema em que você trabalha. Qualquer outro hipervisor serve no lugar do
Multipass: VirtualBox, UTM num Mac com Apple silicon, Hyper-V ou GNOME Boxes, ao preço de meia hora
de telas de instalação.

Os quatro processadores não são enfeite. O gerador de carga e a aplicação dividem a máquina, e com
menos processadores o gerador rouba o tempo de que a aplicação precisa, então os números que você
mede descrevem o gerador. Com dois processadores e 2 GB de memória todas as aulas ainda funcionam; os
seus tempos vão diferir mais das transcrições, e as aulas 4 e 6, que rodam Java, vão demorar para
começar.

**Instalado** é uma boa escolha se você já usa Ubuntu 24.04, ou o WSL com a distribuição Ubuntu 24.04
no Windows. No macOS, ou em outro Linux, as mesmas ferramentas existem, mas as versões e os comandos
de instalação diferem dos impressos aqui. **Online** aparece para você saber que existe, não como
recomendação: você pagaria por hora por algo que o seu computador faz de graça, e a aplicação só
escuta em `127.0.0.1`, então um endereço público não traz vantagem nenhuma.

## Com Multipass

Instale o Multipass pelo site dele e depois, no terminal do seu próprio computador:

```sh
multipass launch 24.04 --name nft --cpus 4 --memory 4G --disk 20G
multipass shell nft
```

**Esses dois comandos não foram rodados para este curso**, porque o computador em que ele foi gravado
não roda hipervisor. A máquina das transcrições foi montada com a mesma versão do Ubuntu e os mesmos
pacotes, sem um. O primeiro comando cria a máquina virtual e o segundo abre um shell dentro dela. Tudo
daqui em diante acontece nesse shell.

Três pequenas diferenças em relação às transcrições são esperadas e não fazem mal:

- O prompt aqui é `ana@nft`, e o seu vai ser `ubuntu@nft`, porque o Multipass chama o usuário de
  `ubuntu`.
- `multipass shell nft` também é o jeito de abrir um segundo terminal na mesma máquina. Várias aulas
  precisam de um: a aplicação roda no primeiro e o teste de carga no segundo.
- Num Mac com Apple silicon, o processador da VM é ARM. Onde uma aula baixa um programa feito para um
  processador, ela dá o nome do arquivo para `x86_64`, o das transcrições, e diz qual nome usar para
  ARM.

## Duas coisas que acontecem no seu próprio computador

Um leitor de tela precisa de uma área de trabalho, e a VM não tem, então a aula 15 roda um no seu
próprio computador: NVDA no Windows, VoiceOver no macOS, Orca no Linux. As aulas 10 e 13 também
mostram as auditorias que vêm nas ferramentas de desenvolvedor do Chrome, que rodam no navegador que
você já tem. Para isso a página precisa chegar ao seu navegador de dentro da VM, e a seção depois da
próxima diz como.
