---
title: Toda máquina tem um dono
version: 1
---

**Um achado sem dono é um achado que ninguém corrige.** O relatório de desvio pôs um nome ao lado de
cada linha porque o `hosts.csv` tem uma coluna `owner`, e as duas máquinas sem linha receberam a única
frase que o relatório pode dizer sobre elas: ninguém é dono. Numa organização maior que a Jatobá essa
lista cresce até virar um **banco de dados de gestão de configuração**, uma CMDB, e o valor dela está
nos mesmos poucos campos mantidos verdadeiros.

| campo | o que depende dele |
|---|---|
| dono | quem recebe os achados das aulas 1, 16 e 18, e quem aprova uma exceção |
| papel | que linha de base se aplica, e a que anel da aula 17 a máquina pertence |
| criticidade | como as prioridades da aula 16 são pesadas, e que anel vai por último |
| endereço e nome | como toda ferramenta a encontra, e como uma linha de log chega até ela |
| ciclo de vida | quando entrou em operação, quando o sistema operacional dela para de receber atualizações, quando é aposentada |

**O dono é uma pessoa, não uma equipe.** "A TI" não é dona de nada: um achado mandado para uma equipe é
lido por todos e tratado por ninguém. Uma pessoa pode delegar, mas o nome na linha é quem responde
quando o achado atrasa.

## As máquinas no fim da vida

Ciclo de vida é o campo que mais fica vazio, e o que falha mais em silêncio. O Ubuntu 24.04 recebe
atualizações de segurança padrão até 2029; uma máquina que ainda o rode depois disso não recebe
correção nenhuma, e a comparação da aula 16 a mostrará limpa, porque nenhum aviso vai citar uma versão
corrigida para uma versão que ninguém corrige. **Um sistema no fim da vida é um achado que nenhum
scanner informa**, então o inventário tem de informar: a data está na linha, e o relatório avisa com um
ano de antecedência.

## Mantendo a lista verdadeira

Uma lista atualizada de memória se deteriora. Três hábitos a mantêm honesta:

- **A lista é conferida contra medição numa agenda**, como esta aula fez: cada máquina não listada e
  cada máquina listada que não respondeu é uma linha num relatório que alguém lê.
- **Ligar uma máquina na rede e acrescentá-la à lista são um ato só.** O controle de acesso à rede da
  aula 4 pode exigir isso: uma porta só abre para um dispositivo que o inventário conhece.
- **Aposentar uma máquina é um passo, não uma ausência.** Ela sai da lista, as chaves dela saem do
  bastião e o endereço é liberado; senão a lista e a rede discordam de um jeito que parece uma máquina
  sumida.
