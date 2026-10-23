---
title: O firewall do Windows, por programa
version: 1
---

**Nada nesta seção foi executado para este curso.** O laboratório não tem máquina Windows, então o
que vem a seguir é o comportamento documentado pela Microsoft do Windows Defender Firewall, o firewall
embutido em toda versão com suporte do Windows, sem transcrito e sem captura de tela.

## Três perfis

O Windows guarda três conjuntos de regras e aplica um por conexão de rede, de acordo com onde a
máquina acha que está:

| perfil | quando se aplica |
|---|---|
| **Domínio** | a máquina alcança um controlador do domínio de que faz parte: está no trabalho |
| **Privado** | uma rede que o usuário marcou como confiável, como a de casa |
| **Público** | qualquer outra, e o padrão para uma rede que ninguém classificou: um café, um aeroporto |

Esse é o problema do notebook da primeira seção resolvido na configuração: a mesma máquina fica mais
fechada no Wi-Fi de um café do que no escritório, sem ninguém mudar nada. Os padrões são os mesmos
nos três, **entrada bloqueada a menos que uma regra permita, saída permitida a menos que uma regra
bloqueie**.

## Regras sobre um programa

Uma regra do Windows pode nomear um **programa**, pelo caminho do executável, ou um **serviço**, pelo
nome do serviço, além de endereços e portas. Essa é a regra por aplicação desta aula sem contas nem
grupos de controle: o próprio firewall sabe que programa é dono de cada conexão. Uma regra que
bloqueia as conexões de saída de um programa fica assim em PowerShell, a partir da documentação do
módulo `NetSecurity`:

```
New-NetFirewallRule -DisplayName "Portal: no outbound" -Direction Outbound `
    -Program "C:\Portal\portal.exe" -Action Block -Profile Domain,Private,Public
```

**Dois comportamentos pegam as pessoas de surpresa.** Uma regra de bloqueio vence uma regra de
permissão que case o mesmo tráfego, seja qual for a ordem em que foram criadas, então uma exceção se
escreve estreitando o bloqueio, e não acrescentando uma permissão. E na primeira vez que um programa
desconhecido escuta conexões, o Windows pode perguntar ao usuário se permite, o que numa máquina
gerenciada é uma decisão que deveria ser do administrador, e não de quem estiver na frente da tela; a
Política de Grupo pode desligar essa pergunta.

## Gerenciado de forma central

Nas máquinas de um escritório ninguém define essas regras à mão. Elas são empurradas pela **Política
de Grupo**, em *Configuração do Computador, Configurações do Windows, Configurações de Segurança,
Windows Defender Firewall com Segurança Avançada*, ou por um serviço de gerenciamento como o Intune,
que a aula 3 descreve, e a política pode impedir que administradores locais acrescentem regras
próprias. É a mesma disciplina dos arquivos desta aula: o conjunto de regras é escrito uma vez, num
lugar só, revisado ali e aplicado a toda máquina que deveria tê-lo.
