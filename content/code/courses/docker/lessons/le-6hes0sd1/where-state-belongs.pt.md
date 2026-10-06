---
title: Onde mora cada tipo de estado
version: 1
---

**Trate todo container como algo que você vai apagar, e ponha cada tipo de estado num lugar que
sobreviva a ele.** É essa regra que torna os containers úteis: um container que não guarda nada próprio
pode ser trocado por um novo, de uma imagem nova, em qualquer máquina, a qualquer hora, e ninguém
precisa lembrar o que havia dentro do antigo.

"Estado" não é uma coisa só. Cada tipo tem o seu lugar certo:

| o quê | onde mora | aula |
| --- | --- | --- |
| dados que a aplicação possui: um banco, arquivos enviados | um volume nomeado | 8 |
| arquivos que você edita no host enquanto desenvolve | um bind mount | 8 |
| configuração que muda entre notebook e produção | variáveis de ambiente ou um arquivo montado, no `docker run` | 17 e 18 |
| segredos: senhas, chaves | um arquivo de segredo, nunca a imagem | 18 |
| logs | a saída padrão do container, recolhida pelo motor | 18 |
| o programa e as dependências dele | a imagem, construída a partir de um Dockerfile | 11 |
| caches e arquivos temporários | a camada de escrita, ou `tmpfs`; perdê-los não tem problema | 8 |

A última linha é o único tipo de estado para o qual a camada de escrita serve: coisas que podem
desaparecer.

## O atalho tentador: `docker commit`

Existe um comando que transforma a camada de escrita de um container numa imagem, e ele parece a
resposta a esta aula inteira. A Ana escreve outra nota no `notes` e faz o commit:

```
ana@vm:~$ docker exec notes sh -c "echo second note > /notes.txt"
ana@vm:~$ docker commit notes notes:snapshot
sha256:1f0cab8ec0bf8809da8da6dbbb0be953b90f9e904a4ab9bae4fc4dbcc6f0c9a0
ana@vm:~$ docker history notes:snapshot
IMAGE          CREATED                  CREATED BY                                      SIZE      COMMENT
1f0cab8ec0bf   Less than a second ago   sleep 3600                                      8.19kB    
5291449c3df7   2 weeks ago              CMD ["/bin/sh"]                                 0B        buildkit.dockerfile.v0
<missing>      2 weeks ago              ADD alpine-minirootfs-3.22.6-x86_64.tar.gz /…   8.97MB    buildkit.dockerfile.v0
```

Funciona: `notes:snapshot` é uma imagem, e um container iniciado a partir dela tem o arquivo. **E é o
hábito errado, por dois motivos visíveis nesse histórico.** A camada nova aparece descrita como
`sleep 3600`, o comando que o container estava rodando, então a imagem não registra nada sobre como o
`/notes.txt` chegou ali. Ninguém consegue reconstruí-la, revisá-la ou aplicar a mesma mudança à
próxima versão do Alpine. E ela captura tudo o que estiver na camada, inclusive o que mais algum
processo escreveu sem ninguém perceber.

O jeito de fazer uma imagem com um arquivo dentro é escrever os passos num Dockerfile, que a aula 11
começa. O `docker commit` tem um uso honesto: guardar o estado exato de um container quebrado para
investigar depois, como evidência e não como produto.

## Uma lista antes de confiar num container

Antes de remover qualquer container que esteja rodando há algum tempo, as respostas a três perguntas
decidem se algo se perde:

1. **O `docker diff` lista alguma coisa que importa?** Se sim, ela está na camada de escrita e vai
   junto com o container.
2. **As montagens dele incluem um volume anônimo?** O `docker inspect` as lista; um nome de hash quer
   dizer que ninguém o escolheu, e ele vai ficar órfão.
3. **Iniciar um container novo da mesma imagem, com as mesmas opções, daria o mesmo resultado?** Se
   não, alguma coisa deste container mora só nele, e é ela que precisa mudar de lugar.
