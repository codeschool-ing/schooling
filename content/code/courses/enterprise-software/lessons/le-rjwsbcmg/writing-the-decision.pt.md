---
title: Pondo a decisão no papel
version: 1
---

A planilha, as curvas e a sensibilidade são as evidências. A decisão é uma página que alguém assina, e
é essa página que vai ser lida em 2029, quando chegar a proposta de renovação, por pessoas que não
estavam na sala. Você conheceu a forma na aula 5 de `architecture-role` — o registro de decisão de
arquitetura de Michael Nygard, de 2011, com título, status, contexto, decisão e consequências — e a
aula 5 de `architecture-modeling` acrescentou as opções e como compará-las. **Um registro de comprar
ou construir precisa de quatro coisas a mais que um registro técnico**: os números com as premissas
em que se apoiam, o ponto fraco honesto da escolha, o gatilho que a reabriria, e os nomes de quem
decidiu e de quem discordou.

## O registro

Joana o escreveu numa tarde, depois da reunião com Marcos e Regina. Tem cerca de 500 palavras.

> **Pagamento aos produtores: substituir a parte da Coleta que atende as fazendas por um produto SaaS
> comprado.** Status: aceito, 26 de novembro de 2026.
>
> **Pergunta.** Como a Serra Alta substitui o que a Coleta faz para as fazendas — registrar cada
> coleta, guardar os resultados de laboratório e calcular o pagamento mensal — antes de Sebastião Lima
> se aposentar, no fim de junho de 2028?
>
> **Contexto.** 1.900 fazendas são pagas no dia 10 de cada mês, segundo 46 regras. O comitê de
> qualidade revisa as tabelas de bonificação duas vezes por ano, e as tabelas são como a Serra Alta
> segura as melhores fazendas; o cálculo que as aplica é feito do mesmo jeito por todo laticínio. A
> conversão para o S/4HANA está planejada para entrar em produção em janeiro de 2028.
>
> **Opções, em 36 meses a partir de janeiro de 2027, em reais.** A, comprar um produto SaaS:
> 4.233.500, primeiro pagamento aos produtores em outubro de 2027. B, estender o SAP depois da
> conversão para o S/4HANA: 5.261.000, primeiro pagamento em maio de 2028. C, construir internamente:
> 4.679.000, primeiro pagamento em abril de 2028. Os totais incluem integração, o time interno, a
> Coleta mantida no ar e o custo de sair. A planilha completa vai anexa.
>
> **Premissas.** A Serra Alta acrescenta 100 fazendas por ano. O reajuste na primeira renovação tem
> teto de 4%. Uma pessoa custa R$ 25.000 por mês. Um sistema que construímos custa 20% da construção
> por ano para manter. Os valores são nominais; descontar a 10% a 15% ao ano não muda a ordem.
>
> **Decisão.** Vamos comprar a opção A, com prazo de 24 meses, renovações de 12 meses e o teto de 4%.
> 41 regras são configuradas nas tabelas de regras do produto, de responsabilidade do comitê de
> qualidade; 5 são extensões escritas ao lado do produto, pela interface publicada dele, e nunca
> dentro dele. Toda interface passa pela nossa própria camada anticorrupção. O contrato inclui a
> exportação do histórico com dicionário de dados.
>
> **Por quê.** A é a mais barata, por R$ 445.500, e a única opção que desliga a Coleta com Sebastião
> ainda aqui. Ela continua a mais barata contra um reajuste de até 61% na renovação, e uma construção
> atrasada só aumenta a diferença: com 50% de atraso, C custaria R$ 5.513.000 e desligaria a Coleta
> seis meses depois de Sebastião sair.
>
> **Ponto fraco.** As cinco regras estendidas são onde a nossa política de qualidade encontra o
> calendário de versões de outra empresa. Se as próximas revisões do comitê precisarem de regras que
> o produto não expressa, cada uma vira uma extensão, e a política passa a andar na velocidade das
> extensões. Num horizonte mais longo, C é mais barata de rodar: se o ano 3 se repetisse, ela
> alcançaria A durante o sétimo ano.
>
> **Revisitar quando** qualquer proposta de renovação passar de R$ 32 por fazenda por mês; ou mais de
> 10 das regras precisarem de extensão; ou o fornecedor for vendido ou mudar a interface sem o aviso
> combinado. Em qualquer caso, todo ano até 31 de maio, antes da data do aviso prévio.
>
> **Decidido por** Marcos Teles, CFO, e Regina Fontes, CIO, por recomendação de Joana Brandão.
> Consultados: Cláudia Mendes, Edson Prado, Sebastião Lima e o time de produto do Rota. Edson Prado
> preferia B, para manter os pagamentos das fazendas dentro do sistema de registro; o registro guarda
> o motivo dele, e a integração pelas interfaces publicadas do SAP responde a parte dele.

