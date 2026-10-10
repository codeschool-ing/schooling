---
title: Uma divisão de capacidade, acordada antes das discussões
version: 1
---

Toda reunião de planejamento da Coreto trazia a mesma discussão. Um item de produto e um trabalho de
engenharia eram comparados, um contra o outro, e o trabalho de engenharia perdia. Não perdia porque
alguém era irracional. **Perdia porque a comparação era montada para ele perder**, e a correção é
parar de fazer essa comparação.

## Por que item a item sempre pende para um lado

Ponha uma funcionalidade e um item de dívida lado a lado e veja o que cada um traz para a reunião. A
funcionalidade tem um cliente, uma data que alguém prometeu e uma pessoa na sala que a quer. O item
de dívida tem um retorno espalhado por muitas sprints futuras, que não pertence a ninguém em
especial. Cada decisão isolada de adiá-lo parece sensata, e é.

A soma não é. A aula 5 precificou a dívida da reserva de assento como juros: cerca de 31 horas de
engenharia por sprint, pagas quer alguém decida ou não, e crescendo quando ninguém mexe nela. Um time
que adia a correção uma sprint de cada vez paga esses juros toda sprint, e nenhuma reunião vê o
total, porque nenhuma reunião olha para mais de uma sprint.

Há uma segunda resposta errada, e os times recorrem a ela quando percebem a primeira. **Os engenheiros
começam a esconder o investimento dentro das estimativas de funcionalidades.** Uma funcionalidade é
estimada com folga, e a folga vai para a refatoração que ninguém teria aprovado. Funciona por um
tempo. Depois o produto descobre que as estimativas têm gordura, passa a descontar todas, e perde o
único sinal que tinha sobre quanto as coisas levam. As estimativas honestas da engenharia são
cortadas junto com as infladas.

## Uma fatia acordada com antecedência

A alternativa é tomar a decisão uma vez, para um período, e parar de rediscuti-la. Produto,
engenharia e a CTO combinam que fatia da capacidade de cada time vai para investimento de
engenharia. **Dentro dessa fatia, a engenharia escolhe o trabalho.** Fora dela, o produto escolhe.

O acordo da Coreto, feito em janeiro entre Júlia Sato, Davi e Helena Prates, diz assim:

> **Divisão de capacidade do ano**
>
> Cada time de produto reserva um quinto de toda sprint para investimento de engenharia: pagamento
> de dívida, atualizações, adoção dos caminhos pavimentados da plataforma e o trabalho que a
> estratégia técnica pede daquele time. O tech lead escolhe o que entra e publica a lista no
> planejamento da sprint. O produto vê a lista e pode questioná-la, e não a aprova item a item.
>
> O time de Reservas fica fora desta divisão. Nos dois primeiros trimestres, toda a capacidade dele
> é investimento de engenharia, como diz a terceira ação da estratégia.
>
> Na temporada de aberturas de vendas, um time pode emprestar sua fatia ao trabalho de produto, uma
> sprint de cada vez. Toda sprint emprestada é devolvida no trimestre seguinte, e o tech lead
> registra as duas coisas nas notas da sprint.
>
> Revisamos a fatia a cada trimestre, contra o que ela comprou.

**Um quinto é escolha da Coreto, não lei.** Você vai ouvir frações fixas citadas como se fossem
regras do setor, e cada uma delas é a decisão de outra empresa para a dívida dela. A fatia certa
depende de quanto juro a sua dívida cobra. Um time cujo código lhe custa uma parte grande de toda
sprint em juros precisa de mais que um time numa base de código jovem, e a fatia deve cair conforme
os juros caem.

## O que entra, e o que não entra

Uma divisão precisa de fronteira, ou vira o lugar onde se arquiva tudo o que a engenharia quer
evitar discutir. A Coreto traçou a linha de propósito, e escreveu os casos que apareceram no
primeiro mês.

| trabalho | que lado | por que a Coreto o pôs ali |
|---|---|---|
| pagar uma dívida precificada, como a suíte de ponta a ponta instável | engenharia | é para isso que a fatia existe |
| levar um serviço para o template de deploy (aula 14) | engenharia | adoção da plataforma é investimento |
| um bug que uma casa reportou | produto | o produto decide a ordem dele contra outros trabalhos de cliente |
| tempo de descoberta de um engenheiro (a seção anterior) | produto | serve a uma ideia de produto |
| uma melhoria de plantão depois de um incidente | engenharia | reduz juros futuros |

A linha do bug foi a disputada. Os engenheiros argumentaram que bug é qualidade, e qualidade é com
eles. A Júlia argumentou que o bug de uma casa disputa com o pedido de funcionalidade de uma casa
pelo mesmo motivo, e quem conversa com as casas deve ordená-los. A Coreto ficou com a Júlia. **O que
importou foi decidir uma vez**, em janeiro, e parar de decidir de novo a cada sprint.

## Prestando contas da fatia

**Uma fatia que não compra nada visível vai ser tomada de volta no primeiro trimestre ruim.** Então, a
cada trimestre, os tech leads relatam o que ela comprou, em termos que importam ao produto: horas de
juros eliminadas, incidentes que não voltaram, uma etapa de release que não precisa mais de alguém
olhando. Os números de juros da aula 5 são a unidade natural. Quando a dívida da reserva de assento
for paga, as 31 horas por sprint que ela cobrava voltam para os times que mexiam nela, e esse é um
número com que a Júlia consegue planejar funcionalidades.

Esta aula não ensina a medir a capacidade de um time, nem por que um time planejado com capacidade
cheia entrega menos. Isso é a aula 12 de `delivery-metrics`, sobre capacidade e folga, e a divisão
aqui reparte a capacidade que aquela aula deixa para você. A divisão trata de quem decide; a folga
trata de quanto há para decidir.

Quando uma liderança de produto contesta a fatia no meio de um trimestre, o acordo é o que torna a
conversa curta. Sem ele, a contestação é mais uma comparação item a item, e a dívida perde de novo. A
aula 22 de `people-leadership` trata desse conflito para quando o acordo sozinho não o encerra.
