---
title: A descrição
version: 1
---

Um pull request tem uma descrição, e num projeto de portfólio ela é uma das coisas mais lidas do
repositório: quem abre a aba de *pull requests* lê descrições antes de diffs. Quatro partes curtas
resolvem:

```localised
Diz o que fazer quando não há nada para emprestar

O quê: quando a lista está vazia, a página diz isso e diz como cadastrar equipamento,
em vez de mostrar uma tabela só com o cabeçalho.

Por quê: na primeira vez que a Marta abriu no servidor, antes de qualquer cadastro,
achou que a página estava quebrada (#6).

Como conferi: abri com o banco vazio e com os dados de exemplo; a mensagem aparece
no primeiro caso e não no segundo. Sem teste: é marcação e uma linha de JavaScript.

Fora desta mudança: a tabela monta as linhas com innerHTML, então o nome de quem pega
emprestado é desenhado como marcação. Isso é anterior a esta mudança; abri a #7 para ele.

Closes #6
```

**O quê** é a mudança em uma ou duas frases, do lado de quem usa. **Por quê** é o motivo, de preferência
algo que aconteceu. **Como conferi** é a parte que as pessoas pulam e quem revisa mais valoriza: diz o que
você rodou e olhou e, tão importante quanto, o que você decidiu não testar e por quê. **Fora desta
mudança** é onde vai o problema encontrado na revisão, com o número do cartão, para ficar registrado sem
ser corrigido aqui.

Para uma mudança na interface, uma captura de tela, antes e depois, poupa quem revisa de rodar qualquer
coisa.

Abra o pull request mesmo que você mesmo vá fazer o merge. Custa um minuto, roda as verificações que o
repositório tiver, aula 12, e deixa a descrição onde o próximo leitor vai encontrá-la.
