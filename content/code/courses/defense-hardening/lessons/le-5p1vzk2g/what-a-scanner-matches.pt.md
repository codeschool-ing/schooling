---
title: O que um scanner compara de fato
version: 1
---

**Um scanner antivírus compara arquivos com descrições de arquivos que alguém já julgou.** A
descrição é uma **assinatura**, e o scanner só é tão bom quanto a lista delas. A imagem comum é a de
um programa que reconhece o perigo. O que ele reconhece é semelhança com algo já visto, e é por isso
que funciona tão bem contra o caso comum e é por isso que a última seção desta aula existe.

Suba o laboratório com `sudo bash hostlab.sh up desk`. O laboratório instalou o **ClamAV**, o scanner
de código aberto, em todas as máquinas. Peça a ele para examinar um arquivo:

```
ana@desk:~$ clamscan --no-summary eicar.txt; echo "exit $?"
LibClamAV Error: cli_loaddbdir: No supported database files found in /var/lib/clamav
ERROR: Can't open file or directory
exit 2
ana@desk:~$ ls /var/lib/clamav
```

Ele se recusa, e o motivo é o ponto desta seção: **sem assinaturas, um scanner não tem com o que
comparar.** As assinaturas do ClamAV vêm dos servidores da Cisco pelo `freshclam`, o atualizador, que
roda como serviço e busca assinaturas novas várias vezes por dia. O laboratório não alcança esses
servidores, então `/var/lib/clamav` está vazio, e **baixar o banco oficial não foi executado para este
curso.** Numa máquina com acesso à internet, `sudo systemctl enable --now clamav-freshclam` enche o
diretório com várias centenas de megabytes de assinaturas em minutos.

Essa lacuna acaba sendo útil. Cada assinatura desta aula é uma que você escreve, que é o melhor jeito
de ver o que uma assinatura é.

## Um arquivo feito para ser detectado

O **arquivo de teste EICAR** são 68 caracteres imprimíveis que todos os fabricantes de antivírus
combinaram, nos anos 1990, detectar como se fosse um vírus. Ele não faz nada; existe para que um
scanner, um filtro de e-mail ou uma quarentena possam ser testados sem lidar com nada perigoso.
Qualquer scanner com banco atualizado o informa. Aqui está ele, e uma assinatura feita pelo `sigtool`,
a ferramenta do próprio ClamAV:

```
ana@desk:~$ cat eicar.txt; echo; wc -c eicar.txt
X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*
68 eicar.txt
ana@desk:~$ sigtool --sha256 eicar.txt > lab.hsb; cat lab.hsb
275a021bbfb6489e54d471899f7db9d1663fc695ec2fe2a2c4538aabf651fd0f:68:eicar.txt
ana@desk:~$ clamscan --no-summary -d lab.hsb eicar.txt; echo "exit $?"
eicar.txt: eicar.txt.UNOFFICIAL FOUND
exit 1
```

A assinatura tem três campos: o hash SHA-256 do arquivo, o tamanho em bytes e um nome. `-d` diz ao
`clamscan` para usar esse arquivo como banco, e ele informa o achado com o nome e `.UNOFFICIAL`, a
marca do ClamAV para uma assinatura que ele não distribuiu. **Código de saída 1 quer dizer "achado"**,
0 quer dizer limpo e 2 quer dizer que a própria varredura falhou, como falhou acima; scripts e
agendamentos leem esse número.

## Substitutos para o resto da aula

Nada neste curso lida com malware de verdade, e nada precisa. O resto da aula usa três arquivos de
texto curtos que fazem o papel de "um arquivo que o escritório decidiu que é ruim", um deles cópia de
outro e um diferente por um único espaço:

```
ana@desk:~$ mkdir samples && printf "JATOBA-LAB-SAMPLE invoice 2026-10\n" > samples/invoice.txt && cp samples/invoice.txt samples/copy.txt && printf "JATOBA-LAB-SAMPLE invoice 2026-10 \n" > samples/changed.txt && sha256sum samples/*
ea62d09edf0db80993d227b7b6f8d0124de06b98686acbbf0c69e74a8968c1e9  samples/changed.txt
0cad6ef09fcc2504e6df0bd0c8da112c9ba39df42a87d6b5f86f071e28140e72  samples/copy.txt
0cad6ef09fcc2504e6df0bd0c8da112c9ba39df42a87d6b5f86f071e28140e72  samples/invoice.txt
```

Os dois arquivos idênticos têm hashes idênticos. O terceiro, um caractere mais longo, tem um hash
completamente diferente, e a próxima seção mostra o que isso faz com uma assinatura.
