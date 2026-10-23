---
title: Assinaturas de hash: exatas, e de um arquivo só
version: 1
---

**Uma assinatura de hash casa com um arquivo e com mais nenhum.** Um hash criptográfico como o SHA-256
é uma impressão digital de cada byte: dois arquivos com o mesmo hash são o mesmo arquivo, e mudar um
único byte muda o hash a ponto de ficar irreconhecível. Uma assinatura feita de um hash, portanto,
nunca confunde um arquivo diferente com o que descreve, e também nunca reconhece uma variante dele.

Faça uma para a primeira amostra, com um nome seu:

```
ana@desk:~$ sigtool --sha256 samples/invoice.txt | sed "s/:invoice.txt$/:Jatoba.Lab.Invoice/" > lab.hsb; cat lab.hsb
0cad6ef09fcc2504e6df0bd0c8da112c9ba39df42a87d6b5f86f071e28140e72:34:Jatoba.Lab.Invoice
ana@desk:~$ clamscan --no-summary -d lab.hsb samples/; echo "exit $?"
samples/copy.txt: Jatoba.Lab.Invoice.UNOFFICIAL FOUND
samples/changed.txt: OK
samples/invoice.txt: Jatoba.Lab.Invoice.UNOFFICIAL FOUND
exit 1
```

O original e a cópia exata são achados. O `changed.txt`, que difere por um espaço, está `OK`. O scanner
está certo nos três casos: perguntaram a ele se estes arquivos são *aquele* arquivo, e um deles não é.

## Por que os fabricantes ainda distribuem milhões delas

Assinaturas de hash são baratas de fazer, baratas de conferir e nunca dão falso positivo, então um
fabricante acrescenta uma para cada arquivo que os analistas confirmam. São o jeito de um scanner
reconhecer as milhares de cópias de um arquivo circulando ao mesmo tempo: o anexo de uma campanha, o
instalador numa página de download falsa.

O limite delas é o outro lado da mesma propriedade. **Um hash descreve o passado.** Um arquivo que
difere de todos os conhecidos em qualquer byte, seja porque foi refeito, reempacotado ou simplesmente
atualizado pelo autor, não casa com hash nenhum. A defesa contra isso não é um hash melhor. São as
assinaturas de conteúdo e as heurísticas das próximas duas seções e, atrás delas, o EDR da aula 8,
que observa o que um programa faz em vez do que ele é.

## Hashes também são como se pergunta

Um hash é a primeira coisa que quem defende anota sobre um arquivo suspeito. Ele identifica o arquivo
sem compartilhá-lo, então pode ser comparado com as listas da própria organização, buscado em fontes
de inteligência de ameaças e consultado em serviços online sem enviar nada. A aula 19 trata desses
serviços e de por que a consulta de um hash vem antes de um envio.
