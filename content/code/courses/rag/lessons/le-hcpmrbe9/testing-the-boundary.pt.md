---
title: Testando a fronteira
version: 1
---

Uma permissão que não é testada é uma permissão que funcionou no dia em que foi escrita. O teste desta
é simples de enunciar: **para todo papel, para toda pergunta que temos, nenhuma linha devolvida pode vir
de um público que o papel não pode ler**. O `audit.py` o roda sobre as 36 perguntas do `eval.jsonl` e do
`identifiers.jsonl`, cinco linhas por pergunta, para cada um dos cinco papéis:

```
ana@lab:~/rag$ python audit.py
5 roles x 36 questions, 900 rows returned, 0 outside the role
ana@lab:~/rag$ python audit.py --careless
5 roles x 36 questions, 900 rows returned, 210 outside the role
```

**900 linhas, nenhuma fora do seu papel.** A segunda linha é o mesmo teste rodado contra uma busca
escrita sem o papel, por uma conexão que a política não limita, e ele acha **210** linhas que um leitor
não deveria ter visto. Essa execução não é enfeite: um teste que nunca foi visto falhar pode estar
passando porque não confere nada. Rodá-lo uma vez contra uma busca quebrada prova que ele sabe
distinguir.

O que este teste cobre e o que não cobre:

- **Cobre o caminho do código.** Um papel acrescentado ao `ROLES` com os públicos errados, uma função
  nova que chama outra busca que não o `access.search`, uma mudança no `WHERE`: cada um o faz falhar.
- **Cobre as perguntas que tem.** Trinta e seis perguntas alcançam os documentos que alcançam. Um
  conjunto de sondas escrito para permissões acrescenta perguntas dirigidas a cada documento restrito,
  como a marcação por reembolsos e o limite de fraude, para que todo pedaço restrito seja o melhor
  casamento de pelo menos uma sonda.
- **Não testa a política**, porque o `access.search` filtra no `WHERE` antes de a política ser
  necessária. A política tem o seu próprio teste, o assistente contando linhas sem nada definido e com
  cada público definido, como na seção sobre o banco. Cada camada é testada sozinha, ou uma quebra numa
  fica escondida pela outra.

Rode-o na CI a cada mudança no código, nos papéis ou no acervo. Um documento novo com a linha
`audience:` errada é um vazamento que sai com a próxima reconstrução do índice, e só um teste sobre os
dados indexados o enxerga.
