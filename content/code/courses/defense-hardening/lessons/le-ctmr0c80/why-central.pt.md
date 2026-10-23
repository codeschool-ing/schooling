---
title: Por que a configuração vai para um lugar só
version: 1
---

**Numa máquina, endurecer é uma lista de comandos. Em cinquenta, é uma questão de quem decide e de
onde a decisão mora.** A aula 2 escreveu a linha de base do portal como uma verificação e um playbook
para um servidor. Um escritório do tamanho da Jatobá tem alguns servidores e algumas dezenas de
estações, e cada uma se desvia do seu jeito: uma configuração mudada por causa de uma impressora que
depois foi trocada, uma regra afrouxada por uma tarde, um notebook que estava fora da rede quando todo
o resto foi atualizado.

A imagem errada é a de que uma frota são muitas cópias da mesma máquina, então os mesmos comandos
digitados em cada uma as manteriam iguais. Elas não continuam iguais, e ninguém digita os comandos na
quadragésima máquina no mesmo dia que na primeira. O que mantém uma frota consistente é o **estado
desejado**: uma descrição de como cada máquina deve ser, guardada num lugar central, e um mecanismo
que compara cada máquina com ela e devolve o que difere, num horário, sem ninguém precisar lembrar.

Três coisas decorrem de levar a configuração para um lugar só, e cada uma é uma propriedade de
segurança por si.

**A regra pode ser lida.** "Toda estação recusa root por SSH" é uma linha que alguém pode revisar, em
vez de um fato verdadeiro nas máquinas que alguém visitou. Um auditor pede a regra, não quarenta
capturas de tela.

**As diferenças são declaradas.** Nem toda máquina deve ser igual. Uma estação e um servidor precisam
de configurações diferentes, e uma máquina pode precisar de uma exceção. A configuração central faz
de cada diferença uma declaração escrita, presa a um grupo ou a uma máquina, que é a única forma em
que uma diferença pode ser revisada. Uma diferença não declarada é desvio.

**O desvio é corrigido sem precisar ser notado antes.** Uma configuração mudada à mão volta na
próxima execução, tenha alguém visto a mudança ou não. Isso é uma defesa em si: um invasor que
afrouxa uma configuração para continuar lá dentro a vê apertada de novo em uma hora, e a mudança
aparece no log da execução que a desfez.

## Duas famílias de ferramentas

Em redes Windows ligadas a um domínio do Active Directory, o mecanismo é a **Política de Grupo**,
embutida no sistema operacional, e as duas próximas seções a explicam. Em máquinas que não são
membros do domínio, notebooks gerenciados pela internet entre elas, a resposta da Microsoft é o
**Intune**, um serviço de gerenciamento de dispositivos móveis que empurra perfis de configuração para
dispositivos inscritos. Nenhum dos dois foi executado para este curso, porque o laboratório não tem
máquina Windows; são ensinados a partir do comportamento documentado pela Microsoft.

No Linux o mecanismo é uma **ferramenta de gerência de configuração**: Ansible, Puppet, Chef ou Salt.
As três últimas seções desta aula montam a metade Linux no laboratório com o Ansible, para três
máquinas com trabalhos diferentes, e a rodam num timer. As ideias passam de uma família para a outra
quase sem mudança, e os erros também.
