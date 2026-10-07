---
title: Uma chave que tranca e destranca
version: 1
---

**A criptografia simétrica usa a mesma chave para cifrar e para decifrar.** Quem tem a chave faz as
duas coisas, e quem não tem não faz nenhuma. Todo o resto desta aula trata de usar bem essa chave,
porque a matemática da cifra é a parte que quase nunca falha.

## Uma carta, uma chave e a mesma chave de volta

A Vereda guarda uma carta de encaminhamento de cada paciente. Aqui está uma, e aqui está a chave
que o laboratório usa para cifrá-la:

```
ana@lab:~/lab$ cat data/referral.txt
Referral 2026-0417. Patient: Marina Duarte, 41.
Lower back pain after lifting, eight weeks. Eight sessions of physiotherapy.
Dr. Paulo Nogueira, CRM-SP 000000 (invented)
ana@lab:~/lab$ cat keys/aes-256.hex
2273f51f3c00abbd6cc30ebc3339cf8b4798afb1786829887df8b0d8526250a0
```

A chave tem 32 bytes, escritos como 64 dígitos hexadecimais: **uma chave de 256 bits**. Ela não
passa de bytes aleatórios. Não há estrutura nela nem senha por trás dela, e é isso que faz dela uma
chave. (O laboratório trapaceia aqui de propósito: ele deriva todas as chaves de um rótulo público,
para que estas transcrições saiam iguais na sua máquina. A aula 17 mostra por que uma chave que
qualquer um consegue reconstruir não é chave.) O `openssl enc` cifra a carta com AES e essa chave,
e o que sai são bytes sem nenhuma relação visível com a carta:

```
ana@lab:~/lab$ openssl enc -aes-256-cbc -K $(cat keys/aes-256.hex) -iv $(cat keys/iv-a.hex) -in data/referral.txt -out referral.enc
ana@lab:~/lab$ od -An -tx1 -N48 referral.enc
 b7 9d 96 21 e6 9a 64 11 01 5e ab b6 c5 7a ff 12
 23 62 e3 f8 5a c8 ef 16 1e 51 d6 80 81 34 48 b8
 12 3c 90 4e 55 85 2f 1f 1e a8 43 4b 7e b7 0d b4
```

Decifrar exige as mesmas duas entradas, a chave e o vetor (`-iv`, assunto da seção 07 desta aula).
Com as duas, a carta volta exatamente igual:

```
ana@lab:~/lab$ openssl enc -d -aes-256-cbc -K $(cat keys/aes-256.hex) -iv $(cat keys/iv-a.hex) -in referral.enc
Referral 2026-0417. Patient: Marina Duarte, 41.
Lower back pain after lifting, eight weeks. Eight sessions of physiotherapy.
Dr. Paulo Nogueira, CRM-SP 000000 (invented)
```

Com **outra** chave de 256 bits, não volta:

```
ana@lab:~/lab$ openssl enc -d -aes-256-cbc -K $(cat keys/aes-256-b.hex) -iv $(cat keys/iv-a.hex) -in referral.enc -out wrong.txt 2>err.txt; echo "exit status $?"; head -1 err.txt
exit status 1
bad decrypt
```

`bad decrypt` é o OpenSSL percebendo que o último bloco não termina como um bloco decifrado
corretamente precisa terminar (a próxima seção explica esse final, o preenchimento). Leia isso
como sorte, não como garantia. A maioria das chaves erradas cai nessa verificação, e algumas
produzem lixo que por acaso termina do jeito certo. Uma cifra sozinha não tem como dizer "esta é a
chave errada"; ela transforma qualquer entrada em alguma saída. Distinguir uma decifragem correta
de lixo é outro trabalho, e a última seção desta aula o entrega ao modo de operação.

## Por que a chave é o único segredo

O algoritmo é público. O AES foi escolhido num concurso aberto organizado pelo NIST, sua
especificação é a FIPS 197, e cada linha do OpenSSL pode ser lida. Isso é deliberado e tem nome,
**princípio de Kerckhoffs**: um sistema precisa continuar seguro quando tudo nele, exceto a chave,
é conhecido. Um algoritmo secreto não acrescenta nada, porque vaza na primeira vez que um binário é
copiado, e custa muito, porque ninguém de fora teve permissão de procurar suas falhas. A aula 17
volta a isso como um dos três erros clássicos.

A força do esquema, então, é o tamanho do espaço de chaves. Com 256 bits há 2²⁵⁶ chaves, e
testar todas está fora do alcance de qualquer computador que se possa construir. Mesmo 128 bits,
2¹²⁸ chaves, está muito além de qualquer busca exaustiva que alguém já executou. **O AES-128 não é
fraco**; o AES-256 é escolhido por margem, e em particular pelo futuro da aula 7, em que um
computador quântico reduz pela metade o tamanho efetivo de uma chave simétrica e 256 vira 128.

## O que a criptografia simétrica não faz sozinha

Uma chave para os dois sentidos é rápida e simples, e deixa um problema intocado: **os dois lados
precisam da mesma chave antes de começar**. O servidor da Vereda consegue cifrar os próprios
arquivos com uma chave que só ele conhece. O navegador de um paciente e esse servidor, que se
encontram pela primeira vez, não compartilham nada. Como os dois combinam uma chave numa rede que
alguém pode estar escutando é a aula 7, e isso precisa da criptografia assimétrica das aulas 2 e 3.
Todo sistema real combina as duas: assimétrica para combinar uma chave, simétrica para cifrar os
dados. Essa combinação é o que o TLS é, na aula 10.

A segunda coisa que ela não faz é **dizer quem escreveu alguma coisa**. Se a Vereda e um
laboratório compartilham uma chave, uma mensagem cifrada com ela pode ter vindo de qualquer um dos
dois. A aula 6 separa provar que uma mensagem está íntegra de provar quem a enviou.
