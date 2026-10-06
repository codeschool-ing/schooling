---
title: Além da tríade
version: 1
---

A tríade é o núcleo, e não é o vocabulário inteiro. Quatro palavras aparecem o tempo todo, e cada
uma responde a uma pergunta que as três letras deixam em aberto.

**Autenticidade** é saber que a informação veio mesmo de onde diz ter vindo. Um e-mail "do banco"
que não é do banco falha em autenticidade mesmo que nada nele tenha sido alterado depois de
escrito. Integridade pergunta se algo mudou no caminho; autenticidade pergunta quem escreveu, para
começar.

**Não repúdio** é poder provar a um terceiro que alguém fez algo, de modo que a pessoa não possa
negar depois. Um contrato assinado tem isso. Uma mensagem que qualquer um com a senha compartilhada
poderia ter mandado, não. Assinaturas digitais (aula 6 de `cryptography`) existem em grande parte
para dar isso.

**Responsabilização** (*accountability*) é poder rastrear cada ação até a pessoa ou o sistema que
a fez. Ela precisa de duas coisas: que cada pessoa tenha a própria conta (a aula 8 chama isso de
identificação), e que as ações fiquem registradas num lugar que a pessoa não consiga apagar. Uma
conta `admin` compartilhada destrói a responsabilização mesmo que ninguém abuse dela, porque quando
algo dá errado ninguém consegue dizer quem fez.

**Privacidade** diz respeito à pessoa que os dados descrevem, e não à organização que os guarda.
Uma empresa pode manter a lista de clientes perfeitamente confidencial e ainda assim violar a
privacidade, coletando mais do que precisa ou usando os dados para uma finalidade com que o cliente
nunca concordou. A aula 17 trata do que a LGPD exige.

### As mesmas três, vistas do lado do atacante

Há quem ache mais fácil pensar no que dá errado. A **tríade DAD** nomeia as três falhas que
espelham as propriedades CIA:

| propriedade CIA | falha DAD | na livraria |
|---|---|---|
| confidencialidade | **divulgação** (*disclosure*) | a lista de clientes é publicada num fórum |
| integridade | **alteração** (*alteration*) | os preços são mudados no banco |
| disponibilidade | **destruição** (*destruction*, ou negação) | um ransomware cifra o servidor |

As duas tríades descrevem o mesmo terreno. CIA é como um defensor enuncia um objetivo; DAD é como
um relatório de incidente enuncia o que aconteceu. Ao ler o relato de um incidente, pergunte qual
das três propriedades se perdeu, porque isso diz quais controles falharam ou faltavam.

Mais um nome que você vai encontrar é o **hexágono parkeriano** (*Parkerian hexad*), proposto por
Donn Parker em 1998. Ele mantém as três e acrescenta posse (o controle sobre os dados, mesmo sem
leitura: uma fita de backup roubada), autenticidade e utilidade (os dados estão lá, mas inúteis,
como um arquivo cifrado sem a chave). É menos comum nas normas, e nada neste curso depende dele.
