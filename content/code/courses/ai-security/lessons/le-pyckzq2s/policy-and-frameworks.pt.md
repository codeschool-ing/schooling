---
title: Uma política, dois frameworks e um calendário
version: 1
---

O registro e a revisão são a máquina. Em volta deles ficam três coisas que são quase só palavras, e
que importam porque decidem quem tem o direito de dizer não.

## Uma política que cabe numa página

Uma política de IA que ninguém lê não protege ninguém. A da Tarefa cabe numa página, e cada linha
pode ser conferida contra algo que este curso construiu:

1. **todo sistema que chama um modelo está no registro**, com um dono que é funcionário; o
   `register.py` garante;
2. **uma mudança que amplia o alcance é revisada antes de ir ao ar**, pelo dono e por alguém que não
   é o autor; o `review.py` garante;
3. **dados pessoais só chegam a um modelo com base legal escrita**, e só o que a finalidade pede;
   aulas 11 e 12;
4. **credenciais são por componente, restritas e trocadas**, nunca num prompt nem num repositório;
   aula 17;
5. **arquivos que decidem o que o assistente diz são versionados e aprovados por nome**; aula 20;
6. **todo alerta tem runbook, e todo incidente uma linha do tempo**; aulas 22 e 24;
7. **quem encontra um problema pode parar o sistema** que o tem, sem pedir antes.

A última linha é a que precisa de uma política e não de um programa. A pessoa de plantão às três da
manhã, ou quem percebe o classificador respondendo no formato errado, precisa saber que desligar uma
funcionalidade está dentro da sua autoridade. Sem isso escrito, as pessoas esperam permissão, e a
aula 24 mostrou quanto custa esperar.

## NIST AI RMF e ISO/IEC 42001

Dois documentos aparecem sempre que um cliente, um auditor ou um investidor pergunta como uma
empresa gerencia o risco de IA, e ajuda saber o que cada um é.

O **NIST AI Risk Management Framework** (AI RMF 1.0, publicado em janeiro de 2023) é voluntário e
gratuito. Ele organiza o trabalho em quatro funções, e o perfil de IA generativa que o NIST publicou
em julho de 2024 (NIST AI 600-1) as aplica a sistemas como o da Tarefa. As aulas do curso se
encaixam nelas com naturalidade:

| função | o que pede | onde este curso fez |
|---|---|---|
| Govern | políticas, papéis, responsabilização, uma cultura que relata problemas | aulas 8, 20, 25 |
| Map | o contexto, para que o sistema serve, e o que pode dar errado | aulas 1, 4, 12, 13 |
| Measure | testar e acompanhar os riscos mapeados | aulas 2, 3, 22, 23 |
| Manage | tratar os riscos, e responder quando um acontece | aulas 5 a 7, 9 a 11, 14 a 19, 21, 24 |

A **ISO/IEC 42001**, publicada em dezembro de 2023, é uma norma de sistema de gestão para IA,
construída como a ISO/IEC 27001 é para segurança da informação: requisitos de uma política de IA,
papéis, avaliação de riscos, uma avaliação de impacto para cada sistema de IA, e um conjunto de
controles de referência no seu Anexo A, com um ciclo de auditorias internas e melhoria. Ao contrário
do framework do NIST, **ela pode ser certificada** por um auditor externo, e é por isso que aparece em
contratos e licitações.

Nenhum dos dois diz como impedir um prompt de vazar uma chave. Eles perguntam se você tem um jeito de
decidir, registrar e conferir essas coisas, e se ele funciona. Uma empresa que fez o trabalho deste
curso tem a maior parte das evidências que qualquer um dos dois pede; o que os frameworks acrescentam
é o hábito de mostrá-las, todo ano, a alguém de fora.

## O calendário

Governança que acontece uma vez é um projeto. Quase tudo o que este curso construiu tem um ritmo, e
escrever o ritmo é o que faz acontecer quando ninguém se lembra:

| com que frequência | o quê | aula |
|---|---|---|
| a cada pull request | a suíte | 23 |
| toda noite | a taxa do que está implantado, contra o teto | 23 |
| todo mês | a lista de alertas, com o que disparou | 22 |
| a cada 90 dias | a troca das chaves | 17 |
| todo trimestre | o registro contra as faturas dos fornecedores | 25 |
| todo ano | a revisão de cada sistema, o registro de ameaças, a própria política | 13, 25 |
| depois de cada incidente | a revisão, e as ações dela na suíte | 24 |

Este é o fim do curso. Os controles dele não são exóticos; a maioria são algumas dezenas de linhas de
Python e um arquivo JSON. O que os faz funcionar é a mesma coisa a que toda aula voltou: **cada um
roda sozinho, diz o que encontrou e sai com um status que o programa de outra pessoa lê.**
