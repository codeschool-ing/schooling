---
title: Integridade que dá para verificar
version: 1
---

**Integridade é a propriedade que as pessoas esquecem, porque um arquivo alterado tem exatamente a
mesma cara de um correto.** Uma lista de clientes vazada vira notícia. Um preço que escorregou de
R$ 45,90 para R$ 4,59 fica no catálogo com cara de normal até alguém notar que a loja está
vendendo no prejuízo há uma semana.

Então a pergunta da integridade não é só "alguém consegue mudar isto?", mas "**nós saberíamos se
tivessem mudado?**". Esta seção responde à segunda metade num arquivo de verdade.

Você não precisa digitar nada do que vem a seguir. Toda transcrição deste curso foi gravada no
laboratório do curso, uma cópia pequena da rede da livraria montada num único computador Linux, e
o texto diz o que cada comando faz. Uma linha que começa com `ana@laptop:~$` é a ana, que cuida da
TI da loja, digitando no notebook do escritório; tudo o que vem embaixo é o que o computador
respondeu.

Aqui está a lista de preços, e uma impressão digital dela:

```
ana@laptop:~$ cat prices.csv
isbn,title,price_cents
9788535914849,Dom Casmurro,4590
9788525432186,Vidas Secas,3990
9788520932964,Grande Sertao: Veredas,8990
ana@laptop:~$ sha256sum prices.csv > prices.sha256
ana@laptop:~$ cat prices.sha256
6fff9e30ac0f27672ff735d4a415423a48b67ae5db16e473f1e3bf341064c11d  prices.csv
ana@laptop:~$ sha256sum -c prices.sha256
prices.csv: OK
```

O `sha256sum` lê o arquivo inteiro e calcula um **hash SHA-256**: 64 caracteres hexadecimais que
dependem de cada byte da entrada. O mesmo arquivo sempre dá o mesmo hash, e qualquer mudança dá
um hash diferente. A ana guardou o hash em `prices.sha256`, e o `sha256sum -c` lê esse arquivo,
calcula o hash de novo e compara. `OK` quer dizer que o arquivo é, byte a byte, o que era.

Agora um caractere muda. Na vida real seria uma edição errada, uma importação com defeito ou
alguém adulterando; aqui é um comando que tira um zero:

```
ana@laptop:~$ sed -i 's/,4590/,459/' prices.csv
ana@laptop:~$ cat prices.csv
isbn,title,price_cents
9788535914849,Dom Casmurro,459
9788525432186,Vidas Secas,3990
9788520932964,Grande Sertao: Veredas,8990
ana@laptop:~$ sha256sum -c prices.sha256
prices.csv: FAILED
sha256sum: WARNING: 1 computed checksum did NOT match
ana@laptop:~$ sha256sum prices.csv
350f6313295d12dcfa2bd78f2908d1becd87f2360fccf9e6ae3fc7ffc2f2880a  prices.csv
```

**Um caractere, e a verificação diz `FAILED`.** O hash novo, `350f6313…`, não tem nada visível em
comum com o antigo, `6fff9e30…`. Essa é uma propriedade de projeto de uma boa função de hash: uma
mudança pequena na entrada embaralha a saída inteira, então ninguém consegue fazer um arquivo
"quase igual" que passe. A aula 4 de `cryptography` explica como se chega a isso e por que MD5 e
SHA-1 não servem mais.

Dois limites importam tanto quanto o resultado:

- **Um hash diz QUE algo mudou, nunca O QUÊ nem QUEM.** A verificação acima não aponta a linha 2 e
  não diz que a mudança foi maliciosa. Descobrir isso é outro trabalho.
- **A impressão guardada tem de estar mais protegida que o arquivo.** Se quem pode editar
  `prices.csv` também pode editar `prices.sha256`, a pessoa muda os dois e a verificação passa.
  Sistemas reais guardam a referência onde o atacante não escreve, ou a assinam com uma chave que
  ele não tem, que é o assunto da aula 6 de `cryptography`.

A mesma ideia, em escala maior, está por trás de muita segurança do dia a dia. Um gerenciador de
pacotes confere o hash de cada download antes de instalar. Uma ferramenta de backup registra
hashes para que uma restauração prove que trouxe de volta o que foi salvo, o que a aula 12 usa.
Monitores de integridade de arquivos guardam hashes dos programas de um servidor e disparam um
alerta quando um deles muda.
