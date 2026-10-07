---
title: Ofuscação esconde do leitor casual, e de mais ninguém
version: 1
---

**Ofuscação transforma dados para que fiquem difíceis de ler de relance, por um método escrito no
próprio software que os lê.** Ela só tem "chave" no sentido de que o programa conhece o truque. Quem
tem o programa, ou o manual dele, ou um exemplo, também tem o truque.

## A senha "protegida" de um fornecedor

O sistema de agendamento da Vereda é um produto comprado de um fornecedor. O arquivo de configuração
dele guarda a senha do banco "protegida", e isto grava o arquivo no laboratório:

```sh
cd ~/lab
cat > data/scheduler.ini <<'EOF'
[database]
host = db.vereda.example
user = scheduler
; password is protected (ROT13 then Base64, see the vendor's manual)
password = SS1xby1mM3BlcmctMjAyNg==
EOF
```

O comentário diz qual é a proteção, porque o próprio manual do fornecedor diz. Desfazendo o segundo
passo:

```
ana@lab:~/lab$ grep '^password' data/scheduler.ini | cut -d' ' -f3 | base64 -d; echo
I-qo-f3perg-2026
```

Ainda não é a senha, mas é claramente uma versão deslocada de uma: mesmo formato, mesmos dígitos,
letras andando pelo alfabeto. O ROT13 troca cada letra pela que está treze posições adiante, então
aplicá-lo de novo o desfaz:

```
ana@lab:~/lab$ grep '^password' data/scheduler.ini | cut -d' ' -f3 | base64 -d | tr 'A-Za-z' 'N-ZA-Mn-za-m'; echo
V-db-s3cret-2026
```

Dois comandos e nenhuma chave. Toda instalação do sistema de agendamento, em toda clínica do país,
"protege" a senha do mesmo jeito, então aprender o truque uma vez abre todas.

## Onde a ofuscação aparece

- **Arquivos de configuração** com senhas "cifradas" cuja chave é uma constante dentro do produto.
  Algumas são XOR com uma sequência fixa de bytes, outras são AES com uma chave compilada no binário.
  Nos dois casos a chave vai junto em toda cópia e é extraída uma vez, por alguém, e publicada.
- **JavaScript minificado ou ofuscado** numa página web. Ele é entregue ao navegador de todo
  visitante, então qualquer coisa nele, inclusive uma chave de API, é pública.
- **Apps de celular** que escondem uma chave de API dentro do app compilado. Um descompilador a
  recupera.
- **"Codificação proprietária"** num formato de arquivo, que a aula 17 chama pelo nome certo: criar o
  próprio algoritmo.

## A ofuscação vale alguma coisa?

Ela aumenta o esforço de um leitor casual, e é só isso que ela faz. É razoável para coisas que nunca
foram secretas, como deixar uma verificação de licença um pouco mais trabalhosa de remover, ou
impedir um colega de ler uma senha por cima do seu ombro. Ela nunca é um controle numa avaliação de
risco, porque a força dela é o tempo que alguém leva para buscar o nome do fornecedor junto com a
palavra "decrypt". Quando um auditor acha uma senha ofuscada, o achado é escrito como **senha em
texto claro na configuração**.
