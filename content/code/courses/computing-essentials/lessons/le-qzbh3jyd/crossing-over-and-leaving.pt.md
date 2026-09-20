---
title: Atravessar, e a questão do que é seu
version: 1
---

A maioria das pessoas trabalha nas duas suítes, normalmente porque outra pessoa escolheu a outra.
Três coisas valem saber antes de um documento atravessar.

## Editar arquivos do Office sem converter

O Drive abre um `.docx` e o edita **no lugar**, mantendo como `.docx`. Isso é o *modo de edição do
Office*, e é a resposta certa sempre que o arquivo tiver de voltar para alguém no Word.

O custo é que os recursos exclusivos do Google ficam indisponíveis, porque não há onde guardá-los
dentro do formato `.docx`. Você ganha a colaboração e não ganha o menu do `@`.

A alternativa — *Arquivo, Salvar como Documentos Google* — converte, libera tudo, e produz um
documento que não é mais o arquivo que alguém te mandou. As duas estão certas; o erro é não saber
qual das duas você fez.

## O que quebra em cada sentido

| | normalmente sobrevive | normalmente se desloca |
|---|---|---|
| **Docs → Word** | texto, títulos, listas, tabelas, imagens, comentários | espaçamento preciso, algumas bordas, quebras de página em documentos longos |
| **Word → Docs** | o mesmo | cabeçalhos por seção, campos, macros, SmartArt |
| **Sheets → Excel** | valores, a maioria das fórmulas, formatação | `QUERY`, `IMPORTRANGE`, `ARRAYFORMULA`, qualquer coisa do Apps Script |
| **Slides → PowerPoint** | layout, texto, imagens | fontes, algumas transições, gráficos vinculados |

**A linha para planejar em torno é a terceira.** Uma planilha construída sobre `QUERY` e
`IMPORTRANGE` não vira uma pasta de trabalho do Excel; vira uma pasta de trabalho do Excel cheia
de `#NOME?`. Se a planilha um dia vai ter de sair, construa com funções que os dois entendem.

## O Takeout, e como é um backup disso

O `takeout.google.com` exporta tudo da conta — Drive, e-mail, fotos, agenda — como um conjunto de
arquivos compactados. Documentos saem como `.docx`, `.xlsx` e `.pptx`, ou como PDFs, escolhido na
hora da exportação.

Duas coisas nele importam:

- **É um instantâneo, não uma sincronia.** Precisa ser rodado de novo para estar atual, e dá para
  agendar a cada dois meses, que é o mais perto de automático disponível.
- **A exportação é uma tradução**, com tudo o que a tabela acima diz. Uma `QUERY` não sobrevive; o
  que sai são os valores que ela produziu no momento da exportação.

## E o argumento da aula oito, aplicado aqui

Um Google Doc é **uma cópia que você não tem**. A conta pode ser suspensa, o serviço pode mudar os
termos, e um documento apagado pelo dono desaparece para todos com quem foi compartilhado. Nenhuma
dessas é provável e todas já aconteceram com alguém.

Então as mesmas três frases valem, sem mudança:

- **um formato simples** — a exportação, como `.docx` ou PDF, de qualquer coisa que doeria perder;
- **uma cópia que não muda quando o original muda** — que a exportação é, por construção;
- **uma delas em outro lugar** — uma pasta na máquina que você copiou na aula oito.

Duas vezes por ano, para a dúzia de documentos que importam, basta. Não é crítica ao serviço; é o
que *você tem uma cópia* significa quando a coisa está no computador de outra pessoa.
