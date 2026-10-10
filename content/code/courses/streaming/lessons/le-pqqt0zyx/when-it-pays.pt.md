---
title: Quando um stream vale a pena, e quando não
version: 1
---

**Um stream vale o que custa quando alguém age sobre a resposta dentro do tempo que o batch levaria
para produzi-la.** Não quando a resposta é só mais agradável fresquinha: um painel que a gerente
abre na segunda de manhã fica igualmente bom alimentado por um job noturno, e custa uma fração do
esforço.

Quatro tipos de pergunta passam nesse teste:

- **Algo precisa ser impedido enquanto acontece.** Um cartão usado no Recife e em Lisboa com dez
  minutos de diferença; um login vindo de mil endereços numa hora. Uma checagem de fraude que
  responde amanhã responde depois que o dinheiro foi embora.
- **Uma promessa depende do estado atual.** O estoque no site, o assento no ônibus, a vaga na van
  de entrega. Vender o último exemplar duas vezes é o sábado no Recife de duas seções atrás.
- **Uma máquina reage a outra máquina.** Um preço que acompanha a demanda, uma recomendação que
  acompanha o último clique, um sensor que para uma linha de produção. Ninguém está lendo isso; um
  programa está, e ele lê em milissegundos.
- **Muitos sistemas precisam saber da mesma coisa.** Uma venda precisa chegar ao estoque, aos pontos
  de fidelidade, ao warehouse e ao contador. Escrevê-la uma vez num log que os quatro leem é
  muitas vezes o principal motivo de uma empresa adotar o Kafka, mesmo quando nenhum dos quatro tem
  pressa.

Vale parar na última, porque ela não é sobre velocidade. A lição 2 chama isso de log como ponto de
integração, e explica por que tantas empresas rodam Kafka para dados que de qualquer forma são
processados em batches de hora em hora.

## Quando não vale

| o pedido | por que um batch atende |
|---|---|
| um relatório diário ou semanal | o período fecha; um número completo e conferível vale mais que um recente |
| treinar um modelo com os dados do ano passado | a entrada é finita e fixa |
| um número conferido por um auditor | o auditor quer reproduzir a partir de um arquivo, não de um instante |
| "seria legal ver ao vivo" | ninguém age sobre a diferença |

O lado do custo é assunto da lição 17, mas a forma dele cabe aqui: um processador de stream é um
programa que roda **o tempo todo**, então custa dinheiro e atenção o tempo todo, inclusive nas
horas em que nada é vendido. Um batch que roda vinte minutos custa vinte minutos.

## A maioria das plataformas faz os dois

A resposta de costume não é um ou outro. Os eventos vão para um log quando acontecem; os processos
que precisam deles agora os leem agora; e um job batch lê o mesmo log à noite para montar a versão
completa e conferida. **O stream é a fonte e o batch é um dos seus leitores.** É para esse arranjo
que este curso caminha na Ponto Final: os caixas escrevendo no Kafka, processadores lendo as vendas
enquanto acontecem, e o warehouse ainda carregado uma vez por noite, a partir dos mesmos eventos.
