---
title: Nomes que ainda não existem
version: 1
---

O jeito mais direto de uma alucinação virar ataque é por um nome. Um modelo a quem se pede código sugere
um pacote para instalar, e às vezes o pacote que ele nomeia nunca foi publicado. A sugestão parece
exatamente uma real. **Um nome que ninguém possui é um nome que qualquer um pode registrar**, e se um
modelo sugere sempre o mesmo nome inventado, quem registrá-lo primeiro decide o que o próximo
desenvolvedor que confiar na sugestão vai instalar. Pesquisadores mediram modelos inventando nomes de
pacotes numa taxa perceptível, e o truque de registrá-los ganhou um apelido próprio, *slopsquatting*.

A defesa é a mesma dos links da aula 9: **um nome que um modelo produziu é conferido contra uma lista
confiável antes de qualquer coisa agir sobre ele.** No laboratório, as sugestões de um modelo para um
recurso de QR code Pix estão em `data/suggested-deps.txt`, escrito pelo curso, e o
`data/registry-snapshot.txt` é um substituto curto dos pacotes que a Tarefa já revisou:

```
ana@lab:~/guard$ cat data/suggested-deps.txt
requests
python-dateutil
pix-qrcode-br
qrcode
brazil-cpf-validator-pro
ana@lab:~/guard$ guard deps data/suggested-deps.txt; echo "exit $?"
requests                   in the snapshot
python-dateutil            in the snapshot
pix-qrcode-br              NOT IN THE SNAPSHOT: do not install
qrcode                     in the snapshot
brazil-cpf-validator-pro   NOT IN THE SNAPSHOT: do not install
exit 1
```

Dois nomes não estão no snapshot. O laboratório não diz se eles existem no índice público, porque essa
não é a pergunta que protege a Tarefa: um nome que existe não é por isso o pacote que o modelo quis
dizer, e o resultado seguro é o mesmo nos dois casos. **Uma pessoa procura o pacote**, lê quem o
publica, há quanto tempo existe e quão usado é, e o acrescenta à lista revisada ou não o instala.

Três hábitos fazem isso valer numa equipe:

- **Instalar a partir da lista revisada, com versões fixadas e hashes conferidos**, para que um nome novo
  exija uma decisão e um nome conhecido não mude por baixo de você.
- **Tratar um nome de pacote no código de um modelo como entrada não confiável**, igual a uma URL na
  resposta dele.
- **Ficar atento ao mesmo nome inventado se repetindo.** Uma sugestão errada uma vez é ruído; uma errada
  do mesmo jeito para muitos desenvolvedores é o nome que alguém vai registrar.

## Links também são nomes

O `out-6` da aula 9 tinha um link para `pay-tarefa.example`, um host que parecia o da Tarefa. Um modelo
que inventa um link plausível produz o mesmo risco que um que inventa um pacote: um nome que outra pessoa
pode possuir. A lista de hosts da aula 9 é a mesma defesa que o snapshot de registro daqui, uma para o
navegador do cliente e outra para a máquina de quem desenvolve.
