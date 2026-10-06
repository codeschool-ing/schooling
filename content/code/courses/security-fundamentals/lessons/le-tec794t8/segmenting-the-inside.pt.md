---
title: Segmentando o lado de dentro
version: 1
---

O laboratório tem quatro segmentos porque a livraria é pequena. Uma organização de verdade divide o
lado de dentro em mais partes, e **segmentação** é o nome geral para dividir uma rede em zonas com
caminhos controlados entre elas. A DMZ é um segmento; a mesma ideia aplicada a todo o resto é o que
impede uma máquina comprometida de virar uma empresa comprometida.

### O que separar

Máquinas ficam no mesmo segmento quando têm a mesma exposição e o mesmo valor, e em segmentos
diferentes quando uma não deveria alcançar a outra livremente:

| segmento | o que tem nele | por que fica separado |
|---|---|---|
| serviços públicos (DMZ) | o servidor web da loja | o mais exposto, o mais provável de ser comprometido |
| servidores | o banco, o servidor de arquivos | o mais valioso |
| equipe | notebooks e desktops | leem e-mail e navegam, que é por onde atacantes entram |
| gestão | as máquinas de onde os administradores trabalham | guardam as chaves de todo o resto |
| visitantes e dispositivos | o Wi-Fi de visitas, impressoras, câmeras, a maquininha de cartão | ninguém controla o que roda neles |

A linha de visitantes e dispositivos pega as pessoas desprevenidas. Uma impressora, uma smart TV na
sala de reunião ou uma câmera rodam software que o dono nunca atualiza e não consegue inspecionar.
Numa rede plana, ficam ao lado do banco. Num segmento próprio, com uma regra que não deixa alcançar
nada de que não precisam, a fraqueza deles fica só com eles.

### Norte-sul e leste-oeste

O tráfego que atravessa o perímetro, entre o lado de dentro e a internet, se chama **norte-sul**. O
tráfego entre máquinas dentro da rede é **leste-oeste**. O perímetro vê o norte-sul e nada mais. Quase
tudo o que um atacante faz depois de entrar, olhar em volta, ir de uma máquina para a próxima, chegar
ao banco, é leste-oeste, e uma rede que só filtra na borda nunca vê isso.

A segmentação põe pontos de filtragem nos caminhos leste-oeste. No laboratório, o `fw` por acaso fica
entre os quatro segmentos, então o mesmo equipamento faz os dois trabalhos. Em redes maiores, os
segmentos muitas vezes são **VLANs**, redes virtuais separadas que compartilham os mesmos switches,
com um firewall ou um roteador com regras entre elas.

### Até onde ir

Cada fronteira é um conjunto de regras para escrever e manter correto, então a segmentação tem o
mesmo custo de qualquer outra camada da aula 4. Uma ordem sensata para uma organização pequena é a
tabela acima, de cima para baixo: primeiro pôr os serviços públicos numa DMZ, depois separar os
servidores valiosos das máquinas da equipe, depois os dispositivos que ninguém controla.

Levada ao limite, a segmentação deixa de ser sobre zonas: cada carga de trabalho ganha a própria
fronteira, e cada conexão entre duas delas precisa ser permitida explicitamente. Isso é
**microssegmentação**, e é uma das ideias com que a aula 7 constrói o Zero Trust. As aulas 4 e 21 de
`networks-security` vão mais longe com as duas, para quem está numa trilha que o inclui.
