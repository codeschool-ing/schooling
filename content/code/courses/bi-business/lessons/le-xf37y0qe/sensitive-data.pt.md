---
title: Dado de saúde é dado sensível
version: 1
---

Os dados de venda da Varanda dizem que alguém comprou uma mangueira. Os dados do Jacarandá dizem que
alguém tem insuficiência cardíaca, foi internado numa terça e voltou três semanas depois. **A lei
brasileira de proteção de dados, a LGPD, põe o dado referente à saúde numa categoria própria, a de
dado pessoal sensível** (art. 5º), com condições de uso mais rígidas que as de um endereço ou de um
histórico de compras, e a autoridade nacional, a ANPD, fiscaliza o seu cumprimento. As aulas 6 e 7
de `data-governance` tratam da lei em si. Esta seção é sobre o que ela faz com o trabalho diário de
um analista da saúde, que se resume quase todo a três hábitos.

## Agregar antes de qualquer coisa sair do sistema

O sistema clínico do hospital guarda o prontuário do paciente, e os médicos e enfermeiros que o
tratam o leem ali, sob regras de acesso que o sistema aplica. **A análise quase nunca precisa saber
quem é o paciente**, então o primeiro hábito é tirar contagens do sistema clínico e deixar os nomes
lá dentro.

O quadro de leitos da seção sobre fluxo de pacientes é um exemplo. Cláudia precisa saber qual paciente vai para
qual leito, e encontra isso no sistema clínico, onde o papel dela permite. O quadro em si mostra
contagens por ala: 7 esperando, 1 leito a menos. Uma tela na parede da sala de gestão de leitos é
vista por todo mundo que passa, e nada nela tem o nome de ninguém.

## Células pequenas identificam pessoas

Agregar não basta quando os grupos são pequenos. Uma secretaria de saúde publica internações por
cidade e por causa, e uma linha diz: uma cidade de 3.000 habitantes, 2 internações por HIV em 2025.
**Numa cidade de 3.000 pessoas, uma contagem de 2 não é anônima**: os vizinhos sabem quem foi duas
vezes a Campinas para se tratar naquele ano, e a tabela publicada confirma o que eles suspeitavam.

A resposta de costume é a **supressão de células pequenas**: toda contagem abaixo de um limite é
trocada por um símbolo, como "<5". O limite é decisão de quem publica, escrita nas suas regras;
cinco e dez são comuns. Uma tabela com supressão fica assim:

| causa | internações |
|---|---|
| insuficiência cardíaca | 12 |
| pneumonia | 17 |
| HIV | <5 |
| total | 31 |

E ela entrega a célula. O total está ali, e as outras duas causas também, então qualquer um pode
subtrair:

```localised
=31-12-17      2
```

**Suprimir uma célula não serve de nada se o total e as outras células ainda permitem calculá-la.**
A correção é suprimir uma segunda célula também (supressão complementar), arredondar o total ou
juntar as cidades pequenas numa região antes de publicar. Um painel que deixa o usuário filtrar até
uma cidade e uma causa recria o problema a cada clique, e é por isso que painéis de saúde aplicam o
limite a qualquer coisa que o filtro produza, e não só à visão inicial.

## Acesso por papel

O terceiro hábito é que o acesso segue a função. Débora precisa de dados por internação para montar
a taxa de reinternação, porque uma reinternação é o mesmo paciente duas vezes, e isso não se conta a
partir de totais. Ela trabalha com uma versão dos dados em que o nome e os documentos do paciente são
trocados por um código, o mesmo código toda vez que o paciente aparece. Isso é dado
**pseudonimizado**: ela consegue ligar as duas internações sem saber de quem são. Continua sendo dado
pessoal pela LGPD, porque o hospital guarda a chave que transforma o código de volta num nome; a
aula 21 retoma a diferença entre isso e o dado anonimizado.

A equipe financeira vê custos por ala e por procedimento, e nenhum diagnóstico. Os gestores de ala
veem a própria ala. A diretoria vê os indicadores mensais. Nada disso é incomum, e tudo isso tem de
ser decidido e escrito antes de publicar o primeiro painel, porque um painel compartilhado por link
chega a quem o link chegar.

## O que isso faz com as quatro perguntas

A saúde é o setor em que a terceira pergunta da aula 17, os dados e o que eles têm de estranho, muda
as outras três. Um bom indicador que exige dados por paciente numa tela é muitas vezes uma escolha
pior que um indicador um pouco mais grosseiro que não exige. O analista que vem do varejo, onde o
pior vazamento é um número de vendas, precisa aprender que aqui o pior vazamento é uma pessoa.
