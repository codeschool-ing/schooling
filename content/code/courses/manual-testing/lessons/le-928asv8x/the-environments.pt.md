---
title: Desenvolvimento, teste, homologação e produção
version: 1
---

A imagem comum de um ambiente de teste é um servidor: a máquina em que a aplicação roda enquanto
alguém a testa. **Ambiente é tudo aquilo em que a aplicação roda e com que ela conversa**, e a
máquina é só o primeiro item. A versão do Python, o sistema operacional e suas configurações, o
relógio e o fuso horário, os dados em memória, o servidor de e-mail, as variáveis com que o programa
foi iniciado e o navegador do outro lado fazem parte dele. Mude qualquer uma dessas coisas e você
está testando em outro ambiente, tenha alguém dado um nome novo a ele ou não.

O plano da aula 1 já tinha uma linha para isso. A pergunta "quem, e com o quê?" citava as máquinas,
os navegadores, os dados e as contas, e listava a caixa de saída como o que faz o papel do servidor
de e-mail. Esta aula trata de por que essa linha importa.

## Os quatro, e para que serve cada um

A maioria dos times mantém quatro ambientes, e os nomes são quase universais mesmo quando as
máquinas por trás deles não são:

| ambiente | quem usa | a versão | os dados | e-mail |
|---|---|---|---|---|
| **desenvolvimento** | um desenvolvedor, no próprio computador | o que ele está escrevendo, minuto a minuto | o que ele digitou | quase nunca é enviado |
| **teste** | os testadores | uma versão conhecida, instalada de propósito | dados de teste preparados, zerados quando se quer | capturado, nunca entregue |
| **homologação** (staging) | testadores e o cliente, antes de uma versão sair | a candidata a versão | com a forma da produção, anonimizados | capturado, ou enviado a poucas caixas internas |
| **produção** | os clientes de verdade | a versão lançada | reais | entregue a pessoas reais |

**Desenvolvimento** muda depressa demais para se testar ali: quando um defeito é escrito, o código
que ele descreve já mudou. **Teste** é o ambiente que este curso vem usando desde o começo. Sua cópia
do boxoffice é uma versão conhecida, o `/health` diz qual, reiniciar zera tudo e a caixa de saída
impede que qualquer e-mail saia da máquina. **Homologação** existe por um motivo só: ser tão parecida
com a produção quanto algo pode ser sem ser a produção. Mesmo sistema operacional, mesma
configuração, mesma versão de tudo, dados com a mesma forma e as mesmas configurações na máquina. Um
teste que passa em homologação vale exatamente na medida em que a homologação se parece com a
produção.

**Produção não é ambiente de teste**, com uma exceção. Depois de uma versão, um testador
roda ali uma verificação de fumaça curta (aula 8), com uma conta mantida para isso, porque algumas
coisas não existem em nenhum outro lugar: o servidor de e-mail real, o domínio real, a maquininha de
cartão real. O plano da aula 1 deixou "o servidor de e-mail real" fora do escopo exatamente por isso,
para ser conferido uma vez em produção, por uma pessoa. Todo o resto é testado antes, porque um
defeito achado em produção já chegou a um cliente.

## Por que quatro e não um

Cada passo da fila tira uma diferença em relação à produção. É esse o motivo de ter mais de um, e é
isso que explica as falhas que aparecem quando um time pula um passo.

Um defeito que depende de uma diferença só aparece nos ambientes que têm essa diferença. As mais
comuns são sem graça: outra versão da linguagem, uma configuração que ninguém copiou, um fuso
horário, uma localidade que escreve `1.234,50` onde outra escreve `1,234.50`, uma conta que existe
num banco de dados e não em outro. **Nenhuma delas aparece no código**, porque o código é o mesmo
arquivo em todos os ambientes. O boxoffice mostra quanto depende das variáveis com que um programa
começa: `BOXOFFICE_PORT` o leva para outra porta, `BOXOFFICE_NOW` mexe no relógio dele e
`BOXOFFICE_SEED` muda todo link de confirmação que ele envia. Um arquivo, três configurações, e cada
uma faz parte do ambiente.

## Os ambientes do teatro

No boxoffice o arranjo é pequeno o bastante para caber na cabeça. Rui escreve o código no notebook
dele, que é o desenvolvimento. Você roda cada versão no seu, que é o teste. O teatro roda a
bilheteria de verdade num servidor Linux alugado num data center, que é a produção, e antes de cada
versão Rui instala a candidata num segundo servidor alugado do mesmo tipo, que é a homologação.

**Os dois servidores alugados mantêm o relógio em UTC**, como servidores alugados muitas vezes vêm.
O notebook do Rui e o seu estão no horário de São Paulo, como o de todo mundo no prédio. Ninguém
escolheu essa diferença e ninguém a anotou, porque ninguém achou que um relógio fizesse parte da
aplicação. A próxima seção mostra quanto ela custa.

## Paridade, e o seu preço

A palavra que os times usam para "a homologação se parece com a produção" é **paridade**, e ela
nunca é perfeita. A produção tem dados de clientes reais e a homologação não pode ter (a aula 20
trata de anonimizá-los). A produção manda e-mail de verdade e a homologação não pode mandar (aula
22). A produção pode rodar em dez máquinas e a homologação em uma. Cada uma dessas lacunas é uma
decisão, e o lugar certo para registrá-la é o plano de teste, junto do motivo, para que um defeito
escondido nela seja um risco conhecido e não uma surpresa.

As lacunas que ninguém decidiu são as perigosas. Um plano de teste não lista uma diferença que
ninguém notou, e é por isso que a primeira pergunta de um testador sobre um defeito que "só acontece
lá" é sempre a mesma: **o que é diferente lá?**
