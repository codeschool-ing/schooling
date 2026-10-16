---
title: O que faz de algo um serviço
version: 1
---

O tamanho é a leitura errada comum: um microsserviço é tido como um programa pequeno, e dividir um
sistema em muitos programas pequenos é tido como a arquitetura. **O que define um serviço é a
independência**, e um programa grande pode tê-la enquanto um pequeno não tem.

James Lewis e Martin Fowler escreveram a descrição que a maioria das pessoas cita, em 2014. Lida
pelo que um serviço precisa conseguir fazer, ela se resume a quatro propriedades:

| propriedade | o que significa na prática |
| --- | --- |
| **implantável de forma independente** | uma versão nova sai sem nenhum outro serviço ser reconstruído, reimplantado ou sequer avisado |
| **organizado em torno de uma capacidade de negócio** | faz uma coisa que o negócio reconheceria, como estoque, pagamentos ou entrega, em vez de uma camada técnica como "a camada de banco" |
| **dono dos seus dados** | as tabelas são dele, e nenhum outro serviço as lê; os outros perguntam a ele |
| **pontas inteligentes, canos burros** | a lógica está nos serviços; o que os liga, HTTP ou uma fila, carrega mensagens e não toma decisões |

A primeira é a que as outras servem. **Se dois serviços sempre precisam ser implantados juntos, eles
são um serviço com uma rede no meio**, e a última seção desta aula tem um nome para isso.

## De onde veio a palavra, em resumo

Dividir sistemas em componentes ligados pela rede é bem mais antigo do que a palavra. A aula 3
trata da arquitetura orientada a serviços, que fez boa parte disso nos anos 2000 com maquinário mais
pesado. O que os anos 2010 acrescentaram foi automação barata: contêineres, pipelines de implantação
e máquinas na nuvem tornaram viável rodar dezenas de unidades implantáveis pequenas, e as empresas
que fizeram isso em público, Netflix e Amazon entre elas, descreveram o resultado. O custo de rodar
cada unidade caiu; o custo da rede entre elas, não.

## O que isso compra

Cada propriedade compra algo específico, e cada uma tem um preço que o resto da aula mede:

| compra | e paga com |
| --- | --- |
| equipes que lançam sem esperar umas pelas outras | uma chamada de rede onde antes havia uma chamada de função |
| escalar uma parte com o seu próprio número de cópias | um segundo banco, e nenhuma transação entre os dois |
| uma falha num serviço que não mata os outros | tipos novos de falha: o outro serviço lento, fora do ar, ou pela metade |
| cada serviço na linguagem e na versão de que precisa | mais um pipeline, imagem, painel e alerta por serviço |

A Quitanda tem uma força da aula 1 forte o bastante: suponha que a equipe de estoque, duas pessoas
que também cuidam do depósito, quer lançar no próprio ritmo, várias vezes por dia, sem esperar a
release da loja. Essa é a força. As duas próximas seções desenham a fronteira e tiram o estoque.
