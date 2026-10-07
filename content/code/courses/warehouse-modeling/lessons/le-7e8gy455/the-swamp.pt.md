---
title: O pântano
version: 1
---

Um lake que cresce sem regras ganha o nome, sem muito carinho, de **data swamp**, um pântano de dados: muitos
dados, e nenhum jeito de saber em quais confiar. As falhas que produzem um são sempre as mesmas poucas, e cada
uma é algo que um banco de dados resolve por você e uma pasta de arquivos não.

- **Sem transações.** Um job que grava vinte arquivos e morre depois do décimo primeiro deixa onze arquivos na
  pasta, e todo leitor dali em diante vê uma carga parcial como se estivesse completa. Dois jobs gravando a
  mesma pasta ao mesmo tempo podem intercalar seus arquivos sem que ninguém perceba.
- **Sem updates nem deletes.** A lição 8 mostrou que um arquivo Parquet é gravado uma vez e nunca editado.
  Corrigir uma venda significa regravar um arquivo, e remover um cliente que pediu para ser esquecido significa
  achar e regravar cada arquivo que o menciona.
- **Sem imposição de esquema.** A seção anterior: qualquer arquivo de qualquer formato pode cair em qualquer
  lugar.
- **Sem histórico.** Sobrescreva um arquivo e a versão antiga se foi; não há como perguntar como a pasta estava
  ontem, quando o relatório da semana passada rodou.
- **O problema dos arquivos pequenos.** Um fluxo que grava um arquivo por minuto faz meio milhão de arquivos por
  ano, e abrir um arquivo tem um custo fixo por menos que ele contenha. A lição 7 encontrou isso como partições
  finas demais.
- **Ninguém sabe o que tem lá.** Sem um catálogo, assunto da lição 12, uma pasta chamada `orders_v2_final` é uma
  pergunta e não uma resposta.

Nenhuma delas tem a ver com o formato dos arquivos, que quase sempre é Parquet e vai bem. **Todas vêm da
falta de uma camada acima dos arquivos que diga quais arquivos formam a tabela agora.** Essa camada é a próxima
seção.
