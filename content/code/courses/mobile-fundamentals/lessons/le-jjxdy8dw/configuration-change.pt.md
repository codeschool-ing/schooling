---
title: A rotação no Android, e o outro jeito de perder uma tela
version: 1
---

**No Android o processo não é a única coisa que o sistema tira: girar o celular destrói a Activity e
constrói uma nova, com o processo ainda vivo.** Isso surpreende a maioria das pessoas que o encontram, porque nada
em girar um celular soa como um fim. Chama-se mudança de configuração, e é o motivo de quem
desenvolve para Android encontrar estado perdido na primeira tarde, e não depois de uma semana em
produção.

## O que acontece quando o celular gira

O guia de Activity do Android diz que, quando ocorre uma mudança de configuração, como uma rotação ou
a entrada no modo de várias janelas, o sistema destrói a Activity por padrão, e então cria uma
instância nova na configuração nova e chama `onCreate` nela. Tudo o que estava nos campos da
instância antiga vai junto. O `onDestroy` da aula 4 roda desta vez, porque é o próprio sistema que
está reconstruindo; o processo, e tudo fora da Activity, sobrevive.

**Então o Android tem dois jeitos de perder estado de UI, com dois remédios diferentes.**

| o que aconteceu | o processo | a Activity | o que o usuário vê sem remédio |
|---|---|---|---|
| o celular girou | vivo | destruída e reconstruída na hora | o formulário se esvazia enquanto a tela gira |
| o app foi morto em segundo plano | foi embora | foi embora | o formulário está vazio quando ele volta |

**O iOS não tem equivalente da primeira linha.** Girar um iPhone avisa às views que o tamanho delas
mudou, e elas se reorganizam; nada é destruído. Um app React Native roda numa única Activity Android
que o template configura para tratar essas mudanças sozinha, então o JavaScript continua rodando
durante uma rotação. Nesses dois, só a segunda linha é um perigo. A aula 8 trata do que uma tela
girada faz com um layout; esta etapa trata só do que ela faz com o estado.

## Memória que sobrevive a uma rotação, e memória que não sobrevive

O guia do Android sobre salvar estado de UI compara as três opções exatamente nessas duas linhas, e
vale ter a tabela inteira:

| opção | onde fica guardada | sobrevive a uma mudança de configuração | sobrevive ao sistema matar o processo | sobrevive ao usuário fechar a tela |
|---|---|---|---|---|
| ViewModel | na memória | sim | não | não |
| estado salvo | serializado, guardado pelo sistema | sim | sim | não |
| armazenamento persistente | no disco ou na rede | sim | sim | sim |

**Um ViewModel é o remédio para a rotação, e não para a morte.** É um objeto que o Android mantém na
memória durante a reconstrução e entrega à Activity nova, para que uma lista carregada da rede não
carregue de novo só porque o celular girou. Mas o guia é explícito: ViewModels são destruídos numa
morte de processo iniciada pelo sistema. Ele vive no processo, e o processo é o que a morte leva.

**O estado salvo é o remédio para as duas coisas**, a um preço. O guia o descreve como limitado a
tipos primitivos e objetos simples e pequenos, como String, lento para gravar porque é serializado, e
mantido pelo sistema fora do seu processo. É assim que ele sobrevive à morte: nunca esteve dentro do
processo que morreu. É também por isso que o conselho do próprio guia é guardar nele a quantidade
mínima de dados necessária, como um ID. A última etapa desta aula mede o que acontece quando esse
conselho é ignorado.

**Armazenamento persistente é para dados**, a primeira linha da tabela da etapa anterior, e sobrevive
até ao usuário fechar a tela de propósito, o que o estado de UI não deve fazer.

## Uma rotação é um teste de graça

**Todo desenvolvedor Android tem na mão um ensaio de morte de processo.** Uma rotação reconstrói a
Activity do mesmo jeito que um lançamento depois de uma morte, então um app que mantém o formulário
durante um giro pelo menos escreveu o caminho de restauração. Ele não provou o caminho de salvamento,
porque um ViewModel aguenta uma rotação sozinho. A morte precisa ser testada à parte, e o programa da
ida e volta desta aula faz exatamente isso, sem celular.
