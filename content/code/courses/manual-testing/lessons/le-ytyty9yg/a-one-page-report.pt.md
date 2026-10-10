---
title: Um relatório de uma página para o boxoffice 1.1
version: 1
---

O plano da aula 1 terminou a lista de entregas com "um resumo de uma página no fim". Esta seção o
escreve, para o boxoffice 1.1, a partir da execução da 1.1 na planilha da aula 18 e dos defeitos
que este curso achou até aqui. **Leia primeiro do jeito que a gerente do teatro leria: de cima para
baixo, parando assim que tiver o bastante para decidir.** O resto da seção diz por que cada linha
está onde está.

## A página

| | boxoffice 1.1, resumo de teste, 10 de outubro de 2026 |
|---|---|
| resposta | **Não está pronto para lançar.** Dois dos três critérios de saída do plano não valem, e o terceiro não foi pedido |
| se for lançado como está | Estudantes pagam preço cheio, ou 10% de desconto se forem sócios, em vez de meia: dois ingressos de Hamlet custam R$ 160,00 em vez de R$ 80,00. Um ingresso já usado na porta pode ser reembolsado, e o lugar dele volta à venda. Um reembolso é aceito depois que o espetáculo começou. Uma palavra digitada no campo de ingressos mostra uma página de erro com o código do próprio programa |
| também em aberto, menores | A tabela de espetáculos rola para o lado no celular. O campo de ingressos não tem rótulo para leitor de tela. Recusar uma ação diz "cannot be useed" |
| desde a 1.0 | Corrigido: seis ingressos podem ser reservados, e um sócio que reserva cinco paga 15% a menos em vez de 25%. Quebrado: o desconto de estudante, que a 1.0 acertava |
| o que mudaria a resposta | O desconto de estudante, os dois defeitos de reembolso e a página de erro corrigidos num build novo, e a suíte de regressão da aula 10 rodada nele |
| critérios de saída | Todo caso dos riscos A a C passa: **não**, três falham, um de preço e dois de reembolso. Nenhum defeito crítico ou grave em aberto: **não**, o preço, os dois reembolsos e a página de erro são graves. Aceitação assinada: não pedida enquanto os dois primeiros falham |
| não testado | Pagamento, carga e o servidor de e-mail real, deixados de fora pelo plano. O link de confirmação, R3, ainda não tem caso |
| números | 17 casos executados: 10 aprovados, 7 com falha, 0 bloqueados. 7 defeitos em aberto, 2 corrigidos na 1.1, 1 novo na 1.1 |

Os relatos de defeito, a planilha e o `results-1.1.xml` vão junto como links, para quem quiser
conferir uma linha.

## Por que nessa ordem

**A resposta é a primeira linha, e é uma palavra.** A gerente que não lê mais nada sabe que não
deve lançar. "Não está pronto" é dito com todas as letras, sem "algumas preocupações" ou "passando
em boa parte", porque uma resposta amaciada é lida como sim.

**As consequências vêm antes da evidência.** A segunda linha é o que acontece com os clientes e o
dinheiro do teatro, nas palavras do teatro: preços em reais, ingressos, reembolsos, o espetáculo
começando. Não há id de caso nela. Cada uma das quatro frases é um relato de defeito de aulas
anteriores, traduzido no que uma pessoa na bilheteria veria.

**Os defeitos menores são citados, e ficam à parte.** Uma mensagem com erro de grafia não é motivo
para segurar uma versão, e pô-la na mesma lista do preço faria o preço parecer tão pequeno quanto
a mensagem. Citá-la ainda importa: a gerente pode decidir lançar um build posterior com esses três
em aberto, e isso deve ser uma decisão, não uma surpresa.

**"Desde a 1.0" está ali porque o último relatório é o que o leitor lembra.** A 1.1 corrigiu duas
coisas e quebrou uma. Dizer isso impede o leitor de supor que a 1.1 é simplesmente melhor, e é a
regressão que a aula 10 achou, contada como notícia.

**O que mudaria a resposta é específico.** Quatro defeitos, um build novo, uma suíte rodada de
novo. A gerente pode perguntar ao Rui quanto tempo os quatro levam e planejar uma data a partir
disso; "é preciso testar mais" não lhe daria nada para perguntar.

**Os critérios de saída são os do plano, citados de volta.** Ninguém pode dizer que a régua subiu
no fim, porque ela foi escrita na aula 1, antes de qualquer caso rodar. A severidade é o único
julgamento da linha, e é a escala da aula 15, aplicada na triagem da aula 16.

**O que não foi testado está na página.** O link de confirmação não tem caso nenhum. Uma gerente
que lê esta página e lança sabe disso, e essa é a diferença entre um risco assumido e um risco não
visto.

**Os números vêm por último, e cada um diz o que conta.** Dezessete casos, dez aprovados, sete com
falha, nada bloqueado. Nenhuma taxa de aprovação, pelo motivo que a seção 01 desta aula deu.

## O que ficou de fora

Os resultados caso a caso, que estão a um link. Os gráficos, que repetiriam o que a linha dos
números já diz. O esforço: quantas horas, quantos casos escritos, coisa de que ninguém que decide
uma versão precisa. E o histórico de cada defeito, que mora no rastreador da aula 17.

**Deixar isso de fora é a parte difícil, e é a habilidade.** Uma testadora que passou duas semanas
numa versão conhece cada um desses detalhes e quer que todos sejam vistos. A página não é o
registro desse trabalho; a planilha, o XML e os relatos são. A página é a única coisa que a gerente
precisa ler antes de decidir, e cabe numa página porque ela tem outras coisas para ler hoje.

## Escrevendo a sua

Seja qual for o produto, as mesmas linhas funcionam:

1. a resposta, numa palavra ou numa frase curta;
2. o que acontece se for lançado como está, nas palavras do negócio;
3. os problemas menores, à parte;
4. o que mudou desde a última versão;
5. o que mudaria a resposta;
6. os critérios de saída do plano, cada um com sim ou não;
7. o que não foi testado;
8. os números, cada um dizendo o que conta.

Se a página não cabe numa página, quase sempre é a segunda linha tentando descrever todos os
defeitos. Fique com os que mudariam a decisão, e ponha link para o resto.
