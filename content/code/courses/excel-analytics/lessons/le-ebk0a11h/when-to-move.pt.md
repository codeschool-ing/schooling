---
title: Sinais de que o trabalho ficou grande demais para a pasta
version: 1
---

**Sair do Excel não é um veredito sobre o Excel; é o que acontece quando um trabalho precisa de algo
que um arquivo não dá.** A pergunta nunca é "esta planilha está grande demais?" no abstrato. É se o
trabalho agora precisa de muitos escritores, de um histórico, de regras que se sustentem, ou de uma
resposta só para muitos leitores. Cada uma dessas coisas tem um sintoma que dá para ver de dentro da
pasta de trabalho.

## Os sinais

| o que você percebe | o que significa | do que o trabalho precisa |
|---|---|---|
| um arquivo chega perto da borda da planilha, ou toda edição faz esperar | tamanho | o modelo de dados agora; um banco de dados se continuar crescendo |
| duas ou mais pessoas precisam **lançar** dados no mesmo arquivo | muitos escritores | um banco de dados |
| você precisa saber quem mudou um número, quando e por quê, e desfazer só aquilo | um histórico | um banco de dados |
| uma regra precisa valer seja quem for que lance os dados, colagem incluída | restrições | um banco de dados |
| outro sistema precisa ler ou gravar os mesmos dados | integração | um banco de dados |
| o mesmo arquivo sai por e-mail toda semana para gente que só **lê** | distribuição | uma plataforma de BI |
| o mesmo KPI está definido em três pastas e dá três respostas | uma definição | o modelo compartilhado de uma plataforma de BI |
| atualizar e mandar o relatório é a manhã de segunda de alguém | um horário | a atualização agendada de uma plataforma de BI |

A tabela se divide limpa em duas, e a divisão é a parte útil. **Problemas de escrita apontam para
um banco de dados. Problemas de leitura apontam para uma plataforma de BI.** A Café Serra poderia
ter um tipo sem o outro: uma segunda loja lançando vendas precisa de um banco de dados muito antes
de alguém precisar de um painel publicado, e um grupo de investidores lendo os números do mês
precisa de um painel publicado enquanto uma pessoa só ainda digita cada venda.

## Mudar não é tudo ou nada

Os dados mudarem de lugar não quer dizer que o Excel vá embora. O arranjo comum é os registros
morarem num banco de dados e o Excel os ler. O Power Query se conecta a um banco de dados como a
aula 13 descreveu, carrega as linhas no modelo de dados, e as tabelas dinâmicas, as medidas e o
painel das aulas 15 a 17 funcionam como antes, sobre dados que muita gente gravou com segurança. O
que sai da pasta de trabalho é a tarefa de **guardar** os registros. A tarefa de **fazer perguntas**
a eles muitas vezes fica exatamente onde estava.

## Quando a pasta de trabalho é a resposta certa

A maior parte das análises nunca encontra nenhum desses sinais, e mudá-las só traria custo. O Excel
é a ferramenta certa quando:

- uma pessoa, ou uma equipe pequena que se reveza, é dona dos dados e da pergunta;
- os dados cabem com folga, e chegam como arquivo ou consulta, não digitados por muita gente;
- a resposta é para hoje, e a pergunta talvez nunca mais seja feita;
- quem lê é quem montou, ou umas poucas pessoas a quem dá para mandar um PDF.

Isso descreve a Café Serra como ela está: 108 vendas, uma dona, um painel lido uma vez por mês. O
curso usou o Excel para essa empresa porque o Excel tem o tamanho certo para ela. Os sinais são para
o dia em que isso deixar de ser verdade, para que a mudança seja uma decisão tomada com antecedência
e não uma correria depois que o arquivo já perdeu alguma coisa.
