---
title: Alterar um servidor, ou substituí-lo
version: 1
---

Declarar o que deveria existir resolve o *quê*. Deixa em aberto *como* uma coisa em execução vai do
que é ao que deveria ser, e há duas respostas com consequências bem diferentes.

**Infraestrutura mutável altera as coisas no lugar.** Uma versão nova do servidor web da loja
significa entrar em cada máquina (ou deixar uma ferramenta entrar) e atualizar o pacote, editar o
arquivo, reiniciar o serviço. A máquina mantém o nome, o endereço e o disco, e carrega o histórico de
cada mudança que já recebeu. Foi assim que quase todo servidor foi operado por décadas, e foi assim
que as ferramentas de gerência de configuração começaram.

**Infraestrutura imutável nunca altera algo em execução.** Uma versão nova significa uma máquina
nova, construída do zero já com a versão nova, colocada em serviço, e a antiga destruída. Nada é
editado, então nada consegue derivar: uma máquina é exatamente o que foi construída para ser, até o
dia em que é jogada fora.

| | mutável | imutável |
|---|---|---|
| uma mudança é | uma edição no que está rodando | uma cópia nova, e depois a troca |
| drift | se acumula em cada máquina | não tem onde morar |
| voltar atrás | desfazer a edição, se alguém souber qual foi | ligar de novo a cópia anterior |
| o que exige | acesso às máquinas em execução | um jeito rápido de construí-las e trocá-las |
| o que custa | nada de saída | uma etapa de build, e um desenho em que perder uma máquina não é problema |

A segunda coluna é o motivo pelo qual os planos do Terraform, da aula 2 em diante, mostram algumas
mudanças como atualização e outras como **substituição** (*replace*): para muitos atributos a
própria nuvem não oferece edição, e o único jeito de mudá-los é um recurso novo. A imagem de uma
máquina é um deles. A aula 6 trata de controlar essa escolha, e a aula 20 de construir as imagens
que fazem da substituição o jeito normal de trabalhar.

**Nenhuma das colunas é virtude por si só.** Um banco de dados é a coisa mutável mais clara que
existe, porque todo o valor dele são os dados que se acumularam ali. O arranjo comum mantém o
estado em poucos lugares cuidados com atenção (um banco, um bucket) e torna substituível tudo o que
fica em volta. A troca tem apelido, *pets and cattle*, bichos de estimação e gado: um pet tem nome e
é tratado até sarar; o gado é numerado, e um animal doente é substituído. A pergunta para qualquer
máquina de que você cuida é qual dos dois ela deveria ser, e se é isso que ela é.
