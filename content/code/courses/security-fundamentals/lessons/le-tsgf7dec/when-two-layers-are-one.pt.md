---
title: Quando duas camadas são uma só
version: 1
---

Contar camadas é fácil e engana. **Dois controles só são duas camadas se falham por motivos
diferentes.** Se uma causa derruba os dois, eles são uma camada desenhada duas vezes, e o queijo
suíço tem uma fatia com os furos impressos em duas páginas.

Quatro jeitos de as camadas virarem uma só:

| causa compartilhada | exemplo | como aparece |
|---|---|---|
| **o mesmo segredo** | o portal e a conta de administrador do servidor usam a mesma senha | um vazamento abre os dois |
| **a mesma pessoa** | o único administrador que cuida do firewall também aprova as mudanças de regra | um erro, ou uma conta comprometida, passa pelos dois |
| **o mesmo software** | dois firewalls em fila do mesmo fabricante, na mesma versão | um defeito naquela versão abre os dois |
| **a mesma suposição** | o portal confia em tudo que vem da rede do escritório, e o banco também | um notebook infectado no escritório passa pelos dois |

A última linha é a que este curso mais trabalha. "Tudo que está dentro é confiável" é uma suposição
compartilhada por muitas camadas ao mesmo tempo, e ela derruba todas juntas no momento em que algo
lá dentro deixa de ser confiável. A aula 5 desenha a rede que essa suposição produz e a aula 7 trata
de removê-la.

### Diversidade

A saída é tornar as camadas **independentes**: segredos diferentes, pessoas diferentes, mecanismos
diferentes. No teste do laboratório da seção anterior, as camadas seguraram porque cada uma dependia
de uma coisa diferente. O login dependia da senha da ana; a verificação de permissão dependia das
regras do próprio portal sobre holerites; a permissão de arquivo dependia do sistema operacional; o
log não dependia de nada, já que registrou o que aconteceu qualquer que fosse o resultado. A senha
vazada derrubou a primeira e não tocou nas outras.

### Mais camadas nem sempre é melhor

Camadas têm custo: cada uma é algo para configurar, atualizar e entender. Uma camada que ninguém
mantém apodrece num furo com nome tranquilizador. E a complexidade é ela mesma uma fonte de falhas:
uma defesa com doze controles sobrepostos que ninguém entende por inteiro produz regras que se
contradizem, e a contradição é o furo.

O objetivo é ter camadas independentes o bastante para que nenhuma falha sozinha vire incidente, e
poucas o bastante para que cada uma seja entendida por alguém responsável por ela. O portal do
laboratório tem quatro, e cada uma falha por um motivo diferente.
