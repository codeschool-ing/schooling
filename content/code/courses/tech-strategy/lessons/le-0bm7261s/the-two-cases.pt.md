---
title: Os dois casos em que vale a pena
version: 1
---

"Nunca reescreva nada" é a lição que as pessoas tiram de Spolsky, e ela é forte demais. As quatro
falhas da seção anterior têm cada uma uma condição: elas mordem quando o sistema é grande, quando o
antigo continua mudando por baixo e quando a troca é um único momento que não dá para desfazer.
**Tire as condições e uma reescrita vira um trabalho comum.** Duas situações tiram.

## Caso um: pequena o bastante para um trimestre, atrás de uma chave que volta

Se a reescrita inteira cabe num trimestre, a maior parte do perigo vai embora junto com o tamanho. O
sistema antigo muda pouco em três meses, então o alvo quase não se move. O escopo é pequeno o
bastante para estimar, e pequeno o bastante para perceber quando começa a crescer. E se a virada é
reversível — o caminho antigo continua rodando atrás de uma chave que manda o tráfego de volta para
ele em minutos —, um erro custa uma manhã, e não uma abertura de vendas.

O gerador de ingressos em PDF da Coreto é o exemplo. A aula 5 o precificou em 120 horas de principal
e 6 horas de juros por sprint, e o deixou para quando um time já estivesse trabalhando naquele
código. Quando isso acontecer, reescrevê-lo inteiro é uma forma razoável de pagar. É um componente
com uma função, transformar um pedido confirmado num arquivo de ingresso, e a saída dele é fácil de
conferir: gere o mesmo pedido com os dois geradores e compare os arquivos. A reescrita cabe com folga
num trimestre para um time, e uma configuração pode mandar a geração de ingressos de volta para o
código antigo se os ingressos de uma casa saírem errados.

**As duas metades da condição importam.** Pequena sem ser reversível é uma virada de uma vez só em
escala menor, e ainda uma manhã ruim quando dá errado. Reversível sem ser pequena é uma reescrita
longa com uma saída de emergência: ela continua perseguindo um alvo móvel por dezoito meses, e a
saída só ajuda no último dia.

## Caso dois: o chão está indo embora

Às vezes a base sob um sistema está acabando e não dá para movê-la peça por peça. Um runtime chega ao
fim do suporte — o Python 2 chegou, em 2020 — e a linguagem em que o código está escrito para de
receber correções de segurança. Um fornecedor fecha a plataforma em que um componente roda. Em cada
caso, não fazer nada deixou de ser uma das opções; a escolha é entre jeitos de mudar.

**Mesmo assim, procure primeiro o caminho incremental.** A maioria das atualizações dá para fazer um
módulo de cada vez, e a aula 7 é o método para mover um sistema enquanto ele continua atendendo
tráfego. **Uma reescrita se justifica quando esse caminho não existe**: quando a base antiga e a nova
não conseguem rodar lado a lado, e então não há nada para mover uma peça de cada vez.

A Coreto tem um candidato plausível. Suponha que os mantenedores da versão de banco de dados sob a
réplica antiga de relatórios anunciem o fim das atualizações de segurança. A réplica é a dívida que a
aula 5 mandou o time deixar quieta, com um retorno de 50 sprints. Quando o banco dela está acabando, o
retorno deixa de ser a pergunta, porque o trabalho é forçado. Uma pequena reconstrução da rotina de
relatórios num banco com suporte, com a réplica antiga rodando até a nova dar os mesmos relatórios, é
o caminho mais barato. Esse é o "algo fora da planilha" que a aula 5 mencionou.

## Passando as propostas pelos dois casos

| pergunta | a reescrita das reservas | gerador de PDF | réplica de relatórios, se o banco dela perder o suporte |
|---|---|---|---|
| cabe num trimestre? | não — dezoito meses pela própria estimativa | sim | sim, a rotina de relatórios é pequena |
| virada reversível? | não — uma chave para a plataforma inteira | sim — uma configuração manda os ingressos de volta | sim — a réplica antiga roda até a nova bater |
| a base está indo embora? | não — nada embaixo dele está acabando | não | sim |
| veredito | não reescrever | uma reescrita é uma forma razoável | a reescrita é forçada |

A reescrita do Mateus não se encaixa em nenhum dos casos. O módulo tem nove anos, todos os times
trabalham nele, a proposta precisa de um ano e meio, e nada embaixo dele está acabando. O que o módulo
tem é um caminho que dói — as reservas de assento —, e **um caminho pode ser movido sem reescrever
tudo o que está ligado a ele**. A aula 7 faz exatamente isso com ele.

## Duas perguntas para qualquer reescrita

Faça-as nesta ordem. A reescrita pode ser terminada dentro de um trimestre e desfeita numa tarde? Se
não, o chão sob o sistema antigo está sumindo, sem jeito de movê-lo peça por peça? Um sim à primeira
faz da reescrita um projeto pequeno com rede de proteção. Um sim à segunda faz dela a menos ruim das
opções forçadas. Um não às duas quer dizer que a proposta é do tipo contra o qual Spolsky alertou,
diga o que disserem os slides, e a próxima seção põe preço numa delas.
