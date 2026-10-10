---
title: Quando não usar
version: 1
---

**A maior parte de um sistema típico não precisa de CQRS, e aplicá-lo em tudo é um dos jeitos mais
comuns de deixar cara uma aplicação simples.** Os próprios defensores dizem isso: Greg Young e Martin
Fowler o descrevem como um padrão para partes específicas de um sistema, as áreas delimitadas onde
leituras e escritas de fato se separam, e advertem contra ele como arquitetura do todo. O custo é
fácil de ver nos próprios arquivos desta lição.

```
ana@laptop:~/patterns/cqrs$ wc -l strained.py commands.py read_model.py
  64 strained.py
 110 commands.py
  73 read_model.py
 247 total
```

A classe tensionada fazia o mesmo trabalho em 64 linhas. A versão dividida usa 183 para o modelo de
escrita e dois de leitura, antes de qualquer maquinaria de fila da seção anterior. Parte da diferença
é o código de demonstração no fim de cada arquivo, e a maior parte é real: seis classes de evento e
de comando, uma tabela de despacho, dois projetores e o esquema de uma tabela. Cada uma dessas coisas
é algo que um leitor precisa achar, e toda tela nova agora pede uma revisão de eventos além de uma
consulta.

## Os custos, com nome

**Mais código e mais conceitos.** Uma tela que mostrava um campo direto do modelo agora precisa do
campo num evento, de um projetor que o copie e de uma coluna num modelo de leitura. Três lugares para
mudar por causa de um rótulo.

**Consistência eventual, se a projeção for assíncrona.** A janela da seção anterior precisa ser
projetada em toda tela que vem depois de uma ação, e explicada a pessoas que não a escolheram.

**Dois modelos para manter em sintonia.** Um bug num projetor produz um modelo de leitura que discorda
do modelo de escrita, em silêncio. Reconstruir resolve, desde que alguém perceba e a reconstrução seja
rápida o bastante para rodar; com alguns milhões de eventos, isso é uma operação com runbook.

**Integração mais difícil.** Uma pessoa nova procurando "onde um empréstimo é salvo" encontra um
handler, uma classe de evento e dois projetores, e precisa aprender o fluxo antes de mudar qualquer
coisa.

## Os casos que não precisam

**Uma tela que edita um registro e mostra o mesmo registro.** A página de perfil de um membro lê os
campos que escreve. O modelo de escrita e o de leitura teriam a mesma forma, então a divisão dobra o
código e não compra nada. A maioria das telas administrativas, a parte CRUD de qualquer sistema, é
esse caso.

**Regras triviais.** Se a única regra é "o título não pode ser vazio", não há nada para um modelo de
escrita pequeno proteger, e a classe tensionada não está tensionada.

**Leituras que já são baratas o bastante.** Se a consulta de disponibilidade leva dois milissegundos
com os dados reais, a tensão da primeira seção é um mau cheiro de projeto e ainda não um problema. Um
índice ou uma view no banco, o nível 1 dos três níveis, pode ser tudo de que ela vai precisar.

## Os casos que precisam

Os sinais são os que a primeira seção listou, medidos e não imaginados. Consultas percorrem
estruturas feitas para escrita e ficam mais lentas com os dados. Telas forçam campos para dentro do
modelo das regras. O tráfego de leitura é muitas vezes o de escrita e escalaria separado. Ou várias
telas precisam dos mesmos fatos em formas diferentes, como `Availability` e `MemberLoans`. Quando
isso aparece numa parte do sistema, divida essa parte. O balcão de empréstimos talvez se qualifique,
e a página de perfil do membro ao lado continuaria não se qualificando.

A lição 13 de `architecture` faz o mesmo argumento do lado do sistema, onde os custos se contam em
serviços, brokers de mensagens e horas de plantão; leia-a com o código desta lição em mente. E a
próxima lição leva os eventos desta um passo adiante: se o modelo de escrita já publica toda mudança
como evento, ele pode guardar os próprios eventos como seu estado.
