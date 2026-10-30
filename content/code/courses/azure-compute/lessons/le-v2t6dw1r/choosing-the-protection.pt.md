---
title: Escolhendo a proteção, e o que nenhuma delas cobre
version: 1
---

A conclusão fácil das três últimas seções é que zonas são melhores, então tudo deveria usá-las, e
que uma máquina espalhada por zonas é uma máquina que fica de pé. A primeira metade é o padrão certo
e a regra errada. A segunda metade é falsa. **Cada arranjo compra a sobrevivência a um tamanho de
falha, e nenhum sobrevive a uma falha que toda cópia divide.** Escolher é questão de dar nome à
falha, e depois ler a tabela.

## Ao que cada um sobrevive

| quando isto falha | uma máquina | conjunto de disponibilidade | em várias zonas |
|---|---|---|---|
| um host | cai | sobrevive | sobrevive |
| a energia ou o switch de um rack | cai | sobrevive | sobrevive |
| uma reinicialização de manutenção | cai durante a reinicialização | sobrevive, um domínio de atualização por vez | sobrevive |
| um datacenter | cai | **cai**, se os racks do conjunto estiverem nele | sobrevive |
| a região | cai | cai | cai |
| uma versão ruim, implantada em tudo | cai | cai | cai |
| um bug no próprio código da loja | cai | cai | cai |

Duas linhas merecem uma frase cada. A visão geral da Microsoft sobre conjuntos de disponibilidade
diz com todas as letras que eles continuam expostos a falhas de infraestrutura compartilhada, como
uma queda de rede num datacenter inteiro, que pode alcançar vários domínios de falha de uma vez. E
para a linha da manutenção em várias zonas, a página sobre manutenção diz que as atualizações que não
precisam de reinicialização são sequenciadas em geral zona por zona, com alguma sobreposição no
final: as zonas não são tocadas no mesmo instante, o que é diferente de nunca serem tocadas.

## O padrão, e as suas duas exceções

**Numa região com zonas, espalhe por zonas.** O próprio conselho da Microsoft, lido em 2026-10-30,
é usar um scale set Flexible para disponibilidade, e espalhá-lo por zonas na maioria das cargas. Foi
o que a lição 4 fez para a API de pedidos da loja, três instâncias em três zonas de Brazil South. Ele
ganha os 99,99% da última seção, e é o único arranjo desta lição que mantém a loja de pé quando um
prédio apaga.

O preço não é uma linha na fatura pelas zonas em si. São três coisas que você paga de qualquer
jeito. Pelo menos duas máquinas onde uma bastaria, o que todo arranjo aqui custa. Um pouco
de latência entre máquinas em zonas diferentes, menos de dois milissegundos de ida e volta, mas mais
do que entre dois racks num prédio. E capacidade: um tamanho nem sempre é oferecido em toda zona, que
é o que o `az vm list-skus` da lição 1 mostra por zona numa assinatura real.

As duas exceções:

- Um conjunto de disponibilidade, onde não há zonas ou onde a latência entre máquinas importa mais
  do que sobreviver a um datacenter. A visão geral diz que conjuntos são especialmente úteis em
  regiões sem zonas, e que as suas máquinas ficam mais perto umas das outras do que zonas permitem.
  Um par de máquinas replicando um banco de dados de forma síncrona é o tipo de trabalho que cabe
  ali. Um conjunto não pode também receber zonas, como o compilador deixou de notar duas seções
  atrás. E um scale set Flexible regional também se espalha por domínios de falha, e é por isso que
  a mesma visão geral recomenda primeiro o scale set.
- Uma máquina só, para trabalho que pode esperar. O relatório noturno de vendas da loja roda uma
  vez, à noite, e ninguém o lê antes da manhã. Se o host dele falha às duas e a máquina volta às duas
  e meia, o relatório atrasa e nada mais acontece. Uma máquina em Premium SSD tem a promessa de
  99,9%, quarenta e três minutos em trinta dias, e um relatório que tolera uma noite atrasada não
  precisa de mais.

Um **grupo de posicionamento por proximidade** pertence à primeira exceção, no seu extremo: máquinas
que precisam da menor latência entre si, ao preço de ficar num só datacenter. É a ferramenta certa
para uma camada que conversa com outra muitas vezes a cada pedido, e a errada para qualquer coisa
cuja razão de existir é sobreviver a esse datacenter.

## Contra o que nenhum deles protege

**Uma região.** Todo arranjo desta lição está dentro de uma, e uma região inalcançável leva todos
eles junto. Sobreviver a isso quer dizer uma cópia numa segunda região, e a lição 1 de
`azure-foundations` diz com qual região cada uma forma par. Um detalhe dos pares importa para esta
loja: a página da Microsoft sobre regiões diz que um par mantém os dados dentro da mesma geografia,
**exceto Brazil South**, então uma cópia guardada no par de Brazil South sai do Brasil. A lição 2
guardou uma réplica da imagem da loja em South Central US, para que as máquinas pudessem ser
recriadas ali. A imagem é a parte fácil, e os pedidos são a difícil.

**Uma versão ruim.** As máquinas em três zonas rodam a mesma imagem, e uma implantação que a quebra a
quebra em três zonas. O que limita isso é quantas máquinas uma mudança alcança de uma vez, que é o
rolling upgrade da lição 4 com o seu health check: um lote de instâncias por vez, parado quando
muitas delas falham.

**Um bug, ou um engano.** As cópias rodam o mesmo código, então uma queda num pedido em particular
derruba toda cópia que receber um deles. Um grupo de recursos excluído exclui as máquinas de todas
as zonas num só comando. Nenhum dos dois é falha do hardware da Microsoft, e o contrato diz isso:
ele exclui o que resulta de entrada defeituosa, e as operações que você mesmo inicia.

**Dados que moram numa máquina.** O disco de uma máquina está na zona da máquina. Um disco com
redundância de zona, o tipo `ZRS` da lição 3, guarda três cópias em três zonas e continua alcançável
quando uma zona não está, e é assim que os dados de uma máquina sozinha sobrevivem à perda da sua
zona. Ele não protege contra a versão que escreveu a coisa errada nele, que é trabalho de um backup.

## A loja, decidida

Juntando tudo, a loja termina com duas respostas e uma lista. A API de pedidos é o scale set da
lição 4 em três zonas, atrás de um load balancer Standard e de um endereço com redundância de zona,
porque um almoço perdido para um prédio é a falha que custa dinheiro. O relatório noturno é uma
máquina em Premium SSD, porque pode esperar. E o que nenhum dos dois arranjos cobre, uma região, uma
versão e o próprio código da loja, fica escrito como as próximas coisas a resolver, em vez de ser
tomado como coberto por uma porcentagem que nunca disse cobri-lo.
