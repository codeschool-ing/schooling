---
title: Quando não desenhar
version: 1
---

**Um diagrama custa desenho, leitura e, acima de tudo, manutenção da verdade, então precisa carregar
algo que uma frase não carrega.** Muitos desenhos em documentos de arquitetura repetem o parágrafo
ao lado, e um desenho que repete a própria legenda é pior que nenhum: custa a mesma manutenção e não
ensina nada.

## O que um desenho carrega e uma frase não

A regra que esta plataforma usa nas próprias aulas também serve para documentos de arquitetura. **Um
diagrama merece o lugar quando carrega uma de quatro coisas:**

| | o quê | um exemplo da Carcará |
| --- | --- | --- |
| **uma sequência no tempo** | passos em que um posterior depende de um anterior ter voltado | o pedido do passageiro, a reserva do assento, a cobrança, a confirmação, nessa ordem |
| **um aninhamento ou uma fronteira** | o que está dentro do quê, e o que atravessa a linha | quais serviços rodam na conta de nuvem da Carcará e quais pertencem à empresa de pagamento |
| **uma contagem** | muitas coisas ao mesmo tempo, que a prosa só consegue afirmar | os celulares de 300 ônibus sincronizando a lista de passagens às 05:00 |
| **dois eixos ao mesmo tempo** | quando a própria forma é o argumento | venda de passagens por hora na semana de São João |

Se o que você quer dizer não é nenhuma dessas, uma frase ou uma tabela provavelmente dizem melhor.
*A API de passagens grava no banco de reservas* é uma frase; desenhada, são duas caixas e uma seta
que o leitor decodifica de volta na mesma frase.

## Diagramas que não deveriam existir

- **O diagrama que duplica o código.** Um diagrama de classes com todas as classes de um serviço fica
  desatualizado no próximo pull request, e o código diz melhor. Se a estrutura importa, gere a partir
  do código, como mostra a aula 12, ou desenhe só as cinco classes de que o leitor precisa.
- **O diagrama que ninguém vai atualizar.** Sem dono, ele estará errado em poucos meses, e um
  diagrama errado faz mais mal que um ausente, porque as pessoas confiam num desenho. A aula 11 trata
  de dono e de apagar.
- **O diagrama pelo documento.** Um modelo de documento pede um diagrama de arquitetura, então se
  desenha um. Se a pergunta que o modelo espera que ele responda não é a pergunta do seu leitor,
  escreva isso em vez de desenhar.

## Um esboço não é um documento

Nada disso vale para um esboço. Desenhar num quadro branco ou numa folha de papel enquanto pensa, ou
enquanto conversa com um colega, é uma das coisas mais úteis que um arquiteto faz, **e o esboço é
feito para ser jogado fora**. As regras desta aula são para o diagrama que você entrega a alguém que
não estava lá. Uma foto de quadro branco colada num documento não é esse diagrama; é um esboço que
alguém esqueceu de redesenhar, e ela carrega todas as convenções privadas de quem estava na sala.

**Desenhe você também.** Pegue um documento de arquitetura a que você tenha acesso e olhe cada
diagrama dele. Para cada um, decida qual das quatro coisas ele carrega. Se não carrega nenhuma,
escreva a frase que o substituiria, e veja se algo se perdeu.