## O que faz disso um registro e não um discurso de vendas

**Cada número carrega a premissa que o produziu.** O preço do ano 3, os 20% de manutenção, as 100
fazendas por ano: quem ler isso em 2029 consegue conferir cada um contra o que aconteceu, e saber que
parte da decisão envelheceu.

**O ponto fraco é escrito por quem recomenda a opção.** Teria sido fácil deixá-lo de fora — ninguém
na reunião o pediu. **Uma recomendação sem ponto fraco soa como advocacia**, e o leitor que mais
tarde encontra a fraqueza sozinho deixa de confiar nos números em volta dela. O de Joana é real: as
cinco regras são exatamente onde a política que a seção 02 desta aula chamou de núcleo toca um
produto que a Serra Alta não controla. Nomeá-lo põe o risco onde o comitê pode vigiá-lo.

**O gatilho é mensurável e fica abaixo do ponto de empate.** A perde para C a R$ 40,14 por fazenda
por mês. O gatilho é R$ 32, porque a decisão de sair tem de ser tomada seis meses antes de uma
renovação, e a hora de preparar uma alternativa é antes de o preço do fornecedor torná-la
necessária. "Revisitar se as circunstâncias mudarem" não teria disparado nada.

**A discordância fica registrada com o motivo.** O argumento de Edson a favor de B — um sistema de
registro só, nenhuma interface para o dinheiro das fazendas — era bom e perdeu no custo e na data.
Escrevê-lo é o que permite que ele ganhe da próxima vez, se os motivos contra ele desaparecerem.

**A data no calendário é a data do aviso prévio.** O momento mais barato para reconsiderar um
contrato SaaS é o mês antes de o aviso vencer. O registro transforma esse mês numa obrigação com dono.

## O que você leva deste curso

Quinze aulas atrás, Joana chegou a uma empresa cujos sistemas ninguém pode desligar. O que ela
aprendeu é o que você agora consegue fazer no lugar dela:

- ler um ERP como os livros da empresa e o fluxo de documentos dela, e saber por que ele restringe
  todo desenho em volta (aulas 1 e 2), e reconhecer as famílias de software corporativo — a da
  Microsoft, a da Salesforce, os gerenciadores de documentos, as suítes de workflow — pelo que elas
  possuem e pelo que custa conviver com elas (aulas 3 a 6);
- modelar um processo de negócio de modo que as pessoas que o executam consigam lê-lo, e saber o que
  é preciso para um modelo executar (aula 7);
- herdar um ESB e SOAP sem desprezo, e encolhê-los de propósito (aula 8);
- escolher entre integrar por arquivo, banco de dados, API e evento, e montar as filas, os
  consumidores idempotentes e os padrões que fazem qualquer um deles sobreviver a uma noite ruim
  (aulas 9 a 11);
- escrever os contratos, as janelas e os SLAs de sistemas que não podem parar (aula 12);
- aposentar um sistema de que o negócio ainda depende, uma capacidade por vez, e migrar os dados
  dele com prova de que chegaram (aulas 13 e 14);
- e decidir se compra ou constrói o que o substitui, com todas as linhas contadas e o ponto fraco por
  escrito.

**Nada disso é sobre um produto específico.** Os produtos das aulas 2 a 6 vão ser renomeados,
comprados e substituídos enquanto você trabalha. As perguntas que você faz a eles continuam valendo:
de quem são os dados, o que o contrato deixa você fazer, quanto custa a integração, quanto custa sair,
e se o trabalho é o que diferencia a empresa ou o que toda empresa precisa acertar.
