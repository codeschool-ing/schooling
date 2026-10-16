---
title: O que quer dizer tático
version: 1
---

**O BI tático serve às decisões que a empresa toma ao longo de semanas e meses, por gestores que
mexem em verba, gente e estoque.** A pergunta dele é "estamos no plano, e para onde movemos recursos no
mês que vem?", e a tela dele põe cada número ao lado do número contra o qual é julgado. A aula 14 foi a
pessoa no chão decidindo em minutos; esta aula é o gestor decidindo numa reunião, com dias para pensar
e um mês de dados sobre o que pensar.

## As decisões, e quem as toma

Na Varanda, as decisões táticas pertencem aos diretores e às suas equipes, e cada área faz uma reunião
no começo do mês:

| quem | o que movimenta | a pergunta da reunião |
|---|---|---|
| Renata Sá, marketing | gasto em mídia entre canais; as campanhas do mês seguinte | que canais compraram pedidos ao custo planejado? |
| Caio Barreto, operações | escalas de pessoal por loja; estoque entre lojas e o CD | onde faltou, e onde sobrou? |
| Otávio Lins, finanças | custos contra o orçamento; caixa das próximas semanas | que linhas saíram do orçamento, e é questão de prazo ou é real? |
| Sônia Freitas, pessoas | contratações; horas extras; férias | onde falta gente para a demanda do mês que vem? |

Essas decisões são menos numerosas e maiores que as do Marcos. Passar R$ 15 mil de mídia de um canal
para outro é reversível, mas só um mês depois, e ninguém quer descobrir em quatro semanas que foi um
erro. **Por isso uma tela tática é lida numa reunião, não de relance**: quem está na mesa tem tempo de
perguntar por quê, e a tela precisa ter a resposta pronta.

## A imagem errada: o total do mês é a resposta

Uma tela tática que mostra "vendas online em novembro: R$ 2.060 mil" não disse nada. Isso é bom?
Depende do que se esperava. **Todo número tático precisa de duas comparações, e cada uma pega o que a
outra deixa passar.**

- **Contra o orçamento ou a meta**, que é o que a empresa planejou. As vendas online de novembro
  ficaram 8,4% acima dos R$ 1.900 mil do orçamento. Isso diz se o plano se cumpriu, e vale o quanto o
  plano vale.
- **Contra o mesmo mês do ano anterior**, que traz a sazonalidade. Novembro de 2025 ficou 24,1% acima
  de novembro de 2024. Isso diz como o negócio andou, e só é justo se os dois meses forem parecidos.

Neste novembro não eram. A aula 7 descobriu que a campanha anual da loja online rodou no fim de outubro
em 2024 e no começo de novembro em 2025, então novembro de 2025 carrega uma campanha que novembro de
2024 não tinha. Juntos, outubro e novembro cresceram 3,6%. **Uma comparação com o ano anterior tem de
ser lida com o calendário ao lado**, e a tela da reunião, na próxima seção, diz isso numa nota de
rodapé.

Uma terceira comparação é o mês anterior. Para um varejista, é a menos útil das três, porque dezembro
sempre ganha de novembro e ninguém aprende nada com isso. A aula 6 fez o mesmo argumento com o
crescimento mês contra mês e ano contra ano.

## O mês fechado

Dado operacional tem minutos de idade. Dado tático espera o mês fechar. Devoluções chegam depois da
venda, um pedido é cancelado uma semana depois, a nota de um fornecedor referente a novembro chega em 3
de dezembro. Otávio fecha os livros da Varanda no quinto dia útil do mês seguinte, e **a reunião mensal
usa os números fechados, os mesmos que finanças reporta**.

Essa é uma decisão sobre definições tanto quanto sobre prazo. Em 1º de dezembro, a contagem de vendas
online de novembro do marketing incluía pedidos cancelados antes da entrega; a de finanças, não. Se a
Renata revisasse o mês pela contagem dela, o novembro dela seria maior que o da contabilidade da
empresa, e a reunião gastaria os primeiros vinte minutos discutindo por quê. Os dois diretores com dois
totais da aula 1 são o mesmo problema na escala do mês, e a aula 2 de `analytics-bi` trata de manter
uma definição só entre áreas.

## Dentro do mês

Um mês é muito tempo para esperar por uma má notícia. Por isso o BI tático muitas vezes acrescenta uma
verificação semanal: o mês até agora contra a parte da meta que já deveria ter sido alcançada. **O
problema é que a meta não chega por igual.** Na Varanda, a campanha de novembro rodou do dia 3 ao dia
13, então uma boa parte dos pedidos online do mês ia mesmo chegar na primeira metade. Uma verificação
que comparasse o dia 15 com metade da meta anunciaria um triunfo na segunda semana e um colapso na
quarta, sem que nada mudasse entre uma e outra. A parte da meta esperada até certo dia tem de seguir a
forma do mês, o que costuma querer dizer o padrão diário do ano anterior com os dias de campanha
movidos para onde caem neste ano.
