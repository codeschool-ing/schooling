---
title: No computador de um cliente
version: 1
---

Duas coisas impedem a ajuda do processador de chegar a um hypervisor num PC comum, e as duas são
frequentes.

**Ela está desligada no firmware.** Muitos PCs saem de fábrica com o VT-x ou o AMD-V desativado. Ele é
ligado na configuração do UEFI, sob um nome que varia de fabricante para fabricante: *Intel
Virtualization Technology*, *VT-x*, *SVM Mode*, *AMD-V*. Um hypervisor num computador assim ou se
recusa a ligar um convidado ou, como o laboratório daqui, volta a imitar o processador e roda com uma
lentidão dolorosa.

**Outra coisa já a pegou.** No Windows, o Hyper-V, o WSL 2, a Área Restrita do Windows e o recurso de
segurança chamado integridade de memória ligam todos o hypervisor da Microsoft, e aí o Windows é um
convidado, como a seção 02 disse. O VirtualBox e o VMware Workstation ainda conseguem rodar por cima
dele, por um componente do Windows chamado *Plataforma do Hipervisor do Windows*, mas deixam de ser
donos dos recursos do processador, e algumas coisas ficam mais lentas ou param de funcionar. Quando o
VirtualBox de um cliente quebrou no dia em que ele instalou o WSL, é por isso.

O que rodar para descobrir:

```sh
systeminfo                       # Windows: under "Hyper-V Requirements", or a line saying a hypervisor was detected
Get-ComputerInfo -Property HyperV*   # Windows PowerShell: the same answers, one per line
sysctl -a | grep -i vmx          # macOS on an Intel processor: VMX in the list means VT-x is there
egrep -c "vmx|svm" /proc/cpuinfo # Linux: more than 0 means the processor offers it
kvm-ok                           # Ubuntu, from the cpu-checker package: whether KVM can be used
```

**Nenhum deles foi rodado para esta aula**, e nenhum está no host do curso. No Windows, o `systeminfo`
lista *Virtualization Enabled In Firmware*, ou diz que um hypervisor foi detectado, que é o caso do
Hyper-V. A aba *Desempenho* do Gerenciador de Tarefas mostra *Virtualização: Habilitado* na página da
CPU. Um Mac com processador da Apple roda convidados feitos para ARM em velocidade cheia, e um
convidado Windows ou Linux feito para Intel só por imitação, tão devagar quanto o laboratório daqui.
