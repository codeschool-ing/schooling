---
title: Assinaturas de conteúdo e YARA
version: 1
---

**Uma assinatura de conteúdo descreve algo de dentro do arquivo e não o arquivo inteiro.** É uma
sequência de bytes, um padrão ou uma combinação deles, e casa com todo arquivo que a contenha, por
mais que o resto difira. Uma assinatura de conteúdo pode cobrir uma família de variantes que
precisaria de um hash para cada uma.

A assinatura de conteúdo mais simples do ClamAV mora num arquivo `.ndb`: um nome, o tipo de arquivo a
que se aplica (`0` é qualquer um), onde procurar (`*` é em qualquer lugar) e os bytes, escritos em
hexadecimal. O `xxd -p` transforma o marcador do substituto nesses bytes:

```
ana@desk:~$ printf "JATOBA-LAB-SAMPLE" | xxd -p
4a41544f42412d4c41422d53414d504c45
ana@desk:~$ echo "Jatoba.Lab.Marker:0:*:4a41544f42412d4c41422d53414d504c45" > lab.ndb; clamscan --no-summary -d lab.ndb samples/; echo "exit $?"
samples/copy.txt: Jatoba.Lab.Marker.UNOFFICIAL FOUND
samples/changed.txt: Jatoba.Lab.Marker.UNOFFICIAL FOUND
samples/invoice.txt: Jatoba.Lab.Marker.UNOFFICIAL FOUND
exit 1
```

As três amostras são achadas, inclusive o `changed.txt`, porque o marcador está nas três. O ClamAV
também tem assinaturas lógicas (`.ldb`), que combinam vários padrões com *e* e *ou* e condições sobre
quantas vezes cada um aparece, e assinaturas presas a um formato de arquivo, por exemplo um padrão que
só conta dentro da seção de código de um executável Windows.

## YARA, a linguagem de padrões de quem defende

O **YARA** é a ferramenta a que os analistas recorrem quando escrevem as próprias regras, e muitos
produtos de segurança leem as regras dele diretamente. Uma regra nomeia as strings e depois diz uma
condição sobre elas, que pode incluir o tamanho do arquivo, o formato e quantas strings casaram:

```
ana@desk:~$ cat > lab.yar <<"EOF"
rule jatoba_lab_marker
{
    strings:
        $marker = "JATOBA-LAB-SAMPLE"
        $word = "invoice" nocase
    condition:
        $marker and $word and filesize < 1KB
}
EOF
yara lab.yar samples/
jatoba_lab_marker samples//invoice.txt
jatoba_lab_marker samples//copy.txt
jatoba_lab_marker samples//changed.txt
```

A regra casa com um arquivo que contém o marcador *e* a palavra "invoice" em qualquer caixa, *e* tem
menos de um kilobyte. Cada cláusula a estreita: só o marcador seria uma regra mais fraca, e o limite
de tamanho impede que um documento grande que por acaso cite o marcador case. Analistas guardam regras
assim em controle de versão, testam contra um conjunto de arquivos que precisa casar e um que não pode,
e as compartilham entre si.

## O preço de casar com mais

Um padrão casa com qualquer arquivo que o contenha, inclusive arquivos que ninguém queria descrever:

```
ana@desk:~$ printf "Training notes: files marked JATOBA-LAB-SAMPLE are invoice test files.\n" > notes.txt; yara lab.yar notes.txt; clamscan --no-summary -d lab.ndb notes.txt
jatoba_lab_marker notes.txt
notes.txt: Jatoba.Lab.Marker.UNOFFICIAL FOUND
```

Uma nota de treinamento que cita o marcador, perfeitamente inocente, é marcada pelos dois. Isso é um
**falso positivo**, e toda regra de conteúdo tem alguns. Uma regra ampla o bastante para pegar a
variante de amanhã é ampla o bastante para pegar o documento de alguém, e o custo cai na pessoa cujo
arquivo foi para a quarentena e em quem precisa decidir se estava certo. Escrever uma boa regra é
escolher o que, num arquivo, é específico da coisa que você quer dizer, e mais nada.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l07-matches\" aria-label=\"Que regra casou com que arquivo nesta aula. Quatro arquivos nas colunas: invoice.txt, a cópia exata, changed.txt que difere por um espaço, e uma nota de treinamento inocente que cita o marcador. Três regras nas linhas. A assinatura de hash casou só com o original e a cópia. A assinatura de conteúdo casou com as três amostras e também com a nota. A regra YARA, com o marcador, a palavra invoice e um limite de tamanho, casou com os mesmos quatro.\"><text x=\"260.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">invoice.txt</text><text x=\"375.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">copy.txt</text><text x=\"490.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">changed.txt</text><text x=\"605.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">notes.txt</text><text x=\"605.0\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">inocente</text><rect x=\"20.0\" y=\"70.0\" width=\"680.0\" height=\"40.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"36.0\" y=\"90.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">hash (.hsb)</text><rect x=\"220.0\" y=\"78.0\" width=\"80.0\" height=\"24.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"260.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">achado</text><rect x=\"335.0\" y=\"78.0\" width=\"80.0\" height=\"24.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"375.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">achado</text><text x=\"490.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">OK</text><text x=\"605.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">OK</text><rect x=\"20.0\" y=\"120.0\" width=\"680.0\" height=\"40.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"36.0\" y=\"140.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">conteúdo (.ndb)</text><rect x=\"220.0\" y=\"128.0\" width=\"80.0\" height=\"24.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"260.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">achado</text><rect x=\"335.0\" y=\"128.0\" width=\"80.0\" height=\"24.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"375.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">achado</text><rect x=\"450.0\" y=\"128.0\" width=\"80.0\" height=\"24.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"490.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">achado</text><rect x=\"565.0\" y=\"128.0\" width=\"80.0\" height=\"24.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">falso positivo</text><rect x=\"20.0\" y=\"170.0\" width=\"680.0\" height=\"40.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"36.0\" y=\"190.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">regra YARA</text><rect x=\"220.0\" y=\"178.0\" width=\"80.0\" height=\"24.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"260.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">achado</text><rect x=\"335.0\" y=\"178.0\" width=\"80.0\" height=\"24.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"375.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">achado</text><rect x=\"450.0\" y=\"178.0\" width=\"80.0\" height=\"24.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"490.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">achado</text><rect x=\"565.0\" y=\"178.0\" width=\"80.0\" height=\"24.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">falso positivo</text><text x=\"360.0\" y=\"232.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">quanto mais ampla a regra, mais ela pega, querendo ou não</text></svg>", "caption": "Regras exatas perdem variantes; regras amplas pegam arquivos inocentes.", "same": ["hash (.hsb)"]}
```
