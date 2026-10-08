---
title: O que está no disco
version: 1
---

Tudo até aqui protegeu o dado em movimento. Agora os arquivos. O PostgreSQL guarda cada tabela em
arquivos comuns sob o diretório de dados, e **nada no PostgreSQL os cifra**. O servidor sabe dizer
qual arquivo guarda os clientes:

```
ana@lab:~/gov$ sudo -u postgres psql -c "CHECKPOINT"
CHECKPOINT
ana@lab:~/gov$ sudo -u postgres psql -Atc "SELECT pg_relation_filepath('sales.customers')"
base/16384/16389
ana@lab:~/gov$ sudo grep -a -o -m 1 "paula.cavalcanti@example.com" /var/lib/postgresql/16/gov/base/16384/16389
paula.cavalcanti@example.com
```

Primeiro `CHECKPOINT`, porque uma página alterada na memória só chega ao arquivo no próximo
checkpoint; depois o caminho do arquivo; depois um `grep` simples pelo e-mail de uma cliente,
rodado contra os bytes crus da tabela. **Está lá, em claro, no arquivo.** Quem tiver uma cópia
desse diretório — um disco roubado, um servidor descartado, um snapshot de volume na nuvem
compartilhado com a conta errada — lê todos os clientes com ferramentas que vêm em todo sistema
operacional.

## Cifrando o volume

A resposta padrão no Linux é cifrar o dispositivo de blocos inteiro onde o diretório de dados mora,
com **LUKS**, para que o que é escrito no disco seja texto cifrado e o que o sistema operacional lê
depois de destravá-lo seja texto claro. O formato fica mais fácil de ver num arquivo pequeno
fazendo papel de disco:

```
ana@lab:~/gov$ truncate -s 32M volume.img
ana@lab:~/gov$ cryptsetup luksFormat --batch-mode volume.img
ana@lab:~/gov$ cryptsetup luksDump volume.img
LUKS header information
Version:       	2
Epoch:         	3
Metadata area: 	16384 [bytes]
Keyslots area: 	16744448 [bytes]
UUID:          	1ac389d5-712f-476d-8ddf-3a3d6138a33b
Label:         	(no label)
Subsystem:     	(no subsystem)
Flags:       	(no flags)

Data segments:
  0: crypt
	offset: 16777216 [bytes]
	length: (whole device)
	cipher: aes-xts-plain64
	sector: 4096 [bytes]

Keyslots:
  0: luks2
	Key:        512 bits
	Priority:   normal
	Cipher:     aes-xts-plain64
	Cipher key: 512 bits
	PBKDF:      argon2id
	Time cost:  5
	Memory:     1048576
	Threads:    4
	Salt:       26 b8 a9 e7 22 8d 34 31 f3 fb 86 2c 0f 68 0b ec 
	            99 b1 3a f5 45 71 41 90 cc e8 4e d9 a2 a7 a1 6f 
	AF stripes: 4000
	AF hash:    sha256
	Area offset:32768 [bytes]
	Area length:258048 [bytes]
	Digest ID:  0
Tokens:
Digests:
  0: pbkdf2
	Hash:       sha256
	Iterations: 219919
	Salt:       20 d6 60 ff c2 28 bd 5c 7f 73 bd 35 ad 35 87 a7 
	            88 81 81 b2 50 a5 fe 62 54 4c 55 e0 df 99 92 5c 
	Digest:     12 65 5f bc ec d8 5a fd 5b 2d 9e 82 5f a0 10 81 
	            ef fd bb 9b 15 a2 81 f4 41 4e 77 37 20 59 23 ac 
```

`luksFormat` escreveu um cabeçalho e mais nada; você digita a frase-senha no prompt, e
nada aparece na tela. O cabeçalho é a parte
interessante:

- **`cipher: aes-xts-plain64`** — AES em modo XTS, o modo feito para discos, com chave de 512 bits
  (duas metades de 256, uma delas para o *tweak* do XTS);
- **um keyslot com `PBKDF: argon2id`** — a frase-senha não é a chave. Ela destrava um slot que
  guarda a chave real do volume, por uma derivação lenta e gulosa de memória de propósito, a mesma
  ideia das iterações do SCRAM da aula 1;
- **espaço para mais slots**, para que um volume possa ser aberto por várias frases-senha ou
  arquivos de chave, e um possa ser removido sem recifrar o disco.

Os passos seguintes abrem o volume, põem um sistema de arquivos nele e o montam onde o PostgreSQL
guarda os dados. **Eles não foram executados aqui**: abrir um volume LUKS precisa do device-mapper
do kernel, que a máquina em que este curso foi gravado não oferece. Na máquina virtual que a
aula 1 recomenda, eles são:

```sh
sudo cryptsetup open volume.img ipe-data
sudo mkfs.ext4 /dev/mapper/ipe-data
sudo mount /dev/mapper/ipe-data /var/lib/postgresql
```

Numa nuvem, a mesma proteção é uma propriedade do volume — um volume EBS cifrado, um disco
persistente do Google Cloud, que o Google cifra por padrão — e a chave que importa é a do serviço
de gestão de chaves do provedor, que é o assunto da aula 4.

## Contra o que ela protege

**Um disco que sai do prédio.** É uma ameaça real e a única: hardware roubado, discos mandados para
conserto, drives descartados sem apagar, um snapshot copiado para fora. Contra essas, a
criptografia de volume é completa e barata. A próxima seção trata de tudo contra o que ela não
protege, que é a maior parte do que este curso trata.
