---
title: Kustomize ou Helm
version: 1
---

**As duas ferramentas respondem perguntas diferentes, e a maioria dos repositórios de verdade usa as
duas.**

| | Kustomize | Helm |
|---|---|---|
| parte de | manifestos simples, válidos sozinhos | templates, válidos só depois de gerados |
| um ambiente é | um overlay: o que é diferente | um arquivo de valores: as respostas às perguntas do chart |
| serve para | as suas aplicações, um punhado de ambientes | software que você instala e não escreveu, muitas configurações |
| o que quem revisa lê | o overlay, e a saída do `kubectl kustomize` | os valores, e a saída do `helm template` |
| empacotamento | nenhum: uma pasta | um chart com versão, publicado num repositório ou registry |
| o release | nenhum: objetos no cluster | um release do Helm com histórico, no cluster |

**Use o Kustomize para o que você escreve**, porque uma base que é YAML simples é algo que todo mundo
do time consegue ler, e um overlay que lista diferenças é a descrição mais barata possível de um
ambiente. **Use o Helm para o que você instala**, porque o autor do chart já respondeu as centenas de
perguntas que você teria de responder, e um arquivo de valores é uma coisa muito menor de cuidar do que
os manifestos dele. Quando um chart de terceiros precisa de uma mudança para a qual não oferece valor,
o Kustomize pode aplicar um patch na saída do Helm depois de gerada, o que tanto os `postRenderers` do
Flux quanto a integração do Argo CD com o Kustomize suportam.

## Gerar no agente, ou no Git

O Flux e o Argo CD geram overlays e charts dentro do cluster, a cada reconciliação, e o Git guarda só
as fontes. Alguns times geram no CI e commitam o resultado, manifestos simples, numa pasta ou branch
separada que o agente aplica. A troca é a que a aula 2 citou: a saída gerada é exatamente o que vai ser
aplicado e quem revisa consegue lê-la, ao custo de uma segunda cópia de tudo, que pode discordar da
fonte. **Gerar no agente é o padrão por um bom motivo**; gere no CI quando alguém ler os manifestos
finais valer essa segunda cópia.
