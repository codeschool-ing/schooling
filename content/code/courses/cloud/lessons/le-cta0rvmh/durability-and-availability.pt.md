---
title: Durabilidade e disponibilidade são duas promessas
version: 1
---

"Onze noves" é citado como se quisesse dizer que um repositório de objetos não pode falhar. É um
número sobre uma de duas coisas, e as duas se confundem fácil.

**Durabilidade é se os bytes ainda existem.** O S3 Standard é projetado para 99,999999999% de
durabilidade em um ano. A AWS ilustra com dez milhões de objetos: 10.000.000 × 0,00000000001 =
0,0001 objeto perdido por ano, o que dá um objeto a cada dez mil anos.

**Disponibilidade é se você consegue lê-los agora.** O S3 Standard é projetado para 99,99% de
disponibilidade. Um ano tem 525.600 minutos, e 0,01% deles são uns 53 minutos em que as requisições
podem falhar. Os dados não se perdem nesses minutos; ficam fora de alcance.

| | a pergunta | S3 Standard, projetado para | como é quando falha |
|---|---|---|---|
| durabilidade | os bytes vão sobreviver? | 99,999999999% por ano | um objeto some para sempre |
| disponibilidade | consigo ler agora? | 99,99% | requisições falham, depois voltam a funcionar |

Os dois vêm do mesmo mecanismo. **O Standard guarda cada objeto em dispositivos de pelo menos três
zonas da região**, então um disco que falha, um rack que falha ou uma zona inteira que apaga não
perdem nada, e as outras zonas continuam respondendo. Tire as réplicas e os dois números caem. O S3
One Zone-Infrequent Access guarda os dados numa zona só para cobrar menos: ele é projetado para
99,5% de disponibilidade, e os dados nele se perdem se aquela zona for destruída. Serve para dados
que dá para refazer, como miniaturas geradas a partir de originais guardados em outro lugar.

Um volume de bloco fica mais embaixo nas duas escalas. Ele é replicado só dentro da zona, e a AWS
declara a durabilidade do `gp3` como uma taxa anual de falha de 0,1 a 0,2 por cento, ou seja, um
volume em cada quinhentos a mil falhando num ano. Essa distância é o motivo de um volume ter
snapshots e de um objeto no Standard não precisar de cópias contra falha de hardware.

## O que onze noves não cobre

**Durabilidade é o repositório guardar o que você mandou guardar.** Ela é medida contra discos e
prédios que falham, e não diz nada sobre as requisições que você manda. Quando um script de limpeza
apaga o prefixo errado, quando um deploy sobrescreve uma configuração com um arquivo vazio, ou quando
um atacante com uma chave vazada cifra cada objeto no lugar, o repositório guarda o resultado com
onze noves de cuidado.

As proteções contra isso são outros mecanismos, e cada um custa alguma coisa:

- **Versionamento**, a próxima seção, guarda a versão antiga quando um objeto é sobrescrito ou
  apagado.
- **Replicação** para um bucket em outra região, e melhor ainda em outra conta, mantém uma cópia que
  as credenciais da primeira conta não alcançam.
- **Object lock** torna versões impossíveis de apagar por um período, até por um administrador. É a
  resposta para o caso do atacante, e o `cloud-security` o cobre com o resto dessa defesa.
