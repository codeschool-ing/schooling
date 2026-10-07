---
title: O seu laboratório, montado por você
version: 1
---

Toda transcrição deste curso foi impressa por uma rede de verdade, e quem monta essa rede é você, no
seu próprio computador. Não é um rack de equipamentos. **É uma máquina Linux com Ubuntu 24.04, na
qual um script monta cada rede de que o curso precisa com peças do kernel Linux**: um namespace de
rede para cada dispositivo, um cabo virtual entre dois deles, uma bridge dentro de um namespace para
cada switch, e o FRR, a suíte de roteamento de código aberto, para os roteadores. Um escritório
inteiro, com switch, roteador e provedor, cabe numa máquina só, e nada disso encosta na rede em que o
seu computador está de verdade.

Há três jeitos de ter essa máquina. Escolha a máquina virtual, a não ser que tenha um motivo para não
escolher.

| | o que é | quanto custa |
|---|---|---|
| instalado | o Ubuntu 24.04 num computador só para isso | nada a comprar, e uma suíte de roteamento, um servidor DHCP e umas vinte ferramentas de rede instalados nesse computador de vez |
| **uma máquina virtual** (recomendado) | o Ubuntu Server 24.04 LTS num hipervisor, no computador que você já usa | 2 processadores, 2 GB de memória e 10 GB de disco enquanto ela roda |
| online | uma pequena máquina virtual Linux alugada num provedor de nuvem | dinheiro por hora, enquanto ela existir |

**A máquina virtual é a escolha** porque o laboratório roda como root, carrega módulos do kernel e
cria e apaga dezenas de interfaces, e uma máquina que você apaga e refaz em meia hora é o lugar certo
para isso. Os números da tabela são folgados: na máquina em que este curso foi gravado, a rede mais
movimentada do curso usou cerca de 60 MB de memória a mais que o sistema parado, e os pacotes
ocuparam menos de 300 MB de disco.

O hipervisor depende do computador que você tem. O **Multipass**, ferramenta da Canonical, cria uma
máquina virtual Ubuntu com um comando no Windows, no macOS e no Linux, e é o caminho mais curto:

```sh
multipass launch 24.04 --name netlab --cpus 2 --memory 2G --disk 10G
multipass shell netlab
```

O primeiro comando baixa o Ubuntu e cria a máquina, e o segundo abre um shell dentro dela, com o
usuário `ubuntu`. Qualquer outro hipervisor serve, ao preço das telas do instalador: VirtualBox no
Windows e no Linux, UTM no Mac, Hyper-V no Windows Pro, GNOME Boxes ou virt-manager no Linux. Instale
nele o Ubuntu Server 24.04 LTS, com o servidor OpenSSH se o instalador oferecer. Num Mac com
processador da Apple, escolha a edição ARM do Ubuntu Server; os pacotes de que o laboratório precisa
também existem para ela.

**Aqueles dois comandos do Multipass não foram rodados para este curso.** Ele foi gravado numa máquina
virtual Ubuntu Server 24.04 feita com o QEMU a partir da imagem de nuvem do próprio Ubuntu, num
computador sem virtualização por hardware, então o processador era emulado em software. Tudo
funcionou, mais devagar do que vai funcionar para você: montar uma rede levou entre 20 e 51 segundos
lá.

**Instalado** é a escolha certa se você tem um computador sobrando que pode apagar. No que você usa
todo dia é a escolha errada, pelo mesmo motivo que torna a máquina virtual a certa. **Online** está
aqui para você saber que existe. A menor máquina de qualquer provedor, com Ubuntu 24.04, serve, e o
laboratório nunca expõe um serviço à internet, porque todo endereço dele é privado ou reservado para
documentação. Mas ela custa dinheiro enquanto existir, e nenhuma aula deste curso depende do plano
gratuito de um provedor.

**Um contêiner não é um laboratório.** O WSL2 no Windows e um contêiner Docker dão os dois um shell
Ubuntu, e os dois rodam sobre um kernel que veio com eles, que em geral não tem módulos e não pode
ganhar novos. O laboratório pede cinco: `veth` para os cabos, `bridge` para os switches, `8021q` para
as VLANs, `bonding` para os cabos agregados da aula 21 e `wireguard` para o túnel da aula 4. A seção
sobre falhas mostra o que um contêiner responde.

Os prompts deste curso foram gravados nessa máquina virtual, que se chama `lab` e cujo usuário é
`ana`. Os seus vão mostrar os seus nomes: `ubuntu@netlab` no Multipass, por exemplo. A próxima seção
põe o laboratório na máquina.
