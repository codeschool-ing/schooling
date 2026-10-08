---
title: Uma revisão de projeto que olha a mudança
version: 1
---

Uma revisão de projeto é onde uma mudança que mexe no modelo é modelada. A diferença entre uma que
mantém o modelo vivo e uma que não mantém é o que ela olha: **a mudança, não o sistema**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 170\" role=\"img\" data-fig=\"l15-review\" aria-label=\"Uma revisão de projeto em quatro passos. A mudança é mostrada como uma diferença no DFD. O STRIDE é aplicado aos elementos e fluxos que mudaram, não ao sistema inteiro. As ameaças e requisitos que resultam são escritos no modelo. A mudança do modelo e a do código vão no mesmo pull request.\"><defs><marker id=\"l15-review-tm-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"40.0\" width=\"150.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"95.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">a mudança, como diff de DFD</text><path d=\"M170.0 70.0 L195.0 70.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-review-tm-ah-paper-dim)\"></path><rect x=\"195.0\" y=\"40.0\" width=\"150.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"270.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">STRIDE no que mudou</text><path d=\"M345.0 70.0 L370.0 70.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-review-tm-ah-paper-dim)\"></path><rect x=\"370.0\" y=\"40.0\" width=\"150.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"445.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">ameaças e requisitos</text><path d=\"M520.0 70.0 L545.0 70.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-review-tm-ah-paper-dim)\"></path><rect x=\"545.0\" y=\"40.0\" width=\"150.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"620.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">um pull request</text><text x=\"360.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">trinta minutos, as pessoas que vão construir, e o modelo aberto na tela</text></svg>", "caption": "Uma revisão que só olha o que mudou é curta o bastante para acontecer toda vez, que é a única frequência que mantém um modelo vivo."}
```

### Quatro passos

1. **A mudança, como uma diferença no DFD.** A história da nota fiscal acrescenta uma entidade
   externa, o serviço de nota da prefeitura, e três fluxos: o portal pede uma nota, o serviço a
   devolve, o paciente a baixa. Desenhadas no diagrama de nível 1, as partes novas são tudo o que
   alguém precisa olhar. O `model.py` ganha os mesmos acréscimos, então o diff que os revisores leem
   é o diff que vai entrar no commit.
2. **STRIDE no que mudou.** Cada elemento e fluxo novo recebe as seis perguntas da aula 3, e só
   eles. O fluxo novo para o serviço da prefeitura atravessa a fronteira dos fornecedores:
   falsificação (é mesmo a prefeitura?), adulteração (o valor pode ser alterado no caminho?),
   vazamento de informação (o que o serviço guarda sobre os pacientes da Vereda?).
3. **Ameaças e requisitos.** O que as perguntas acham é escrito em `threats.csv` e `requirements.csv`
   com ids novos, e estimado se for grande o bastante para disputar dinheiro com o resto. Uma ameaça
   que a equipe decide aceitar ganha um registro de decisão, como na aula 12.
4. **Um pull request.** As mudanças do modelo vão no mesmo pull request que o código. Quem aprova o
   código vê as ameaças ao lado, e **o modelo não consegue ficar atrás do código que descreve**,
   porque os dois entram juntos ou não entram.

### Quem, e por quanto tempo

As pessoas que vão construir a mudança, a ana com o modelo aberto, e a carla quando a mudança
atravessa uma fronteira de confiança. Trinta minutos costumam bastar, porque o escopo é um punhado de
elementos. Uma revisão que precisa de duas horas é sinal de que a mudança é maior que uma história,
o que vale saber por si só.

### O que ela pega que o refinamento não pega

O refinamento pergunta se uma história mexe no modelo. A revisão pergunta **o que pode dar errado no
que ela mexe**, elemento por elemento, e é onde um requisito é escrito com precisão suficiente para
ser testado. "Só o paciente que pagou recebe a nota" é uma frase de refinamento. "O portal devolve
uma nota só à conta que pagou a sessão, e responde a qualquer outro pedido como se a nota não
existisse" é um requisito, com a mesma forma do R10, e dá para escrever um teste contra ele.

### O mínimo que ainda é uma revisão

Quando uma equipe está ocupada demais para qualquer coisa, uma regra mantém o hábito: **um pull
request que muda uma entrada, um repositório de dados ou uma fronteira precisa mudar o modelo também,
ou dizer na descrição por que não.** É barato de conferir na revisão e barato de seguir. Um revisor
que vê uma rota de upload nova e nenhuma mudança no `model.py` faz uma pergunta, e essa pergunta é a
maior parte do que uma revisão de projeto existe para fazer.
