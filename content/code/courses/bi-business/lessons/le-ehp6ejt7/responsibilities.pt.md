---
title: Pelo que o analista responde
version: 1
---

Habilidades são o que um analista sabe fazer. Responsabilidades são o que a empresa pode esperar dele
quando ninguém está conferindo. **Os números de um analista de BI são lidos por pessoas que não têm
como verificá-los**, e isso faz de seis coisas trabalho do analista, mesmo que nenhum pedido jamais
as peça.

## Cuidar das definições

O analista guarda a definição escrita de todo número que publica: o que é contado, o que fica de
fora, em que período, de que fonte. O dono do número decide o que ele quer dizer, como disse a aula 3.
**O analista garante que essa decisão esteja escrita, seja fácil de achar e seja a mesma em todo
relatório que mostra o número.** Quando Lívia publicou o e-mail de vendas de segunda, a definição de
venda foi junto, num link no rodapé: pedidos pagos e cupons de caixa, contados no dia do pagamento,
com as devoluções descontadas na semana em que acontecem.

## Conferir antes de publicar

Todo número é conferido antes de sair, contra algo independente: o número da semana passada, a soma
das partes, o total do sistema financeiro. **A conferência que importa é a que pegaria um erro que você
sabe nomear**, não um ritual. A conferência de segunda de Lívia leva dez minutos: o total contra o
caixa diário do sistema financeiro, cada loja contra as suas quatro semanas anteriores, e a contagem
de lojas que mandaram arquivo. Na terceira semana, ela pegou uma loja cujo arquivo tinha chegado
vazio, e o e-mail saiu com uma linha dizendo que faltava o número de Betim, em vez de um total cerca
de R$ 170.000 menor, que é o que uma semana comum de Betim vende.

## Documentar

Não só as definições: de onde vêm os dados de cada relatório, o que foi suposto, o que ficou de fora e
por quê. **O teste é se outra pessoa conseguiria refazer o trabalho no ano que vem e chegar à mesma
resposta sem perguntar a você.** Em fevereiro parece burocracia. No próximo dezembro, quando o conselho
perguntar como foi calculada a taxa de recompra de 2025 e quem calculou estiver de férias, é a única
coisa que ajuda.

## Dizer "ainda não sabemos"

Às vezes os dados não conseguem responder à pergunta, ou não até o prazo, ou não com confiança
suficiente para agir. O analista diz isso, com clareza, junto com o que seria preciso para descobrir.
**Uma resposta confiante a uma pergunta que os dados não resolvem é pior que nenhuma resposta**, porque
alguém vai agir com base nela. A aula 2 listou os lugares onde os dados acabam; aqui está o hábito de
admitir isso em voz alta.

## Guardar o que é confidencial

Um analista de BI vê mais da empresa que quase qualquer pessoa: todo salário num relatório de
quadro de pessoal, o endereço e o histórico de compras de cada cliente, as vendas de uma loja antes do
próprio gerente. **O acesso aos dados é para o trabalho que justificou esse acesso**, não para
curiosidade, e um relatório mostra o que o leitor precisa e nada mais. Salários aparecem nos
relatórios de RH por faixa, não por nome; listas de clientes só saem do banco de dados quando há um
motivo e uma base para isso. Dados pessoais têm regras próprias, e as aulas 6 e 7 de `data-governance`
tratam delas.

## Não mudar um número para agradar

Mais cedo ou mais tarde alguém sênior vai não gostar de um número e pedir que ele seja "revisto".
Rever não tem problema: números às vezes estão errados, e uma segunda conferência custa pouco. **Mudar a
definição, o período ou a comparação até o número ficar melhor tem**, e destrói a única coisa que uma
área de BI tem a oferecer: que os números dela querem dizer a mesma coisa seja quem for que eles
incomodem. Quando Renata perguntou se os números dos links patrocinados podiam deixar de fora as duas
semanas em que a campanha ficou pausada, Lívia mostrou as duas versões, rotuladas, e disse qual delas
respondia à pergunta que tinham combinado. A técnica inteira é essa: nunca esconder uma versão, e
sempre dizer qual delas é a resposta.
