---
title: Cifragem de disco inteiro, dentro de um cabeçalho LUKS
version: 1
---

**Um sistema de cifragem de disco inteiro cifra cada setor de um volume com uma chave aleatória, a
chave do volume, e guarda essa chave num cabeçalho, cifrada sob cada frase-senha autorizada a
desbloqueá-lo.** O LUKS, o padrão do Linux, deixa essa estrutura fácil de ver; o BitLocker e o
FileVault são construídos do mesmo jeito. Os notebooks da Vereda rodam Linux, e o laboratório formata
um arquivo de 32 MiB no lugar do disco de um notebook.

## Formatando, e uma segunda entrada

```
ana@lab:~/lab$ truncate -s 32M disk.img
ana@lab:~/lab$ cryptsetup luksFormat -q --type luks2 --cipher aes-xts-plain64 --key-size 512 --pbkdf argon2id --pbkdf-force-iterations 4 --pbkdf-memory 65536 --pbkdf-parallel 1 --uuid 6d2f4a1e-0b7c-4c3e-9a51-2f6e8c1d0a37 --key-file disk.pass disk.img
ana@lab:~/lab$ cryptsetup luksAddKey -q --pbkdf argon2id --pbkdf-force-iterations 4 --pbkdf-memory 65536 --pbkdf-parallel 1 --key-file disk.pass disk.img recovery.pass
```

O primeiro comando criou o volume e sua chave aleatória de 512 bits, protegida pela frase-senha do
fisioterapeuta. O segundo acrescentou uma **frase-senha de recuperação** num segundo slot, a que a TI
guarda no cofre para o dia em que alguém esquece a sua. Nenhuma das duas frases-senha cifra o disco.
Cada uma só desbloqueia uma cópia da chave do volume.

## Lendo o cabeçalho

```
ana@lab:~/lab$ cryptsetup luksDump disk.img | grep -E '^(Version|UUID)|^  [0-9]: |cipher:|Cipher key|PBKDF|Time cost|Memory'
Version:       	2
UUID:          	6d2f4a1e-0b7c-4c3e-9a51-2f6e8c1d0a37
  0: crypt
	cipher: aes-xts-plain64
  0: luks2
	Cipher key: 512 bits
	PBKDF:      argon2id
	Time cost:  4
	Memory:     65536
  1: luks2
	Cipher key: 512 bits
	PBKDF:      argon2id
	Time cost:  4
	Memory:     65536
  0: pbkdf2
```

O cabeçalho diz, em público:

- os dados são cifrados com **AES no modo XTS** (`aes-xts-plain64`), com uma chave de 512 bits, que
  são duas chaves AES-256. O XTS é um modo feito para discos: cada setor é cifrado com a própria
  posição misturada, então setores iguais não parecem iguais (o problema do ECB da aula 1) e qualquer
  setor pode ser lido ou gravado sozinho. Ele não tem etiqueta de autenticação, porque um setor não
  tem espaço para uma; essa é uma limitação conhecida da cifragem de disco;
- dois **slots de chave**, 0 e 1, cada um guardando a chave do volume cifrada sob uma chave derivada
  de uma frase-senha com **Argon2id**, custo de tempo 4, 64 MiB de memória: a função lenta e pesada em
  memória da aula 5, fazendo o trabalho para o qual foi feita. Quem rouba o notebook precisa adivinhar
  a frase-senha na velocidade do Argon2id, offline, pelo tempo que quiser. É por isso que a força da
  frase-senha é a proteção inteira.

## Desbloqueando, com qualquer uma das frases-senha

A frase-senha de recuperação recupera a chave do volume:

```
ana@lab:~/lab$ cryptsetup open --test-passphrase --key-file recovery.pass disk.img && echo "recovery passphrase unlocks the volume key"
recovery passphrase unlocks the volume key
```

Uma frase-senha que difere por uma letra maiúscula não recupera:

```
ana@lab:~/lab$ printf 'Correct horse battery staple' > typo.pass; cryptsetup open --test-passphrase --key-file typo.pass disk.img; echo "exit status $?"
No key available with this passphrase.
exit status 2
```

(O laboratório confere as frases-senha com `--test-passphrase`, que desbloqueia a chave do volume e
para. Mapear o volume como disco exige o device mapper do kernel, que a máquina que gravou esta aula
não oferece, então o volume nunca é montado aqui.)

## O que a estrutura compra

Como as frases-senha só embrulham a chave do volume, trocar uma frase-senha regrava algumas centenas
de bytes do cabeçalho e **nunca cifra o disco de novo**. Remover o slot de um funcionário revoga o
acesso dele sem tocar nos dados. E destruir o cabeçalho destrói a chave do volume, o que deixa o disco
inteiro ilegível de uma vez: o **apagamento criptográfico** (*crypto-erase*), que é como discos e
celulares cifrados são apagados num segundo. Uma cópia do cabeçalho feita antes de um slot ser
removido ainda abre com a frase-senha antiga, e é por isso que cabeçalhos têm backup feito de
propósito e cópias antigas são destruídas.

Num notebook com TPM, a chave do volume também pode ser selada no TPM para que a máquina só destrave
se a cadeia de boot não tiver mudado; o BitLocker faz isso por padrão, em geral também com um PIN. O
que ele protege continua o mesmo: o aparelho desligado.
