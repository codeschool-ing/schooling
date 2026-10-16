---
title: Deixar o grupo de fora não tira o viés
version: 1
---

**A região nunca foi uma das entradas do modelo.** As seis que ele usou foram recência, pedidos em 90
dias, tempo de casa, duas colunas de canal e o plano. E mesmo assim ele trata o Norte diferente, porque
a recência e a contagem de pedidos carregam a região dentro delas: um ritmo lento é, no dado da Panela,
quase uma assinatura do Norte.

Uma entrada que carrega a identidade de um grupo sem nomeá-la é um **proxy**. Proxies estão em toda
parte, e são o motivo de a primeira reação mais comum ao viés, tirar a coluna sensível, raramente
funcionar. Alguns conhecidos:

- **o CEP** carrega renda, e em muitas cidades raça;
- **o primeiro nome** carrega gênero, e muitas vezes idade;
- **o aparelho** que um cliente usa carrega renda;
- **a hora do dia** em que uma pessoa compra carrega o tipo de trabalho que ela tem.

Um modelo à procura de padrões vai achar o grupo pelos proxies sempre que os resultados do grupo forem
diferentes, e vai fazer isso em silêncio, sem nenhuma coluna para onde alguém possa apontar.

Deixar o grupo de fora tem um segundo custo, e é o menos óbvio. **Um analista que tira a região do dado
não consegue rodar a auditoria da etapa anterior.** A coluna que não pode decidir nada é a mesma coluna
necessária para checar que nada é decidido por ela. A prática usual é mantê-la ao lado do modelo, fora
das entradas dele e em toda avaliação.

Se uma coluna de grupo pode ser entrada é outra pergunta, com respostas legais que variam por país e
por tipo de decisão. No Brasil a LGPD trata como sensíveis os dados que revelam origem racial ou
étnica, religião, saúde e alguns outros, com regras mais estritas para usá-los. Região não está nessa
lista, mas o raciocínio vale igual: uma decisão que trata pessoas diferente por causa de onde moram
precisa de um motivo que alguém esteja disposto a defender.
