---
title: Quanto um control plane custa em horas
version: 1
---

O dinheiro é pouco. **As horas não são**, e são as mesmas seja qual for o custo das máquinas. Cada linha
abaixo é trabalho que um control plane gerenciado faz por você e que rodar o seu devolve, com a lição
deste curso que o mostrou:

| trabalho | com que frequência | onde apareceu neste curso |
|---|---|---|
| atualizar o control plane, uma versão menor de cada vez | o Kubernetes lança três versões menores por ano | a lição 47 junta um nó com o kubeadm; uma atualização é a mesma ferramenta |
| fazer backup do etcd, e ensaiar a restauração | backups diários, restaurações ensaiadas em calendário | a lição 47 tira e restaura um snapshot |
| renovar certificados | os do kubeadm expiram em um ano | a lição 47 leu `364d` de tempo restante |
| vigiar o API server e o etcd, e ser acordado quando falham | sempre | a lição 41 lê o que eles expõem |
| substituir uma máquina do control plane que falhou | quando acontece | a lição 32 perdeu um worker; uma máquina do control plane é mais difícil |

**Atualizações são a linha que cresce.** Cada versão menor recebe suporte por cerca de catorze meses, e
um cluster só pode subir uma versão menor de cada vez, então um cluster que fica duas versões para trás
precisa de duas atualizações seguidas, cada uma com os seus testes. Um serviço gerenciado faz a metade
do control plane disso por você e cobra suporte estendido quando você fica para trás.

## Pondo as horas na soma

A comparação vira então uma soma com um termo que este curso não consegue preencher por você, o preço
de uma hora da pessoa que faria o trabalho:

`próprio = 3 × máquina × 730 + horas por mês × preço de uma hora`

`gerenciado = 73 dólares por cluster por mês`

Só como ilustração, com números escolhidos para a conta e não tirados de lista de preços nenhuma: se
operar o control plane tomasse oito horas por mês e uma hora custasse 50 dólares, só as horas dariam
400 dólares por mês, mais de cinco vezes a taxa, antes de uma única máquina. O argumento não depende dos
números: **para um ou poucos clusters, a taxa é muito menor que o tempo que ela substitui**, onde quer
que a linha entre as duas caia para você.

Os nós workers, de novo, não estão em nenhuma das somas. Nem as horas gastas com as aplicações, que são
as mesmas de qualquer jeito: um control plane gerenciado não atualiza os seus Deployments, não escreve
as suas network policies nem escolhe os seus requests.
