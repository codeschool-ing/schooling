---
title: E01, e o FTK Imager
version: 1
---

Uma imagem bruta são só bytes: o número do caso, quem a fez, quando, e o hash dela vivem em outro lugar, num
documento que pode se separar dela. O **Expert Witness Format**, os arquivos terminados em `.E01`, guarda tudo
isso **dentro da imagem**, comprime o espaço vazio e guarda uma soma de verificação para cada bloco, então um dano
no arquivo da imagem é detectado. Ele nasceu com o EnCase, uma suíte forense comercial, e hoje é o formato de
imagem mais comum no trabalho forense.

A ferramenta que a maioria dos peritos usa para escrevê-lo é o **FTK Imager**, software gratuito da Exterro que
roda no Windows. **Ele não foi rodado nesta aula**, porque o laboratório é uma máquina Linux. Em linhas gerais, ele
pede exatamente o que o próximo comando recebe como opções: em *File, Create Disk Image*, uma origem (*Physical
Drive*, através de um bloqueador de escrita), um tipo de imagem (*E01*), os dados da evidência (número do caso,
número da evidência, descrição, perito, notas), uma pasta de destino, e uma caixa que vale sempre marcar, *Verify
images after they are created*. No fim ele escreve um arquivo de texto ao lado da imagem com os hashes que
calculou.

No Linux, o `ewfacquire` do `ewf-tools` escreve o mesmo formato, com os mesmos dados:

```
root@soc:~/case# ewfacquire -u -q -t evidence/files-data -C INC-2026-014 -E 001 -D 'files, data disk' -e diego -N 'imaged after containment' -d sha256 -c deflate:fast /dev/loop0
ewfacquire 20140814

Device information:
Bus type:				
Vendor:					
Model:					
Serial:					

Storage media information:
Type:					Device
Media type:				Fixed
Media size:				33 MB (33554432 bytes)
Bytes per sector:			512

MD5 hash calculated over data:		3260d6031df48a9f68dd1d7cb7578fda
SHA256 hash calculated over data:	eae7ac5a6c3fdefeba94adcb9f73955babaf7ffe4f54f20cb02e0d2cee186475
ewfacquire: SUCCESS
root@soc:~/case# ls -l evidence
total 32948
-rw-r--r-- 1 root root   180611 Oct  7 20:59 files-data.E01
-rw-r--r-- 1 root root 33554432 Oct  7 20:59 files-data.dd
```

`-u` roda sem perguntas; `-t` nomeia o destino, e o `.E01` é acrescentado; `-C`, `-E`, `-D`, `-e` e `-N` são o
número do caso, o número da evidência, a descrição, o perito e as notas; `-d sha256` acrescenta um SHA-256 ao MD5
que ele sempre calcula; `-c deflate:fast` comprime. O SHA-256 que ele imprime é **o mesmo do `dd`**: o mesmo disco,
por duas ferramentas. E o E01 tem 180.611 bytes contra os 33.554.432 da imagem bruta, porque a maior parte de um
disco novo está vazia, e vazio comprime para quase nada.

Depois, a verificação, que lê a imagem inteira de volta e compara, e os dados do caso lidos de dentro do próprio
arquivo:

```
root@soc:~/case# ewfverify -q evidence/files-data.E01
ewfverify 20140814


MD5 hash stored in file:		3260d6031df48a9f68dd1d7cb7578fda
MD5 hash calculated over data:		3260d6031df48a9f68dd1d7cb7578fda

ewfverify: SUCCESS
root@soc:~/case# ewfinfo evidence/files-data.E01
ewfinfo 20140814

Acquiry information
	Case number:		INC-2026-014
	Description:		files, data disk
	Examiner name:		diego
	Evidence number:	001
	Notes:			imaged after containment
	Acquisition date:	Wed Oct  7 20:59:35 2026
	System date:		Wed Oct  7 20:59:35 2026
	Operating system used:	Linux
	Software version used:	20140814
	Password:		N/A

EWF information
	File format:		EnCase 6
	Sectors per chunk:	64
	Error granularity:	64
	Compression method:	deflate
	Compression level:	good (fast) compression

Media information
	Media type:		fixed disk
	Is physical:		yes
	Bytes per sector:	512
	Number of sectors:	65536
	Media size:		32 MiB (33554432 bytes)

Digest hash information
	MD5:			3260d6031df48a9f68dd1d7cb7578fda
```

Um detalhe merece atenção. O formato EnCase 6 guarda o **MD5** dentro do arquivo, e o `ewfverify` confere esse; o
SHA-256 foi calculado e impresso, mas este formato não tem lugar para ele. Então **o SHA-256 vai à mão para o
registro de custódia**, a partir da saída da aquisição, que é o assunto da próxima seção.
