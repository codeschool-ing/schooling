---
title: Olhando um arquivo sem abri-lo
version: 1
---

**As primeiras perguntas sobre um arquivo suspeito se respondem na sua própria máquina, sem
executá-lo.** O que ele é de verdade? Qual é o hash dele? Que texto há dentro? Ele bate com um padrão
que você já viu? Nenhuma das quatro manda nada a lugar nenhum.

Dois arquivos chegaram no `desk`. Um diz ser a fatura de outubro; o outro é uma anotação. Os dois são
feitos aqui pela aula, e a "fatura" é um script inofensivo que só imprime uma frase, escrito para
parecer o tipo de coisa que chega por e-mail:

```
ana@desk:~$ mkdir -p ~/inbox && cd ~/inbox && cat > fatura-outubro.pdf <<'EOF'
#!/bin/sh
# A lab sample for lesson 19. It looks like a PDF by its name and is a shell script.
# It does nothing but print one sentence.
PAY_URL=http://pagamento.cobranca-urgente.example.org/boleto
echo "This file is a harmless lab sample. It would have opened $PAY_URL"
EOF
printf 'Reunião com o cliente às 15h.\nLevar o contrato assinado.\n' > nota.txt; ls -l
total 8
-rw-rw-r-- 1 ana ana 271 Oct 23 10:12 fatura-outubro.pdf
-rw-rw-r-- 1 ana ana  59 Oct 23 10:12 nota.txt
```

## O que ele é de verdade

Um nome de arquivo é um rótulo que alguém escolheu. O `file` lê os primeiros bytes, onde a maioria dos
formatos se anuncia, e diz o que eles anunciam:

```
ana@desk:~$ cd ~/inbox && file *
fatura-outubro.pdf: POSIX shell script, ASCII text executable
nota.txt:           Unicode text, UTF-8 text
```

A fatura é um script de shell. Um PDF de verdade começa com os quatro bytes `%PDF`, e este começa com
`#!`, a marca de um script. **Um arquivo cujo nome e conteúdo discordam é um achado antes de qualquer
outra coisa se saber sobre ele**, e numa estação onde alguém pode clicar duas vezes nele, é o achado
que importa.

## O hash dele

```
ana@desk:~$ cd ~/inbox && sha256sum *
1f40c2b362d01d064dcc53f20fc9b0a3e624469b810c9c5e7493e02d9be70cce  fatura-outubro.pdf
881d0c339a944999540104f5a56afcf66ef77a8ff6fc50017e2d7fb718bec98e  nota.txt
```

Um hash SHA-256 são 64 caracteres hexadecimais calculados a partir de cada byte do arquivo: mude um
byte e o hash muda por completo, e ninguém consegue voltar de um hash ao conteúdo. Isso faz dele a
coisa certa a buscar e a anotar. É a identidade pela qual um serviço procura um arquivo, a linha que um
relatório de incidente registra e a entrada das próximas três seções, **e ele não revela nada dos
dados de um cliente**, o que o próprio arquivo revelaria.

## O que está escrito dentro

O `strings` imprime os trechos de texto legível de qualquer arquivo, binário ou não, e o `xxd` mostra
os primeiros bytes com os valores hexadecimais:

```
ana@desk:~$ cd ~/inbox && strings -n 8 fatura-outubro.pdf | grep -iE "http|sh"
#!/bin/sh
# A lab sample for lesson 19. It looks like a PDF by its name and is a shell script.
PAY_URL=http://pagamento.cobranca-urgente.example.org/boleto
ana@desk:~$ cd ~/inbox && xxd fatura-outubro.pdf | head -2
00000000: 2321 2f62 696e 2f73 680a 2320 4120 6c61  #!/bin/sh.# A la
00000010: 6220 7361 6d70 6c65 2066 6f72 206c 6573  b sample for les
```

O endereço que o script teria visitado está em texto claro. Numa amostra de verdade, é aqui que você
acha os domínios a bloquear no resolvedor da aula 14 e a procurar na última seção desta aula. A linha
do `xxd` mostra os mesmos primeiros bytes que o `file` leu: `2321` é `#!`.

## Um padrão, escrito uma vez

Uma regra YARA, que a aula 7 usou para descrever malware pelo conteúdo, também descreve esta situação:
um script que carrega um endereço web, diga o nome o que disser. Escreva-a no `desk` e rode-a sobre a
caixa de entrada, com `-s` para mostrar o que bateu e onde:

```
ana@desk:~$ cat > ~/disguised.yar <<'EOF'
rule script_named_like_a_document
{
    meta:
        description = "a shell script that carries a web address, whatever its name says"
    strings:
        $shebang = "#!/bin/sh"
        $url = /https?:\/\/[a-z0-9.-]+\.[a-z]{2,}/
    condition:
        $shebang at 0 and $url
}
EOF
yara -s ~/disguised.yar ~/inbox
script_named_like_a_document /home/ana/inbox/fatura-outubro.pdf
0x0:$shebang: #!/bin/sh
0x91:$url: http://pagamento.cobranca-urgente.example.org
```

Um arquivo bate, no byte 0 para a marca de script e no byte `0x91` para o endereço; a anotação não. Uma
regra assim não custa nada para rodar sobre cada anexo que um servidor de e-mail recebe, e guarda o que
um analista aprendeu com uma amostra para que a próxima seja achada sem analista.

**Tudo nesta seção ficou no `desk`.** O arquivo nunca foi executado, nunca foi enviado, e as quatro
respostas que deu bastam para decidir que ele não deve chegar à caixa de entrada de mais ninguém. As
próximas seções são para os casos em que elas não bastam.
