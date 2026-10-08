---
title: Contenção de curto prazo: as opções
version: 1
---

A **contenção de curto prazo** é o movimento rápido que impede o dano de crescer enquanto a investigação
continua. Não é um conserto: o buraco por onde o invasor entrou continua lá, e o que ele deixou para trás
também. A aula 14 trata dos dois. Aqui a pergunta é só o que parar primeiro, e quanto isso custa.

O playbook da aula 11 lista os movimentos para uma conta comprometida. Lado a lado, cada um tem um preço em
quatro moedas:

| ação | para | quebra | avisa o outro lado | desfeita por |
|---|---|---|---|---|
| **bloquear o endereço de origem** no firewall | conexões novas daquele endereço | quase nada | sim, na próxima tentativa | apagar a regra |
| **restringir a saída de um host** ao que ele precisa | dados saindo para qualquer outro lugar | o que mais o host costumava alcançar | sim, quando uma transferência falha | apagar a regra |
| **isolar o host** da rede | tudo de e para ele | o serviço que ele presta; o acesso remoto da própria equipe | sim, na hora | ligar de volta |
| **bloquear a conta**, trocar a senha, revogar as chaves | as credenciais roubadas, em todos os hosts | o trabalho do dono, até receber novas | sim, no próximo login | emitir credenciais novas, nunca as antigas |
| **desligar o host** | tudo nele | o serviço, e a memória, que era evidência | sim | nada traz a memória de volta |

Duas colunas decidem a maioria dos casos. **O que quebra** é por que o negócio tem voz: isolar o servidor de
arquivos para o trabalho do escritório inteiro, e essa decisão não é só do analista. **Desfeita por** é por
que os movimentos mais leves vêm primeiro quando bastam. Uma regra de firewall se apaga num segundo; a memória
de um servidor desligado não se lê de novo.

A coluna que as pessoas esquecem é **avisa o outro lado**. Toda ação aqui é visível para quem está na outra
ponta, e um invasor que percebe que foi descoberto pode se apressar, ou usar uma segunda entrada que a equipe
ainda não achou. Isso não é motivo para esperar. É motivo para conhecer o escopo antes, e por isso a aula 12
veio antes desta, e para fazer os movimentos que fecham as entradas conhecidas ao mesmo tempo, não um por um
ao longo de uma manhã.

Na quinta, os dados já saíram: 612 MB naquela noite. O que resta proteger é tudo que ainda não saiu, e a conta
que ainda consegue fazer login.
