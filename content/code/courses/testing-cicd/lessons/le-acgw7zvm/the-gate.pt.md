---
title: A barreira antes da produção
version: 1
---

Entre a homologação e a produção fica a **barreira** (*gate*): o ponto em que alguém, ou algo, decide
que este artefato segue adiante. Na entrega contínua, a barreira costuma ser uma pessoa aprovando um
release que o pipeline já provou implantável. Na implantação contínua, é uma regra: toda verificação
verde, e a mudança vai sozinha.

## O que atravessa a barreira é o artefato

A decisão é sobre **um artefato específico**, identificado pelo hash, e o que chega à produção precisa
ser esse artefato e mais nada. O `deploy.sh` confere o hash antes de desempacotar qualquer coisa. Aqui
uma cópia do artefato ganha um byte a mais no caminho para a produção:

```
ana@laptop:~/shipquote$ ops/deploy.sh production /tmp/shipquote-1.4.0.tar.gz; echo "exit status $?"
shipquote-1.4.0.tar.gz: FAILED
sha256sum: WARNING: 1 computed checksum did NOT match
exit status 1
```

O `sha256sum` calculou um hash que não bate com o que o build gravou, disse `FAILED`, e o deploy parou
com código de saída 1 antes de tocar no ambiente. Um byte mudado por um download quebrado, um erro de
disco ou a edição de alguém é pego do mesmo jeito. Depois o artefato verdadeiro passa:

```
ana@laptop:~/shipquote$ ops/deploy.sh production dist/shipquote-1.4.0.tar.gz
smoke: http://127.0.0.1:8300 is up and running 1.4.0
ana@laptop:~/shipquote$ for port in 8200 8300; do curl -s http://127.0.0.1:$port/version; echo; done
{"version": "1.4.0", "env": "staging"}
{"version": "1.4.0", "env": "production"}
```

Homologação e produção agora rodam **o mesmo release, 1.4.0**, e diferem só no ambiente. Nada foi
remontado para a produção; os bytes que passaram pela homologação são os bytes que rodam lá.

## Onde a barreira mora num serviço hospedado

O GitHub Actions modela isso com **environments**: um job que declara `environment: production` espera
até as regras de proteção do ambiente serem satisfeitas, como aprovação por revisores nomeados, um
tempo de espera, ou deploy só a partir da `main`. O ambiente também pode guardar segredos próprios,
disponíveis só para jobs que passaram pelas regras dele, o que a aula 9 usa. O GitLab tem a mesma
ideia com o mesmo nome, com ambientes protegidos e aprovações de deploy.

```yaml
  production:
    needs: staging
    runs-on: ubuntu-24.04
    environment: production
    steps:
      - run: ops/deploy.sh production dist/shipquote-1.4.0.tar.gz
```

Esse trecho é um esboço, e não faz parte do workflow do `shipquote`: o laboratório não tem
repositório no GitHub nem produção para o job alcançar.

## Para que serve uma pessoa na barreira

Uma aprovação sempre dada não é barreira; é atraso. Vale ter uma pessoa na barreira quando ela **sabe
algo que o pipeline não sabe**: que uma campanha de marketing começa em uma hora, que a transportadora
está migrando a API hoje à noite, que a equipe de atendimento está desfalcada. Se todo motivo para
esperar pode ser escrito como verificação, escreva como verificação, e a barreira pode virar uma
regra. É assim que equipes passam da entrega para a implantação: uma decisão de cada vez, conforme
cada uma fica automatizável.
