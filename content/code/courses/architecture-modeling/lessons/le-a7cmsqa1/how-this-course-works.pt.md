---
title: Como este curso funciona, e o que você precisa para ele
version: 1
---

**Este curso ensina a desenhar arquitetura de um jeito que outra pessoa entenda, e a manter o
desenho, a decisão por trás dele e o documento em volta verdadeiros enquanto o sistema viver.** Ele
trata de notações, registros e frameworks, e cada um deles é julgado pelo mesmo critério: quem leu
entendeu o que quem escreveu quis dizer?

## Carcará, a empresa de todas as aulas

Os exemplos vêm de uma empresa só, do começo ao fim. **A Carcará é fictícia**: uma empresa de
ônibus intermunicipais com sede em Salvador, 140 linhas pela Bahia, cerca de 300 ônibus e mais ou
menos 9.000 passagens vendidas num dia comum. Perto das festas de São João, em junho, e de novo no
Natal, esse número quadruplica, e a semana anterior é quando tudo o que era frágil quebra.

Quarenta engenheiros trabalham lá, em cinco times. **Vendas** faz o site e o app do passageiro,
**Embarque** faz o app que os motoristas usam para conferir passagens na porta do ônibus. **Pagamentos** cuida da integração com o gateway de pagamento, **Frota** cuida da ligação com o
sistema antigo que conhece ônibus e motoristas, e **Plataforma** roda a infraestrutura de todo mundo.

Algumas pessoas aparecem mais de uma vez:

| | quem | o que espera de um diagrama |
| --- | --- | --- |
| **Tainá** | a arquiteta, uma engenheira staff que os outros chamam quando uma decisão atravessa times | ser entendida de primeira, por gente que não estava na sala |
| **Otávio** | head de produto | o que uma mudança vai deixar o cliente fazer, e quando |
| **Celeste** | diretora de operações, responsável por os ônibus saírem de fato | o que pode impedir um ônibus de embarcar passageiros |
| **Rui** | lidera o time de Plataforma | o que roda onde, e o que fala com o quê |
| **Joana** | analista de negócios, quem transforma um pedido em requisitos | o que o sistema precisa fazer, escrito de um jeito que dê para conferir |
| **Bento** | um engenheiro no primeiro mês de trabalho | por onde começar |

O mesmo sistema é desenhado várias vezes em notações diferentes, de propósito. Até a aula 4 você
terá visto a venda de passagem da Carcará como caso de uso, como sequência de mensagens, como
conjunto de containers e como máquina de estados, e a comparação entre esses desenhos ensina mais
do que qualquer um deles sozinho.

## Nada para instalar, em treze das catorze aulas

**Este curso não tem ambiente de execução.** Não há programa para rodar nas aulas 1 a 11, 13 e 14,
nem máquina para preparar. O que você vai usar é comum e gratuito:

| | para que serve | opções gratuitas |
| --- | --- | --- |
| **papel e lápis** | o primeiro rascunho de cada diagrama, que deve ser rápido e descartável | — |
| **uma ferramenta de diagramas** | o desenho que você guarda | [diagrams.net](https://www.drawio.com/), também chamado draw.io, gratuito e de código aberto, no navegador ou como programa; [Excalidraw](https://excalidraw.com/) para esboços com cara de esboço |
| **um editor de texto** | registros de decisão, listas de requisitos e os documentos das aulas 5 a 11 | o que você já usa para programar; o Visual Studio Code é gratuito, e qualquer editor de texto puro também serve |
| **um lugar para guardar os registros** | para que os registros de decisão da aula 5 fiquem em ordem e tenham histórico | uma pasta de arquivos Markdown, de preferência num repositório Git ao lado do código |

**A aula 12 é a exceção.** Diagramas escritos como texto precisam de três programas pequenos para
virar desenho, e essa aula começa mostrando como prepará-los no seu computador, numa máquina virtual
ou no navegador, antes de pedir que você digite qualquer coisa.

## O que as questões podem e não podem perguntar

**Um curso sobre desenhar, numa plataforma que não consegue receber um desenho, é uma concessão
real**, e é melhor dizer isso aqui do que você descobrir na aula 3. As questões de cada aula
conferem o que uma máquina consegue corrigir: mostram um diagrama pronto e perguntam o que está
errado nele, pedem que você ponha nomes nas partes de um, que ordene os passos de um método ou que
escolha entre dois registros. Essa é a metade de leitura da habilidade, e é a metade em que a
maioria dos diagramas falha.

A metade de desenho é sua. **Muitas seções terminam com algo para desenhar para a Carcará**, e a
seção seguinte, ou a figura dentro dela, mostra uma boa resposta. Desenhe a sua primeiro, no papel,
antes de olhar; depois compare com a lista de conferência da seção sobre o teste de leitura, nesta
aula. Um diagrama que você desenhou e depois corrigiu ensina mais do que dez que você só leu.
