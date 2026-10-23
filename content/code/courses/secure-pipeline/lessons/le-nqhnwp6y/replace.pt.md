---
title: O terceiro movimento, substituir uma dependência
version: 1
---

Atualizar pressupõe que haja para o que atualizar. Às vezes não há: o aviso não tem versão corrigida
e os mantenedores dizem que não haverá. A aula 7 encontrou exatamente esse caso, uma branch que
acrescentava `ecdsa==0.19.2` e um aviso sem correção, e o gate alertou em vez de quebrar, porque
ninguém podia agir naquele dia. **Um alerta que nunca pode sumir é uma decisão adiada**, e a decisão é
o terceiro movimento.

### O que o PyPI diz sobre o ecdsa

O histórico de releases, e os avisos que os dados de vulnerabilidade do próprio PyPI listam para a
versão que a aula 7 usou:

@@FENCE 1@@

Um aviso com três nomes, CVE, GHSA e PYSEC, e nada em `fixed_in`. O texto explica o porquê: um canal
lateral de tempo na assinatura, e **"The python-ecdsa project considers side channel attacks out of
scope for the project and there is no planned fix."**, ou seja, o projeto considera ataques de canal
lateral fora do escopo e não planeja correção. É uma declaração honesta e uma posição legítima para
uma biblioteca em Python puro, e diz exatamente o que o projeto vai e não vai fazer por você.

O histórico recente do repositório responde à segunda pergunta de saúde, quem o mantém:

@@FENCE 2@@

Um merge em junho, e no último ano uma pessoa escreveu a maior parte dos commits que não são merge. É
um projeto mantido, por um grupo pequeno, com um escopo declarado. **Nada aqui diz que o pacote foi
abandonado; diz que a correção de que você precisa está fora do que ele promete.**

### Decidindo

O texto do aviso é preciso sobre onde está o risco, e isso decide o movimento:

| o que o serviço faz com ECDSA | o aviso se aplica? | o movimento |
|---|---|---|
| só verifica assinaturas que outra parte fez | não: o texto diz que a verificação não é afetada | manter, fixado, com o motivo escrito nas exceções do gate |
| assina com uma chave que ele guarda | sim | substituir |
| assina só para conferir as próprias mensagens depois | sim | substituir, e perguntar se uma assinatura é mesmo necessária |

A última linha é comum e merece um momento. Se um serviço assina uma mensagem só para que o mesmo
serviço confie nela depois, ninguém mais a verifica, e o que ele precisa é de um **código de
autenticação de mensagem** (MAC): o `hmac` da biblioteca padrão, com `hmac.compare_digest` para
comparar, que a aula 3 já usou para o token do linkbox. Nenhuma dependência é o melhor substituto que
existe.

Quando uma assinatura de verdade é necessária, o substituto é o pacote `cryptography`, mantido pela
Python Cryptographic Authority, cujo código de curvas elípticas roda no OpenSSL em vez de em Python. A
mesma operação que o linkbox teria feito com o `ecdsa`, como `~/scratch/sign.py`:

@@FENCE 3@@

Rodado num ambiente descartável, para nada ser acrescentado ao linkbox:

@@FENCE 4@@

### O que uma substituição custa

**Substituir é o mais caro dos três movimentos**, e por isso vem por último. Mexe em código, não só
num lock: toda chamada muda, os testes que cobriam a biblioteca antiga precisam cobrir a nova, e a
dependência nova traz as próprias perguntas de saúde, os próprios avisos e, no caso do
`cryptography`, wheels compiladas para cada plataforma em que você implanta. O histórico de releases
dela no PyPI é a mesma checagem que esta aula fez para o gunicorn, e vale fazê-la antes do primeiro
import.

Então a ordem se mantém. **Fixe sempre, atualize por padrão, e substitua quando o projeto tiver dito,
por escrito, que não vai corrigir o que importa para você.** O linkbox não precisava do `ecdsa` em
`main`, e a branch que o acrescentou nunca entrou; o argumento acima é o que um time escreveria no
pull request que o remove.
