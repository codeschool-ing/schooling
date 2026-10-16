---
title: Por que nunca há uma só
version: 1
---

**Uma empresa na AWS roda várias contas, e o motivo são as paredes.** A imagem com que as pessoas
chegam é uma conta só, dividida por tags e por políticas do IAM bem cuidadas: recursos de produção
com a tag `env=prod`, uma política que mantém os desenvolvedores longe deles, uma fatura lida por
tag. Funciona no primeiro dia. Falha de três jeitos que cada um parece erro de alguém, e cada um é o
mesmo erro: **duas coisas que não deviam dividir uma parede foram postas dentro de uma só**.

## Três jeitos de uma conta só dar errado

**O experimento de uma desenvolvedora fica ao lado da produção.** Para testar algo, a `bia` precisa
criar e apagar máquinas. Numa conta compartilhada, a permissão de apagar as máquinas dela tem de ser
escrita de modo a não alcançar as da produção, em geral como uma condição sobre uma tag. Um recurso
criado sem a tag, ou uma política que esqueceu a condição, e o experimento pode apagar o que os
clientes usam. A lição 8 mostra como uma condição dessas é avaliada. Aqui, **a
segurança depende de toda política e toda tag estarem certas, toda vez**. Numa conta separada, o
mesmo erro apaga o sandbox.

**Um teste gasta a cota da produção.** A cota da primeira seção, cinco VPCs por região, é contada
para a conta inteira. Suponha que o build cria uma VPC para cada pull request que testa, e que há
três abertos. Com a VPC padrão e a da produção, são cinco, e o próximo deploy que precisar de uma
rede é recusado. Nada estava errado no deploy e nada estava errado nos testes. Eles foram contados
contra um número de que a produção também precisava. Em contas separadas, cada uma tem as suas
cinco.

**A fatura não pode ser dividida.** Tags dividem as linhas que as carregam, e a lição 13 faz a loja
pôr tag em tudo o que pode. Mas nem tudo numa fatura é um recurso com tag. Uma máquina que alguém
esqueceu de marcar não cai em equipe nenhuma. Algumas cobranças, como o plano de suporte, pertencem
à conta e não a um recurso dentro dela. Quando a loja inteira é uma conta, essas linhas não são de
ninguém, e "quanto custa o staging" não tem resposta exata. **Quando o staging é uma conta própria, a
resposta é a linha dele na fatura**, e a lição 3 mostra como uma fatura só ainda carrega todas as
contas.

## A divisão que a loja usa

A forma abaixo é aquela a que chegam o guia da própria AWS e a maioria das empresas, e é a que este
curso constrói nas lições 3 a 5:

| conta | o que mora lá | quem entra |
|---|---|---|
| gerenciamento | a organização e a fatura, e mais nada | quase ninguém, quase nunca |
| `shop-prod` | a loja que os clientes usam | o pipeline de deploy; pessoas só para ler, ou numa emergência |
| `shop-staging` | uma cópia da loja, para testar versões | o pipeline e os desenvolvedores |
| `sandbox` | experimentos, limpos regularmente | qualquer desenvolvedor, com um orçamento pequeno |
| `security` | as ferramentas que vigiam todas as outras contas | a equipe de segurança, só leitura no resto |
| `log-archive` | uma cópia dos logs de toda conta, que ninguém pode apagar | quase ninguém; os logs chegam sozinhos |

**Produção e staging são separadas para um teste não poder tocar nos clientes**, e para uma versão
ser testada num lugar com a mesma forma antes de chegar a eles. Muitas empresas também mantêm uma
conta de desenvolvimento por equipe; a loja é pequena e deixa o `sandbox` fazer esse papel.

**`security` e `log-archive` ficam separadas de tudo o que vigiam.** A pergunta que elas respondem é
o que aconteceu, e a resposta tem de sobreviver a alguém que controla uma conta de carga de trabalho
e quer que ela seja outra. Se os logs da `shop-prod` moram na `shop-prod`, quem tomar essa conta pode
apagar a prova de ter feito isso. Numa conta própria, com uma barreira que proíbe apagá-los, não pode.
A lição 4 escreve essa barreira e a lição 5 constrói as duas contas.

**A conta de gerenciamento não guarda carga de trabalho**, por um motivo que a lição 4 torna preciso:
é a única conta que as barreiras da organização não conseguem restringir. Qualquer coisa rodando lá
roda fora de toda regra que a organização define.

## Quanto custa ter seis

Uma conta não custa nada para criar ou manter. **O que custa é a base**: toda conta precisa do mesmo
registro de logs, das mesmas barreiras, do mesmo jeito de as pessoas entrarem e do mesmo alerta de
orçamento. Seis contas montadas à mão viram seis contas ligeiramente diferentes em um mês, e a
diferença é descoberta no dia em que importa. As três próximas lições resolvem esse problema, em
ordem. A lição 3 põe as contas numa árvore com uma fatura, e a lição 4 define regras que toda conta
de um galho herda. A lição 5 constrói o arranjo inteiro para que uma conta nova **já
comece certa** em vez de ser consertada depois.

Entrar é o outro custo. Uma pessoa com trabalho em três contas precisa de um jeito de entrar em cada
uma que não sejam três senhas. A lição 11 dá à loja uma entrada única para todas. Um serviço numa
conta que lê de outra precisa de uma role que possa assumir, que a lição 9 constrói. Os dois são uma
porta feita de propósito, que é exatamente para o que as paredes serviam.
