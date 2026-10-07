---
title: O que este curso faz, e com quais dados
version: 1
---

**Limpar é a parte da análise que decide se o resto dela é verdade.** Um gráfico, um modelo ou um
painel é uma conta sobre linhas, e nenhum deles distingue uma linha real de uma repetida, um preço
de um erro de digitação, ou uma célula vazia que quer dizer zero de outra que quer dizer que
ninguém perguntou. Você distingue. Este curso é sobre fazer isso de propósito, numa ordem, e com
registro de cada decisão.

Não é um curso de truques. Cada aula pega um tipo de defeito e mostra de onde ele vem, como
encontrá-lo, quais são as escolhas honestas e quanto custa cada uma. O código é curto. O assunto é
o julgamento.

## A empresa, e a pergunta

Toda aula trabalha sobre os mesmos dados: os sistemas da **Quitanda Verde**, uma mercearia de
orgânicos que não existe. Ela tem cinco lojas — Pinheiros em São Paulo, Cambuí em Campinas,
Botafogo no Rio de Janeiro, Savassi em Belo Horizonte e Batel em Curitiba — e um site e um
aplicativo que entregam.

Na primeira semana de janeiro de 2026, a analista, Ana, recebe o que esses sistemas exportam e uma
pergunta: **dá para confiar nos números de 2025?** Os arquivos são o que sistemas assim produzem de
verdade. O site escreve datas de um jeito, o aplicativo de outro e o caixa antigo das lojas de um
terceiro. O arquivo de clientes foi exportado num dia diferente do de pedidos. Algumas pessoas se
cadastraram duas vezes. Um vazio numa coluna quer dizer zero, e um vazio na coluna seguinte quer
dizer que o cronômetro desistiu.

Nada disso foi achado por acaso. O gerador do laboratório planta cada defeito de propósito e anota
onde o pôs, para que uma aula diga não só que uma técnica encontrou duplicados, mas **quantos dos
verdadeiros ela encontrou** — uma pergunta que o trabalho real quase nunca deixa responder.

## Como uma aula funciona

Cada aula faz o trabalho duas vezes, em **SQL no PostgreSQL** e em **pandas**, porque são os dois
lugares onde esse trabalho acontece na prática e porque cada um facilita um erro diferente. A aula
16 junta o Excel e o dplyr do R à comparação e diz quando usar cada um.

::: track bi
Você chega aqui vindo do `excel-analytics`, onde as aulas 13 e 14 fizeram boa parte disto no Power
Query, e do `sql-databases`. A metade em SQL de cada aula foi escrita para você, e todo exercício
pode ser respondido a partir dela. A metade em pandas aparece ao lado para você ler; o Python em si
chega mais adiante na sua trilha, com o `python`, e este curso é um bom motivo para levá-lo a
sério.
:::

::: track data-science
Você chega aqui vindo do `python-data`, onde as aulas 9 a 15 ensinaram o pandas que este curso
usa, e do `sql-databases`. Aqui o pandas é a ferramenta, e o assunto é o julgamento por trás de
cada chamada. O SQL ao lado está ali porque boa parte da limpeza real acontece antes de o dado sair
do banco, e porque um colega vai pedir que você a faça lá.
:::

::: track *
A metade em SQL de cada aula se sustenta sozinha, e a metade em pandas também: leia a que você
conhece e use a outra como tradução.
:::

Todo comando mostrado foi executado, no laboratório descrito na próxima seção, e a saída aparece
como saiu. Onde algo não pôde ser executado aqui, a aula diz.

## A ordem das aulas

| aulas | o que fazem |
|---|---|
| 1–2 | medir os dados e perfilá-los antes de mexer em qualquer coisa |
| 3–4 | valores faltantes: por que faltam, e depois o que fazer |
| 5 | duplicados, exatos e aproximados |
| 6–8 | texto, formatos e categorias levados a uma grafia só |
| 9 | valores atípicos: erro de digitação, evento real ou fraude |
| 10–11 | tipos convertidos com segurança, e tabelas juntadas sem perder nem multiplicar linhas |
| 12–14 | transformações, mudança de formato e enriquecimento com fontes externas |
| 15 | análise exploratória como a última checagem antes de entregar o dado |
| 16–17 | as ferramentas comparadas, e como tornar tudo repetível |

**O que fica para outros cursos.** Rodar a limpeza num agendamento, dentro de um pipeline, é o
`pipelines-etl`, cuja aula 16 transforma as checagens deste curso em testes que param uma carga.
Decidir quem é dono de uma coluna e quem pode mudá-la é o `data-governance`, aula 9. Desenhar o
dado limpo é o `visualization`, que vem logo depois deste curso nas duas trilhas.
