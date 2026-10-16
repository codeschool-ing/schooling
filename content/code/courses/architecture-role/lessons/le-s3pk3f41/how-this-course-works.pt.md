---
title: Como este curso funciona
version: 1
---

Este é um curso sobre um papel, não sobre uma tecnologia. **Você já sabe construir um back-end; este
curso é sobre a pessoa que decide como as peças dele se encaixam, e que responde por essa decisão
depois.** Ele abre a trilha de arquitetura de software e pressupõe a trilha de back-end antes dela:
você já escreveu uma API, desenhou tabelas, pôs um serviço num contêiner, e em `architecture` e
`scale` conheceu o monólito, os microsserviços, as filas, as réplicas e o back pressure. Aqueles
cursos ensinaram os estilos. Este é sobre escolher entre eles, registrar a escolha e conviver com
ela.

## Nada para instalar

**A prática deste curso é ler, escrever e desenhar.** Não há servidor para rodar nem ambiente para
montar. Você precisa de três ferramentas comuns, cada uma com uma opção gratuita:

| ferramenta | opções gratuitas | onde o curso usa |
|---|---|---|
| um editor de texto | o mesmo que você usa desde o começo da trilha de back-end | em todas as aulas: registros de decisão na aula 5, padrões na aula 9, suas próprias notas o tempo todo |
| uma ferramenta de diagramas | diagrams.net, gratuito no navegador ou como aplicativo de desktop, salvando os arquivos no seu próprio disco; Excalidraw, gratuito e de código aberto; papel e lápis | caixas e setas desde esta aula, e a escolha de visões na aula 8 |
| uma planilha | LibreOffice Calc, gratuito; qualquer outra planilha funciona do mesmo jeito | uma matriz de decisão ponderada na aula 6, três opções com custo na aula 13, estimativas na aula 14 |

Papel não é uma escolha menor. **Uma ferramenta de diagramas tenta você a deixar o desenho arrumado;
o papel obriga você a decidir o que são as caixas**, e a segunda coisa é a habilidade.

**Há um único programa no curso inteiro, na aula 9**, e rodá-lo é opcional. É um script curto em
Python 3, só com a biblioteca padrão, que lê um pequeno projeto de exemplo e falha quando um módulo
importa outro que não tem permissão de importar. Ler o script e a saída dele basta para acompanhar a
aula. Se quiser rodá-lo, você precisa do Python 3: se fez o caminho de Python da trilha de back-end,
a aula 1 de `python` o instalou; senão, ele vem de python.org ou do gerenciador de pacotes do seu
sistema. Nada mais é necessário, porque o script não usa nada fora da biblioteca padrão.

## A empresa que você vai acompanhar

Todas as aulas acompanham uma única empresa. **A Carreto é inventada**: um marketplace de frete em
Curitiba, fundado em 2017, que conecta *embarcadores* a caminhoneiros autônomos e pequenas
transportadoras. Um embarcador é uma empresa com cargas para mover — uma fábrica de móveis, uma
cooperativa de grãos, o centro de distribuição de uma rede de supermercados. O embarcador publica
uma carga, a Carreto cota o frete, oferece a carga a motoristas adequados, acompanha o caminhão e,
quando a entrega é comprovada, paga o motorista e fatura o embarcador.

Cerca de **50 engenheiros em 7 times** constroem o sistema:

| time | do que é dono |
|---|---|
| Shipper | o app web em que os embarcadores publicam e acompanham cargas |
| Driver | o app móvel dos motoristas |
| Matching | oferecer cada carga aos motoristas adequados |
| Pricing | cotar o frete |
| Payments | pagar os motoristas e faturar os embarcadores |
| Tracking | posições de GPS e comprovante de entrega |
| Platform | infraestrutura, CI e observabilidade |

O sistema começou como **uma aplicação Django com um banco PostgreSQL**, que todo mundo na Carreto
chama de "o monólito". Com os anos, algumas partes saíram dele. O Tracking roda como serviço
próprio, com banco próprio, o Pricing é um serviço separado, e um broker de mensagens leva eventos
para alguns dos times. Quando este curso começa, são **14 serviços implantáveis para 50
engenheiros**. Alguns mereceram existir e outros não; a aula 12 faz a conta.

A Carreto também trabalha sob regras que não escreveu. O frete no Brasil é regulado. Todo serviço de
frete precisa de um conhecimento de transporte eletrônico, o CT-e, autorizado pela secretaria da
fazenda do estado antes de o caminhão sair. A agência nacional de transportes publica um piso mínimo
do frete, abaixo do qual nenhuma cotação pode ficar. E os motoristas querem receber rápido, muitos
deles por Pix. A seção 05 desta aula trata essas regras como parte da arquitetura, que é o que elas
são.

## As pessoas

A protagonista é **Renata Okubo**, engenheira staff que trabalha na Carreto há seis anos. Ela
escreveu boa parte do código original de Payments e tem sido a pessoa que os outros times chamam
quando um problema atravessa as fronteiras deles. Nesta semana o CTO, Tomás Viana, cria um papel que
a Carreto nunca teve e o entrega a ela: Renata se torna a primeira arquiteta de software da empresa.
O curso acompanha o que ela faz com o papel, inclusive as partes em que erra.

| pessoa | papel |
|---|---|
| Renata Okubo | engenheira staff, agora a primeira arquiteta de software da Carreto |
| Tomás Viana | CTO, que criou o papel |
| Helena Prado | diretora de produto |
| Sílvio Matos | diretor financeiro |
| Bruno Farias | tech lead de Payments |
| Kátia Lemos | tech lead de Matching |
| Diego Araújo | tech lead do app Driver |
| Ícaro Nunes | desenvolvedor júnior em Payments, formado há dois anos |
| Paula Reis | engenheira sênior em Platform |

Todo mundo nessa tabela é fictício, e os números da Carreto também. As ideias que eles ilustram não
são: cada uma vem com a fonte, para você poder ler o original.

## Como uma aula é organizada

Toda aula tem a mesma forma: um vídeo curto que diz para que a aula serve, três seções de leitura e
uma seção de prática no fim. Esta primeira aula tem uma quarta seção de leitura, esta que você está
lendo.

**As questões de uma aula não valem nota.** Uma resposta errada mostra por que está errada, e você
segue em frente. Muitas são sobre julgamento, não sobre fato — que decisão é arquitetural, que jeito
de decidir combina com uma situação — e nessas o curso se compromete com uma resposta e explica o
raciocínio na própria opção. Se você discordar depois de ler a explicação, fez o que a questão
pedia. A prova do curso, no fim, é o único lugar que vale nota.

## Um hábito para começar agora

Mantenha uma pasta de arquivos de texto simples, um por aula. **Quando uma aula fizer alguma coisa
na Carreto, anote como a mesma coisa aparece onde você trabalha**, ou no último sistema que você
construiu. A Carreto é arrumada porque foi inventada para ensinar; o seu sistema não é, e a
distância entre os dois é onde a maior parte do que este curso ensina é posta à prova.
