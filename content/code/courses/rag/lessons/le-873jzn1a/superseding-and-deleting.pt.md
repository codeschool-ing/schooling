---
title: Substituir e apagar
version: 1
---

As aulas 1 e 3 esbarraram o tempo todo no `returns-policy-2025`: o regulamento substituído, recuperado
porque trata exatamente do assunto certo, e citado com confiança. Há dois jeitos de impedir isso, e o
índice tem de permitir os dois, porque eles atendem necessidades diferentes.

## Marcar um documento como substituído

O primeiro mantém o documento e registra que ele não vale mais. O cabeçalho de todo documento tem um
`status`, e todo pedaço o leva. Suponha que a Marginalia troque os termos do vale-presente e marque os
antigos:

```
ana@lab:~/rag$ sed -i "s/^status: current$/status: superseded/" data/docs/gift-cards.md
ana@lab:~/rag$ python ingest.py
chunks: 137  embedded: 0  removed: 0  kept: 137
ana@lab:~/rag$ psql -c "SELECT status, count(*) FROM chunks GROUP BY status"
   status   | count 
------------+-------
 superseded |    12
 current    |   125
(2 rows)
```

**Nada virou embedding, e doze pedaços agora estão substituídos**: os cinco dos termos do vale-presente
e os sete do regulamento de devoluções de 2025, que já vinha marcado assim. O texto não mudou, então
nenhum id mudou e nenhum vetor foi recalculado; o `main` reescreveu os metadados de todos os pedaços, e
o status novo está na tabela.

Marcar mantém o texto antigo disponível para as perguntas que precisam dele. Um atendente tratando uma
reclamação sobre um pedido de 2025 precisa do regulamento de 2025; um auditor perguntando o que os
clientes ouviram no ano passado também. O que a marca faz sozinha é nada: a busca continua devolvendo
pedaços substituídos até uma consulta dizer que não. A aula 14 acrescenta essa condição a toda busca
voltada para clientes, e deixa a busca de um atendente incluir versões antigas de propósito.

## Apagar um documento

O segundo remove o documento de vez. Quando um documento está errado, foi retirado, ou contém dados
pessoais cuja exclusão alguém pediu, ele não deveria ser encontrável por ninguém:

```
ana@lab:~/rag$ rm data/docs/returns-policy-2025.md
ana@lab:~/rag$ python ingest.py
chunks: 130  embedded: 0  removed: 7  kept: 130
ana@lab:~/rag$ psql -tc "SELECT count(*) FROM chunks WHERE doc_id = 'returns-policy-2025'"
     0
```

**Sete pedaços removidos, nenhum restante.** Como o `ingest.py` compara o que os documentos produzem com
o que a tabela tem, apagar o arquivo basta: os ids dele deixam de ser desejados e são apagados na mesma
execução. Nenhum passo separado de exclusão pode ser esquecido.

Essa propriedade é a que a aula 3 usou quando disse que um sistema de recuperação consegue atender a um
pedido de exclusão e um modelo ajustado não. Ela só vale se **o índice for derivado dos documentos e
nada mais escrever nele.** Um pedaço inserido à mão, ou por um segundo programa, não tem documento por
trás, e a próxima execução do `ingest.py` o apaga, porque nenhum documento produz o id dele: a correção
que ele levava some durante a noite, sem ninguém ser avisado. Então a regra para o índice é a que este
repositório aplica ao próprio catálogo: os arquivos são a verdade, um único programa escreve o espelho,
e uma correção é feita no arquivo.

## Qual usar

| | marcar como substituído | apagar |
| --- | --- | --- |
| o texto continua encontrável | por buscas que o peçam | por ninguém |
| a próxima resposta a um cliente | só documentos em vigor, depois que o filtro da aula 14 existir | só documentos em vigor |
| serve para | regulamentos substituídos, versões antigas de termos, o que uma auditoria pode pedir | documentos errados, retirados, dados pessoais sob pedido de exclusão |
| desfeito por | voltar o status | restaurar o arquivo e refazer o embedding |
