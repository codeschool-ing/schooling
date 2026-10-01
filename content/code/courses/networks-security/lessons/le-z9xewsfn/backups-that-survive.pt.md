---
title: Backups que o atacante não alcança
version: 1
---

A alavanca do ransomware é simples: os arquivos estão cifrados e a única cópia da chave está com o
atacante. **Um backup que pode ser restaurado tira essa alavanca**, e o ransomware moderno sabe
disso, por isso procura os backups primeiro e os cifra ou apaga antes de se anunciar. Um backup em
que as máquinas infectadas podem escrever é um backup que o ransomware pode destruir.

O desenho de rede que vem daí é uma questão de **direção**:

| desenho | quem inicia a conexão | um cliente infectado pode danificar o backup? |
|---|---|---|
| os clientes enviam para uma pasta compartilhada no servidor de backup | o cliente | sim: tudo o que o cliente pode escrever, o software nele pode sobrescrever |
| o servidor de backup busca nos clientes | o servidor de backup | não pela rede: nada de dentro pode abrir uma conexão com ele |
| o backup também é copiado offline ou para um armazenamento imutável | um processo à parte, com agendamento | não: a cópia não pode ser alterada por um período definido, por ninguém |

Nos termos da matriz da aula 4, o servidor de backup tem uma **linha** (pode alcançar as máquinas de
que faz backup, na única porta que o agente dele usa) e uma **coluna vazia** (nada pode iniciar uma
conversa com ele, exceto a administração a partir do segmento de gestão). É o mesmo formato da DMZ,
desenhado pelo motivo oposto: lá as células vazias protegem o lado de dentro da DMZ, aqui protegem o
backup do lado de dentro.

Duas práticas que a rede não fornece e que continuam sendo do defensor:

- testes de restauração, com agendamento, porque um backup do qual ninguém restaurou nada é uma
  esperança, não um backup;
- credenciais que o domínio não conhece: se a conta de administrador do sistema de backup é a
  mesma que o resto da empresa usa, o atacante que tomou o resto da empresa toma essa também.

## O que a rede contribui, numa lista só

Somados, os controles de rede desta aula transformam cada etapa do padrão num lugar onde o ataque
pode parar:

- na entrega, o gateway de e-mail e o sandboxing, os recursos de NGFW da aula 2;
- no primeiro clique, o DNS protetivo;
- contra a propagação, os firewalls de host;
- ao primeiro sinal, uma regra de quarentena;
- no fim, backups que nenhuma máquina infectada alcança.

Nenhum deles substitui a
pessoa que denuncia cedo uma mensagem suspeita; cada um compra tempo para que essa pessoa faça
diferença.
