---
title: O que é teste de aceitação
version: 1
---

Uma imagem comum do teste de aceitação do usuário é a de uma última volta do teste de sistema: os
mesmos casos, rodados mais uma vez pelo time de teste, com o nome do cliente na capa. **O teste de
aceitação faz outra pergunta, e quem responde é outra pessoa.** O teste de sistema pergunta se o
produto atende aos requisitos, e quem julga são os testadores. O teste de aceitação pergunta se as
pessoas que vão ficar com o produto conseguem trabalhar com ele, e quem julga são elas. A gerente
do teatro não quer saber se o R5 passa. Ela quer saber se consegue abrir a bilheteria no sábado
com isto.

As duas perguntas se separam mais do que parece. A aula 6 chamou a segunda de **validação**:
estamos construindo a coisa certa, em vez de construindo a coisa do jeito certo. O teste de
aceitação é a validação formalizada, com data, um conjunto de critérios combinado antes e uma
decisão no fim, tomada pelo cliente. O `qa-fundamentals` o colocou no topo do modelo V, de frente
para os requisitos; esta aula trata do que acontece ali na prática.

## Os tipos de aceitação

O **teste de aceitação do usuário**, o UAT (da sigla em inglês), é o que a maioria das pessoas quer
dizer. Os usuários, ou o cliente falando por eles, usam o produto nas suas tarefas reais e decidem
se ele dá conta do trabalho. No boxoffice, são a gerente e os dois atendentes que vendem no balcão.

O **teste de aceitação operacional** pergunta se quem opera o sistema consegue operá-lo: fazer
backup, restaurar, religar depois de uma queda de energia, perceber quando ele está com problema.
Ele acha outro tipo de problema. O boxoffice guarda tudo na memória, então reiniciar apaga todos
os pedidos. Isso é aceitável numa build de teste e um desastre para um teatro num sábado à noite, e
nenhum teste funcional de reserva vai dizer isso, porque todos começam reiniciando.

A aceitação **contratual** e a **regulatória** conferem o produto contra um contrato, ou contra uma
lei ou uma norma: o sistema de um banco contra as regras do Banco Central, um site contra uma lei
de acessibilidade. Cada uma tem a sua papelada, e o formato é o mesmo.

## Alfa e beta

Mais duas palavras vêm de empresas que vendem um produto para muitos clientes, onde não existe um
cliente único a quem perguntar.

O **teste alfa** é feito por pessoas de dentro da empresa que construiu o produto, mas de fora do
time que o construiu, geralmente no próprio ambiente dos desenvolvedores: gente de vendas ou de
suporte usando o produto como um cliente usaria. O **teste beta** entrega um produto quase pronto a
alguns usuários reais, no ambiente deles, antes do lançamento geral, e recolhe o que eles relatam.
Um beta chega às máquinas, às redes e aos hábitos que nenhum ambiente de teste tem.

O boxoffice é feito para um único cliente, e as palavras servem mesmo assim, com um pouco de
esforço. Um alfa seriam os dois atendentes usando a build de teste da 1.1 por uma manhã, com a Ana
ao lado. Um beta seria vender os ingressos de verdade de uma matinê de domingo de The Little
Prince pela 1.1, com o jeito antigo de vender pronto para o caso de ela falhar.

## Quem faz o quê

Os papéis são onde a maioria dos UATs dá errado, então vale dizê-los com todas as letras.

**O cliente decide.** Ele escolhe o que significa aceitável, conduz a sessão ou põe seus usuários
para conduzi-la, e diz sim ou não no fim. Um UAT em que os testadores rodam os casos e o cliente
assina o resultado é um teste de sistema com uma assinatura, e deixa passar justamente o que o UAT
existe para achar.

**O testador prepara e apoia.** A Ana monta o ambiente, transforma os critérios em casos que a
gerente consiga seguir, registra tudo o que acontece e converte o que vê em relatórios de defeito
e perguntas. Ela não convence a gerente a desistir de um achado, e não decide se a versão sai.

**O UAT começa quando o teste de sistema termina**, com os resultados conhecidos. Entregar ao cliente
uma build que ainda falha nos próprios testes de sistema desperdiça a única tarde que ele tem com
defeitos que o time acharia sozinho. A rodada de regressão da aula 10 faz parte disso: o defeito
do desconto de estudante já está relatado quando a gerente se senta, e ela vai topar com ele mesmo
assim, como a seção 04 desta aula acompanha.
