---
title: Root por padrão
version: 1
---

**A menos que a imagem diga outra coisa, o processo do container dela roda como root, o usuário 0.**
A aula 4 mostrou que o Docker não dá namespace de usuários aos containers por padrão, então esse root
é o root do host, contido só pelas outras paredes. Cada uma dessas paredes é uma linha de defesa; um
processo que não é root desde o começo é mais uma, e é a mais barata que existe.

A imagem da Ana da aula 13 não define usuário, e a base distroless sobre a qual ela é construída nomeia
o root explicitamente:

```
ana@vm:~/shelf$ docker build -q -t shelf:root .
sha256:7eab1a08a6c6e2a934a60fc48a9fd1e879587e0a813565a8ac95fe8902b75e3e
ana@vm:~/shelf$ docker image inspect shelf:root --format "User: [{{.Config.User}}]"
User: [0]
ana@vm:~/shelf$ docker run -d --name as-root shelf:root
4d3b4bf986ecae5f7071e19f5b89e732bbae5559df1e9a6fc05acf49985d90e0
ana@vm:~/shelf$ docker top as-root -o pid,uid,args
PID                 UID                 COMMAND
3105                0                   /shelf
```

`User: [0]`, e o `docker top` concorda: o `/shelf` roda com UID 0. Nada no `shelf` precisa disso. Ele
não lê arquivo protegido, escuta numa porta alta e não escreve nada em disco.

## Quanto custa ser root lá dentro

Root dentro de um container não é automaticamente root no host, porque namespaces, cgroups e as
restrições que a aula 21 cobre continuam valendo. **O que muda é quanto vale um único erro.** Três
exemplos, cada um uma classe real de incidente:

- **Um bind mount dá o poder do root sobre o diretório do host.** O container da aula 8 escreveu um
  arquivo do root na pasta pessoal da Ana; um container que montasse o `/etc` como root poderia
  reescrever a configuração do host.
- **Uma falha no kernel ou no runtime que deixe um processo passar pelas paredes o faz chegar ao host
  como o usuário que ele era.** Como root, isso é a máquina inteira. Como UID 65532, um usuário sem
  direito nenhum no host, é muito pouco.
- **Um bug no programa vira bug do root.** Se o `shelf` tivesse uma falha que deixasse uma requisição
  escrever um arquivo escolhido pelo atacante, o root poderia escrevê-lo em qualquer lugar do sistema
  de arquivos do container, inclusive por cima do próprio programa.

Nenhum desses depende do root para ser útil a um atacante, e cada um deles fica pior com ele. Esse é o
argumento inteiro da próxima etapa, e é por isso que o Kubernetes, na aula 25 do curso `kubernetes`,
consegue se recusar a iniciar um container que rodaria como root.
