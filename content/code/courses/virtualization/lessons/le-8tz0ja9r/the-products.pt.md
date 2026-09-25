---
title: Workstation, Player e Fusion
version: 1
---

A VMware faz três hypervisors de desktop, todos tipo 2:

- **Workstation Pro**, para Windows e Linux. Snapshots, clones, várias redes, convidados cifrados.
- **Workstation Player**, a versão gratuita e reduzida para Windows e Linux, que rodava um convidado de
  cada vez e deixava de fora snapshots e clones.
- **Fusion**, a mesma coisa para Mac.

**Os termos mudaram em 2024**, depois que a Broadcom comprou a VMware. O Player foi descontinuado, e o
Workstation Pro e o Fusion Pro ficaram gratuitos, primeiro para uso pessoal e depois, a partir de
novembro de 2024, também para uso em empresas. Os downloads agora vêm do site de suporte da Broadcom,
atrás de uma conta gratuita. Qualquer parte disso pode ter mudado de novo quando você ler, então
**confira os termos atuais do fabricante antes de instalá-lo no computador de uma empresa**, onde
licença é questão jurídica e não técnica.

O que um técnico de suporte encontra na prática é uma mistura: instalações novas do Workstation, e
cópias antigas do Player que ainda ligam os convidados perfeitamente e nunca vão receber outra
atualização. Nada do que vem a seguir depende de qual delas é.

O VMware Workstation não está instalado no host deste curso, e nada nesta aula o rodou. O que rodou é a
parte do VMware que todo hypervisor compartilha: o formato de disco e o jeito de empacotar uma máquina.
