---
title: Os dados que não valem a pena coletar
version: 1
---

**Todo dado que um app coleta é algo que ele depois precisa declarar, proteger, guardar e apagar quando
pedirem, então o dado mais barato de ter é o que nunca foi coletado.** O hábito com que a maioria das
equipes começa vai no sentido contrário: coletar o que pode ser útil, e decidir depois para que serve.
Num celular esse hábito sai caro duas vezes. Os formulários das lojas tornam a coleta pública, e a
pessoa que lê o rótulo na página do produto decide se instala com base nele.

## Do que o planner não precisa

**O planner não precisa de conta, de localização, de contatos, nem de um identificador do aparelho.**
Percorra a lista do que um app típico coleta e pergunte, para cada item, o que a aluna perderia sem ele.

| dado | o que compraria para o planner | o que a aluna perde sem ele |
|---|---|---|
| uma conta com endereço de e-mail | um plano em dois celulares | nada hoje: o plano está no celular, e a aula 16 o mantém lá |
| localização | nada; uma sessão de estudo não tem lugar | nada |
| contatos | convidar uma amiga para estudar | uma folha de compartilhamento, que o sistema oferece sem a permissão |
| um identificador do aparelho para analytics | contar quantas pessoas abrem cada tela | nada que ela veja |
| logs de crash enviados a um terceiro | achar crashes mais cedo | nada que ela veja, até um crash ficar sem correção |

**Só a última linha é uma troca de verdade, e ela tem uma resposta mais barata.** Os consoles das duas
lojas mostram relatórios de crash e dados de desempenho que o próprio sistema reúne, sem nenhum SDK no
app. A aula 12 de `mobile-delivery` trata de bibliotecas de relatório de crashes, e a aula 15 dele do
que é medido em campo. Partir dos relatórios do próprio sistema mantém o formulário do planner vazio
enquanto eles bastarem.

**"Não vale a pena coletar" é um julgamento sobre a pessoa, não sobre armazenamento.** Um identificador
de aparelho custa poucos bytes. O que ele custa à aluna é que toda tela que ela abre vira um registro
preso ao celular dela, nas mãos de alguém que ela não escolheu, sob uma política que ela não leu. A
página da Apple sobre privacy details cita dados dos quais os identificadores foram retirados como
exemplo de dados *não* ligados ao usuário; tirar o que liga um dado a uma pessoa é algo que um app
consegue fazer antes da coleta, e não consegue desfazer depois.

## Analytics que não é vigilância

**Medir como um app é usado não é o problema; medir quem o está usando, tela por tela, é.** Existe uma
versão de analytics que responde às perguntas que uma equipe de fato tem, como quais telas são usadas e
onde as pessoas desistem, a partir de contagens que não identificam ninguém: sem identificador do
aparelho, sem conta, nada que permita remontar as sessões de uma pessoa. A aula 16 de `mobile-delivery`
trata de construir exatamente isso, eventos e funis com uma medição que não é vigilância, e ela parte do
inventário que esta aula escreveu.

**As etiquetas de um link são a mesma pergunta em miniatura.** O parser da aula 11 ignorou o
`?from=email` de um link para a semana. Uma etiqueta assim diz de onde a pessoa veio, o que a torna útil
para uma equipe de marketing e também a torna um dado sobre a pessoa. O planner não a lê para nada e não
a envia a lugar nenhum, então ela não aparece no inventário, e os formulários das lojas nunca perguntam
sobre ela. Se o planner um dia começasse a contar de onde vêm as instalações, pelo referrer dos links
adiados da aula 11, isso seria uma linha nova no inventário, com um `why` que alguém precisa estar
disposto a escrever.

## A ordem das perguntas

**Pergunte se deve coletar antes de perguntar como declarar.** O inventário da seção anterior torna a
ordem mecânica: uma entrada não existe sem motivo, e o motivo precisa sobreviver a ser lido pela pessoa
de quem ele trata. Quando o motivo é "pode ser útil", a entrada não entra, e o formulário fica com uma
linha a menos. Quando o motivo é real, a entrada diz para onde o dado vai, e as respostas do formulário
saem dela.

A figura desta aula tinha três caixas, e o planner guarda tudo na primeira. Esse é o formato que vale a
pena buscar em qualquer app: dados na caixa da esquerda por padrão, e todo movimento para a direita uma
decisão que alguém escreveu.
