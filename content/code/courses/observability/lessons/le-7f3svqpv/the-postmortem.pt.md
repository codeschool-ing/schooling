---
title: O postmortem do incidente da aula 17
version: 1
---

Um postmortem tem uma forma, e mantê-la deixa as revisões de uma equipe comparáveis e rápidas de ler. Eis
o incidente da aula 17 escrito do jeito que uma equipe escreveria, com todo horário e número tirado da
captura daquela aula.

**Resumo.** Em 2 de outubro, uma versão do payments fez uma cobrança em oito falhar. Os checkouts falharam
por uns quatro minutos até a versão ser revertida. O alerta de queima rápida acionou o plantão três
minutos depois da versão, e o incidente foi encerrado nove minutos depois de começar.

**Impacto.**

| | |
|---|---|
| usuários | mais ou menos um checkout em nove falhou com 502 por quatro minutos |
| serviços | o payments, e através dele o orders e a vitrine |
| orçamento de erros | uma taxa de queima de cinco minutos de uns 15 a 19; a de trinta minutos passou de 12 |
| dados | nada perdido; cobranças que falharam não foram feitas, então ninguém pagou por um pedido que falhou |

**Linha do tempo**, todos os horários em UTC, a partir das marcas:

| horário | evento |
|---|---|
| 20:46:49 | versão 1.4.2 do payments lançada |
| 20:49:58 | page: `CheckoutBudgetBurningFast` |
| 20:50:00 | SEV-2 declarado, ana no comando |
| 20:51:01 | payments revertido para a 1.4.0 |
| 20:51:58 | page resolvido |
| 20:55:55 | incidente encerrado |

**Fatores contribuintes.** A tabela da seção anterior: o bug como gatilho, o mock e o canary ausente como
defesas que faltaram, a janela de cinco minutos como o custo da detecção, e a marca de deploy como a
defesa que funcionou.

**O que deu certo.** O page era um sintoma, então descrevia o que os clientes viam. A versão estava
marcada, então *o que mudou?* levou um comando. A reversão foi um passo só e também foi marcada.

**Ações.**

| ação | dono | prazo |
|---|---|---|
| acrescentar as respostas de erro da rede de cartões ao mock do payments | Carla | 20 de outubro |
| lançar o payments primeiro em uma instância e observar a taxa de erros dela antes das outras | Bruno | 31 de outubro |
| corrigir o tratamento de erro da 1.4.2 e lançá-la pelo canary | ana | 24 de outubro |

O documento nomeia pessoas só como donas de ações e como papéis na linha do tempo. **Em lugar nenhum ele
diz quem escreveu o bug**, porque esse fato não muda nada na lista acima, e perguntar por ele deixaria o
próximo postmortem mais curto.
