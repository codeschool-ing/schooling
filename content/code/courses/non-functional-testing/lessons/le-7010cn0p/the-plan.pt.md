---
title: O plano de teste, uma categoria de cada vez
version: 1
---

Um plano de teste montado a partir do Top 10 é uma tabela com um bloco por categoria. Cada linha é
um caso de teste pequeno o bastante para falhar: uma requisição, a resposta que ela tem de receber,
e **o que a segura**. Essa última coluna é a que torna o plano honesto, porque ela só tem quatro
valores possíveis, e só um deles é um teste que já roda:

| o que segura a linha | significado |
|---|---|
| **um teste** | escrito, na suíte, e roda a cada mudança |
| **a escrever** | um teste poderia segurá-la e ninguém o escreveu ainda |
| **um scanner** | uma ferramenta dos cinco tipos da aula 16 a confere, num agendamento ou a cada mudança |
| **uma revisão** | só uma pessoa lendo o projeto, o código ou a implantação consegue julgá-la |

O plano abaixo cobre os dois serviços deste curso: a bilheteria da aula 1, na porta 8000, e o
serviço de contas da aula 16, na 8001. Os nomes de teste são os de `test_account.py` (aula 16),
`test_sessions.py` (aula 17), `test_vectors.py` (aula 20) e `test_owasp.py`, que esta aula
acrescenta.

## O plano

| | caso de teste | seguro por |
|---|---|---|
| **A01** | o token de um cliente não lê a reserva de outro cliente | um teste, aula 16 |
| | o token de um cliente não abre a lista da equipe; alguém da equipe abre | um teste, aula 17 |
| | um token no endereço é ignorado | um teste, aula 17 |
| | o token de formulário de um cliente não funciona para outro | um teste, aula 20 |
| | a bilheteria acredita em qualquer nome em `customer` que uma reserva traga | **uma revisão**: por projeto, ela não tem identidades |
| | nenhuma rota busca um endereço fornecido pelo usuário (falsificação de requisição do lado do servidor) | uma revisão: verdade hoje, a reconferir quando alguma buscar |
| **A02** | toda resposta traz `nosniff`, e `Server` não diz software nem versão | um teste, esta aula |
| | a página não pode ficar no frame de outro site | um teste, esta aula |
| | a página com as reservas de alguém pede aos caches que não guardem cópia | **achado em aberto F19-1**, um teste o marca |
| | o cabeçalho `Server` da bilheteria diz o software e a versão | uma revisão, um achado para a bilheteria |
| | só HTTPS, com `Strict-Transport-Security`, na implantação | uma revisão, e uma varredura DAST da homologação |
| **A03** | o `account.py` usa a biblioteca padrão do Python e nada mais | uma revisão |
| | nenhuma ferramenta do ambiente virtual tem um alerta publicado | um scanner, aula 21 |
| | todo download da instalação é fixado numa versão, vindo de quem a publica | uma revisão |
| **A04** | uma senha é guardada como hash scrypt com sal, nunca como ela mesma | um teste, aula 17 |
| | o banco não guarda nenhum token de sessão válido | um teste, aula 17 |
| | o cookie de sessão traz `Secure` quando o serviço estiver atrás de HTTPS | uma revisão da implantação |
| **A05** | uma aspa simples na busca é só texto | um teste, aula 16 |
| | marcação numa reserva volta escapada | testes, aulas 16 e 20 |
| | nenhum SQL é montado juntando strings | um scanner (SAST), e uma revisão |
| **A06** | cinco logins errados travam o nome, então qualquer um consegue travar qualquer um | **uma revisão**: uma decisão de projeto, aula 17 |
| | os casos de abuso de cada funcionalidade nova são escritos ao lado dos casos de uso | uma revisão |
| **A07** | o login para depois de cinco falhas | um teste, aula 17 |
| | um nome desconhecido recebe exatamente a resposta de uma senha errada | um teste, aula 17 |
| | uma sessão acaba no logout e na expiração | testes, aulas 16 e 17 |
| | o cadastro recusa uma senha com menos de 12 caracteres | **a escrever** |
| **A08** | um upload é conferido pelo conteúdo, guardado com um nome aleatório e nunca servido | testes, aulas 16 e 20 |
| | nenhum corpo de requisição é lido com outra coisa que não `json.loads` | uma revisão |
| | nenhum commit acrescenta um segredo | um scanner, o hook e o pipeline da aula 18 |
| **A09** | um login errado é registrado com o nome e sem a senha | um teste, esta aula |
| | uma recusa é registrada com a conta que pediu e o que ela pediu | um teste, esta aula |
| | um nome não consegue escrever uma linha de log própria | um teste, esta aula |
| | um login bem-sucedido é registrado | **achado em aberto F19-3**: não é |
| | uma rajada de recusas ou de travamentos alerta alguém | uma revisão hoje, aula 24 |
| **A10** | um corpo malformado recebe `400` | um teste, esta aula |
| | um erro inesperado responde uma frase simples e nenhum rastro | testes, aula 16 e esta aula |
| | um `Content-Length` que não é número recebe `400` | **achado em aberto F19-2**, um teste o marca |
| | um erro dentro da verificação de sessão recusa em vez de deixar passar | uma revisão: o `guarded` responde `500`, nunca a rota |

## Lendo o plano

**Conte a coluna, não as linhas.** Das trinta e oito linhas acima, dezenove são seguras por um teste
que roda a cada mudança, e a maior parte deles foi escrita nas aulas 16, 17 e 20, antes de este
plano existir: a lista os confirma em vez de inventá-los. Isso é normal, e é também o motivo de
montar o plano, porque ele mostra onde está o resto.

- **As revisões não são falhas do plano.** A A06 não tem teste porque um teste confere que o código
  faz o que foi decidido, e Insecure Design trata do que foi decidido. Uma pessoa lê a decisão e diz
  se ela se sustenta; o exercício final da aula 17 foi uma dessas leituras, e a bilheteria acreditar
  em qualquer nome que recebe é outra.
- **Os scanners cobrem as linhas que são iguais em toda aplicação**: uma biblioteca com um alerta,
  um segredo num commit, SQL montado juntando strings. As aulas 18 e 21 rodam dois deles.
- **As linhas marcadas *a escrever* são uma dívida com nome.** O tamanho da senha é conferido pelo
  `register` hoje, e nada notaria se ele deixasse de ser conferido.
- **Os achados em aberto são defeitos que o plano encontrou**, e a próxima seção mostra cada um. Um
  plano de teste que não encontra nada novo foi escrito para descrever o sistema, não para testá-lo.

O plano é revisto de novo sempre que o sistema ganha uma funcionalidade, que é quando as linhas
dele envelhecem: no dia em que o `account.py` buscar um endereço, a linha de falsificação de
requisição do lado do servidor da A01 precisa ser testada em vez de revisada.
