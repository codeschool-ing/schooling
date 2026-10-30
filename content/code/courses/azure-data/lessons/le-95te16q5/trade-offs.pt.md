---
title: Quando ligar, e a configuração que não tem volta
version: 1
---

**O espaço de nomes hierárquico é escolhido por conta, e depois de ligado fica ligado.** A
documentação da Microsoft é clara sobre a direção: uma conta sem ele pode ser convertida para tê-lo, e
uma conta com ele nunca volta atrás. Isso o põe ao lado do tipo e do desempenho da lição 1, as decisões
da conta que não se desfazem sem mover os dados, e é por isso que a Quitanda tem duas contas em vez de
uma com a configuração ligada para tudo.

Esta seção foi escrita a partir da documentação da Microsoft e não foi rodada, fora o último comando.

## O que custa tê-lo

As pessoas esperam uma troca entre preço e velocidade. A troca de verdade é entre dois conjuntos de
recursos.

**Para análise de dados, o espaço de nomes é a resposta.** Renomeação e exclusão atômicas de
diretórios, listas em cada diretório e o endpoint do Data Lake, contra o qual o Spark, o Synapse e o
Databricks são construídos. Um lake em que os motores de análise escrevem sem ele paga o custo de
copiar e apagar visto antes nesta lição a cada commit de job, e corre o risco do diretório escrito pela
metade a cada falha.

**Para os arquivos de uma aplicação, ele compra pouco e pode tirar alguma coisa.** Uma loja que guarda
fotos de produtos, notas fiscais ou a exportação noturna pelo nome exato nunca renomeia um diretório e
nunca precisa de uma lista por pasta. E a Microsoft mantém uma tabela de recursos do Blob Storage por
tipo de conta, porque alguns recursos chegaram mais tarde, ou com limites, às contas com espaço de
nomes hierárquico. Vários dos recursos de proteção da lição 5 já estiveram nessa tabela. Leia a tabela
atual para cada recurso de que um desenho depende antes de ligar o espaço de nomes, porque depois
disso um recurso que falta não pode ser obtido na mesma conta.

**A conversão de uma conta existente é de mão única e tem pré-requisitos.** A documentação da
Microsoft descreve uma etapa de validação que procura na conta recursos incompatíveis com o espaço de
nomes e se recusa a converter até eles saírem. É uma migração com plano, não uma caixa de seleção.

## As duas contas da Quitanda

| conta | espaço de nomes | guarda | por quê |
|---|---|---|---|
| `stquitandadataprd` | plano | as exportações noturnas da loja, arquivos lidos pelo nome exato | a conta da lição 1; precisa de todos os recursos de proteção da lição 5 |
| `stquitandalakeprd` | hierárquico | `raw/`, `curated/`, `clicks/` e as tabelas dos analistas | os motores confirmam renomeando diretórios, e o acesso muda por diretório |

As exportações viajam da primeira conta para a segunda toda noite, numa cópia que a Quitanda paga uma
vez por arquivo. Sai mais barato do que pagar pelo espaço de nomes errado em cada operação, numa
direção ou na outra.

## Como saber qual você tem

No Azure, as propriedades da conta dizem: `az storage account show` imprime `isHnsEnabled`, true ou
false, e o endpoint do Data Lake só responde quando é true. Esse comando pergunta ao Azure Resource
Manager, o plano de controle, então aqui ele termina onde o `show-connection-string` da lição 1
terminou:

```
ana@laptop:~/azure$ az storage account show -n stquitandalakeprd --query isHnsEnabled 2>&1 | tail -1
ERROR: Please run 'az login' to setup account.
```

No laboratório a resposta é sempre a mesma: a conta do Azurite é plana, e toda renomeação deste curso
que não é no Azure é uma cópia e uma exclusão.
