---
title: Dependências
version: 1
---

O DFD mostra o portal como um círculo, e o círculo esconde a maior parte do que está rodando. O
portal é código da Vereda em cima de um framework web, uma biblioteca de PDF, a biblioteca cliente
do gateway de pagamento e tudo o que elas importam, rodando nas máquinas de um provedor de nuvem,
respondendo a um nome que um provedor de DNS publica, construído por um serviço de CI a partir de um
host de git, com pacotes baixados de registros públicos. **Cada um deles roda com a confiança do
portal**, e um erro em qualquer um é uma porta de entrada que a Vereda nunca escreveu.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l06-dependencies\" aria-label=\"Quatro anéis do que o portal depende. Código que a Vereda escreveu: o portal, o console, o worker. Código que a Vereda importa: um framework web, uma biblioteca de PDF, a biblioteca cliente do gateway, e tudo o que essas importam por sua vez. Serviços que a Vereda chama: o provedor de nuvem, o DNS, o provedor de SMS, o gateway de pagamento. E o que constrói e entrega: o host do git, o executor de CI, os registros de pacotes.\"><defs><marker id=\"l06-dependencies-tm-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"40.0\" width=\"160.0\" height=\"120.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"100.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">o que a Vereda escreveu</text><text x=\"100.0\" y=\"95.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">o portal,</text><text x=\"100.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">o console,</text><text x=\"100.0\" y=\"120.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">o worker</text><path d=\"M180.0 100.0 L192.0 100.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-dependencies-tm-ah-paper-dim)\"></path><rect x=\"192.0\" y=\"40.0\" width=\"160.0\" height=\"120.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"272.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">o que ela importa</text><text x=\"272.0\" y=\"89.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">um framework web,</text><text x=\"272.0\" y=\"101.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">uma biblioteca de PDF,</text><text x=\"272.0\" y=\"114.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">o cliente do gateway,</text><text x=\"272.0\" y=\"126.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">e o que eles importam</text><path d=\"M352.0 100.0 L364.0 100.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-dependencies-tm-ah-paper-dim)\"></path><rect x=\"364.0\" y=\"40.0\" width=\"160.0\" height=\"120.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"444.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">o que ela chama</text><text x=\"444.0\" y=\"95.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">o provedor de nuvem,</text><text x=\"444.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">o DNS, o provedor de SMS,</text><text x=\"444.0\" y=\"120.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">o gateway de pagamento</text><path d=\"M524.0 100.0 L536.0 100.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-dependencies-tm-ah-paper-dim)\"></path><rect x=\"536.0\" y=\"40.0\" width=\"160.0\" height=\"120.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"616.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">o que constrói e entrega</text><text x=\"616.0\" y=\"95.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">o host do git,</text><text x=\"616.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">o executor de CI,</text><text x=\"616.0\" y=\"120.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">registros de pacotes</text><text x=\"360.0\" y=\"195.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Cada anel roda com a confiança do anterior, e você revisou só o primeiro.</text><text x=\"360.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">Só este ambiente: 1 pacote instalado de propósito, mais 5 que vieram junto.</text></svg>", "caption": "A superfície inclui tudo o que roda com a sua confiança. A maior parte disso você não escreveu."}
```

### O tamanho disso

O ambiente da aula 1 é um bom exemplo pequeno. Um pacote foi instalado de propósito:

```
(.venv) ana@vm:~/tm$ pip list
Package           Version
----------------- -------
annotated-types   0.8.0
pip               26.2.1
pydantic          2.13.5
pydantic_core     2.46.5
pytm              1.4.0
typing_extensions 4.16.0
typing-inspection 0.4.4
```

O pytm, mais cinco pacotes que vieram com ele, mais o próprio pip. Nenhum dos cinco foi escolhido
por alguém da Vereda, e cada um roda com as mesmas permissões do modelo. Numa aplicação web a mesma
proporção é típica e os números são maiores: um framework traz dezenas de pacotes, e cada um deles
traz os seus.

### O que o mapa registra para cada dependência

Um modelo de ameaças não lista cada pacote transitivo; isso é uma lista de materiais de software
(SBOM), e o curso `secure-pipeline` (aula 13) gera uma automaticamente. O que o modelo registra são
as dependências que **ficam num ponto de entrada ou guardam um segredo**, porque são aquelas cuja
falha é uma ameaça a este projeto:

| dependência | por que está no mapa | a pergunta que levanta |
|---|---|---|
| a biblioteca de PDF do console | interpreta arquivos que pacientes enviam | o que acontece quando ela encontra um arquivo malformado? (T14) |
| a biblioteca cliente do gateway | guarda a chave da API e monta toda cobrança | quem a atualiza, e quão rápido depois de uma correção? |
| o provedor de SMS | recebe um telefone e uma mensagem a cada agendamento | o que o contrato dele diz sobre guardá-los? |
| a conta de nuvem | guarda todas as máquinas e todos os segredos | quem tem o papel de dono, e com que segundo fator? |
| o serviço de CI | consegue publicar qualquer coisa em produção | quais branches do repositório podem disparar um deploy? |

### Serviços também são pontos de entrada

O gateway de pagamento está desenhado como entidade externa, mas a Vereda também depende dele: se os
servidores dele forem comprometidos, o webhook leva o que o atacante quiser, assinado com uma chave
válida. O modelo não tem como corrigir isso. Consegue garantir que a dependência esteja anotada, que
o contrato com o gateway diga quem avisa quem depois de um incidente, e que o portal confira o que
uma assinatura não confere: que o valor pago bate com o agendamento. A aula 8 transforma essa frase
num requisito.
