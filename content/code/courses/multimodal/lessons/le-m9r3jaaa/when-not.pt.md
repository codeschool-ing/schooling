---
title: Quando um modelo multimodal é a ferramenta errada
version: 1
---

O erro mais caro deste campo é usar um modelo para recuperar uma informação que sempre esteve disponível numa forma mais barata e exata. Antes de recorrer a qualquer modelo deste curso, procure estes casos.

**O dado já existe como dado.** Um PDF gerado por software de contabilidade tem uma camada de texto: os caracteres estão no arquivo, e uma biblioteca os lê com exatidão, de graça, em milissegundos. Passá-lo por OCR ou por um modelo de visão relê a imagem de um texto que já era texto, e acrescenta erros. O mesmo vale para uma nota que chega como arquivo XML (no Brasil a nota fiscal eletrônica, a NF-e, é exatamente isso), um formulário cujos campos são campos, e um código de barras, que um leitor lê sem dúvida nenhuma.

**Uma regra resolveria.** Se a tarefa é "esta imagem tem mais de 5 MB" ou "esta gravação passa de dez minutos", o ffprobe responde. O programa de inventário da aula 1 fez isso para cada arquivo do laboratório sem modelo nenhum.

**A resposta precisa ser exata e ninguém vai conferir.** Um modelo que lança totais de notas fiscais num sistema contábil sem ninguém olhando vai, um dia, escrever 2 onde a página diz 12 (a aula 2 mostra exatamente essa leitura errada). Onde um valor errado sai caro, a saída do modelo é um rascunho para uma pessoa, ou é conferida contra outra coisa: os valores das linhas têm de somar o total, o número do pedido tem de existir.

**O dado é o corpo ou a identidade de alguém.** Um rosto, uma voz e uma impressão digital podem identificar uma pessoa. Pela LGPD, dado biométrico é dado pessoal sensível, com bases mais estritas para tratá-lo. Mandar a fotografia de um cliente para a API de um terceiro é uma transferência dos dados dele, e a política de privacidade tem de dizer isso. A aula 8 mostra o menor passo, tirar os metadados de uma fotografia antes que ela saia.

**Cada tentativa custa dinheiro e o usuário vai tentar de novo.** Uma chamada a um modelo de texto custa frações de centavo. Gerar uma imagem ou ouvir uma hora de áudio custa muito mais, e a aula 13 põe números nisso. Um recurso que convida as pessoas a apertar "tentar de novo" multiplica esse custo pelo número de apertos.

Nenhum desses é motivo para fugir do campo. Cada um é uma pergunta a responder antes de escrever a primeira linha, e uma resposta honesta às vezes será "modelo nenhum".
