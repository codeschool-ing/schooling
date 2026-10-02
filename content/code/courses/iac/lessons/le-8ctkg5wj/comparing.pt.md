---
title: Comparando as quatro, e quando um agente compensa
version: 1
---

A aula 18 e esta já mostraram o mesmo trabalho pequeno quatro vezes: um diretório, uma página, um
arquivo de configuração e algo que só roda quando a configuração muda. **Por baixo das sintaxes
diferentes, as quatro ferramentas compartilham um modelo**: recursos com um estado desejado, uma execução
que confere cada um e só age onde há diferença, e um jeito de dizer que um recurso depende de outro. O
que muda é tudo em volta desse modelo.

| | Ansible | Puppet | Chef | Salt |
|---|---|---|---|---|
| escrito em | YAML, com Jinja | linguagem própria do Puppet | Ruby | YAML, com Jinja |
| em cada máquina | só SSH e Python | um agente | um agente, o `chef-client` | um agente, o minion |
| quem começa uma execução | a máquina de controle, quando alguém roda | o agente, a cada 30 minutos por padrão | o cliente, num horário fixo | o master, na hora; ou o minion |
| ordem | as tarefas, como escritas | um grafo de relacionamentos, depois o manifest | os recursos, como escritos | o arquivo, a menos que um requisite diga outra coisa |
| sem servidor | nunca precisa de um | `puppet apply` | `chef-client --local-mode` | `salt-call --local` |
| "só quando aquilo mudou" | um handler | `notify` e `refreshonly` | `notifies` | `onchanges` |

Duas linhas merecem uma frase cada.

**Quem começa uma execução** é a linha que muda como um time trabalha, pelos motivos da segunda seção
desta aula: um agente corrige o drift no próprio horário, inclusive o drift que alguém quis fazer.
**Ordem** é a linha que muda como uma descrição é lida. No Ansible e no Chef, de cima para baixo é a
verdade. No Puppet, os relacionamentos são, e de cima para baixo é só o critério de reserva. O Salt numera os
states na ordem do arquivo e deixa os requisites os moverem.

As empresas por trás delas mudaram de dono, o que importa quando você procura documentação, suporte ou
uma licença. O Chef pertence à Progress Software desde 2020. O Puppet foi comprado pela Perforce em
2022. A SaltStack foi comprada pela VMware em 2020, e a VMware pela Broadcom, então o Salt está lá
agora. O Ansible pertence à Red Hat, que é parte da IBM.

## Quando um agente compensa

Comece pelo que as máquinas são. **Máquinas de vida longa, que são consertadas em vez de substituídas,
são onde um agente se paga**: centenas de servidores que precisam ficar como descritos por anos, sob
uma auditoria que pede provas, são mantidos certos por algo que confere a cada meia hora e informa o
que corrigiu. Se você entrar num time que roda Puppet, Chef ou Salt, esse é o motivo provável, e
reconhecer o modelo é a habilidade de que você precisa ali.

Onde as máquinas vivem pouco, o argumento se inverte. Uma máquina que é substituída, e não editada,
tem pouco tempo para derivar e ninguém para entrar nela e editar, e a configuração passa para a imagem
a partir da qual ela é construída. Essa é a aula 20, com o Packer, e é o lado imutável da troca que a
aula 1 apresentou. Para a configuração que ainda é necessária no boot ou em poucos hosts de vida
longa, uma ferramenta sem agente rodada a partir de um pipeline é mais leve: nada para instalar, nenhum
servidor, nenhum certificado. É por isso que a aula 18 ensina o Ansible e esta aula só mostra as
outras.

O que se leva para qualquer lugar, seja qual for a ferramenta que um trabalho puser na sua frente, é o
conjunto de perguntas desta aula: o que um recurso declara, o que uma execução faz quando ele já bate,
o que acontece com uma edição à mão, e quem decide a ordem.
