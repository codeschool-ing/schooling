---
title: Um bill of materials para cada imagem enviada
version: 1
---

Um SBOM feito à mão numa terça descreve a imagem de terça. **O que vale a pena ter é feito pelo
pipeline, para cada imagem que ele envia, a partir dessa imagem e de nada mais**, e guardado onde a
execução é guardada. Isso é mais um estágio, depois do `push`, para que ele descreva exatamente os bytes
que agora estão no registry.

### O estágio

Salve-o como `ci/sbom.sh`:

```sh
# The bill of materials of the image this run pushed, in CycloneDX and in
# SPDX, kept beside the run's logs.
set -euo pipefail
out=${CI_LOGS:-ci-logs}
syft -q "localhost:5000/linkbox:${CI_COMMIT:-dev}" \
  -o cyclonedx-json="$out/sbom.cdx.json" -o spdx-json="$out/sbom.spdx.json"
```

Há três decisões nessas seis linhas. Ele lê a imagem **do registry**, pela tag do commit desta execução,
então o SBOM descreve o que foi enviado e não o que por acaso está no Docker local. Ele escreve **os dois
formatos** numa execução do syft, que lê a imagem uma vez. E os escreve no diretório de logs da própria
execução, para que o SBOM de cada execução fique ao lado dos logs que dizem como aquela imagem foi
construída e checada.

A lista, com o estágio novo no fim, como `ci/stages`:

```
secrets
test
sast
sca
build
image
push
sbom
```

Ele vai por último porque descreve a imagem enviada; uma execução que quebrou antes do `push` não tem o
que descrever. E ele quebra o build se o syft falhar, de propósito: **uma imagem sem bill of materials é
uma imagem sobre a qual ninguém consegue responder perguntas depois**, e descobrir isso no dia do aviso é
tarde demais.

### A execução

Faça commit dos dois e envie para o CI:

```
ana@vm:~/linkbox$ git add ci/sbom.sh ci/stages
ana@vm:~/linkbox$ git commit -q -m "a bill of materials for every image pushed"
8:54AM INF 0 commits scanned.
8:54AM INF scanned ~286 bytes (286 bytes) in 182ms
8:54AM INF no leaks found
```

```
ana@vm:~/linkbox$ git push ci main
remote: run 1: main at 4e552d7        
remote: secrets: passed in 1s        
remote: test: passed in 2s        
remote: sast: passed in 3s        
remote: sca: passed in 10s        
remote: build: passed in 1s        
remote: image: passed in 1s        
remote: push: passed in 1s        
remote: sbom: passed in 6s        
remote: pipeline passed with 0 warning(s)        
remote: run 1: passed        
To /home/ana/ci/linkbox.git
   1d23ec6..4e552d7  main -> main
```

Os dois arquivos estão no diretório da execução, ao lado dos logs:

```
ana@vm:~/linkbox$ ls ~/ci/runs/1/logs
build.log
image.log
push.log
sast.log
sbom.cdx.json
sbom.log
sbom.spdx.json
sca.log
secrets.log
test.log
ana@vm:~/linkbox$ jq ".components | length" ~/ci/runs/1/logs/sbom.cdx.json
2190
```

### Onde guardar

**Ao lado da execução, por enquanto.** `~/ci/runs/N/logs` guarda o SBOM de cada execução, com o nome
apenas da execução, e o commit e a tag da imagem os amarram. Isso basta para responder "quais execuções
entregaram o packaging 26.3" com um laço sobre o diretório:

```
ana@vm:~/linkbox$ for f in ~/ci/runs/*/logs/sbom.cdx.json; do jq -r --arg f "$f" ".components[] | select(.name == \"packaging\") | \"\(\$f): \(.name) \(.version)\"" "$f"; done
/home/ana/ci/runs/1/logs/sbom.cdx.json: packaging 26.3
```

Há duas fraquezas que uma instalação de verdade precisa corrigir. O SBOM e a imagem vivem em lugares
diferentes, então uma cópia da imagem em outro lugar chega sem a lista; e nada prova que a lista foi
escrita pelo pipeline e não editada depois. **A aula 14 corrige as duas de uma vez**: ela assina o SBOM e
o anexa à imagem no registry como uma atestação, para que a lista viaje com a imagem e carregue a
assinatura do pipeline.

Organizações maiores também enviam todo SBOM para um serviço que os guarda e indexa, para que a
pergunta "quem tem o packaging 26.3" seja feita uma vez sobre as imagens de todos os times, e não uma vez
por diretório. O Dependency-Track, da OWASP, é o de código aberto mais comum. Ele não foi executado para
este curso; o que ele faz é o laço acima, na escala de uma empresa, com o scan da seção anterior feito
todo dia contra os avisos novos.

### O que o SBOM de uma imagem não vê

Um SBOM só é tão completo quanto os registros que o gerador encontra. O syft leu o banco de pacotes do
Debian e os diretórios `dist-info` do Python, e qualquer coisa instalada sem deixar um registro desses é
invisível para ele:

- **um binário copiado à mão**, um `COPY` de uma ferramenta baixada ou um `curl` num `RUN`, não tem
  registro de pacote, então aparece, na melhor das hipóteses, como um arquivo sem nome e sem versão;
- **código incorporado à aplicação**, uma biblioteca colada no `app.py`, é parte do linkbox para
  qualquer ferramenta;
- **o que a imagem faz em tempo de execução**, como um pacote instalado quando o container sobe, não está
  em camada nenhuma.

A árvore de código é outra medição, e não uma melhor:

```
ana@vm:~/linkbox$ syft -q dir:. | head -n 14
NAME          VERSION  TYPE                    
blinker       1.9.0    python  (+1 duplicate)  
click         8.1.7    python  (+1 duplicate)  
flask         3.1.3    python  (+1 duplicate)  
gunicorn      22.0.0   python  (+1 duplicate)  
iniconfig     2.3.1    python                  
itsdangerous  2.2.0    python  (+1 duplicate)  
jinja2        3.1.6    python  (+1 duplicate)  
markupsafe    2.1.3    python  (+1 duplicate)  
packaging     26.3     python                  
pluggy        1.7.0    python                  
pygments      2.21.0   python                  
pytest        9.0.3    python  (+1 duplicate)  
werkzeug      3.1.9    python  (+1 duplicate)
```

A partir do repositório, com o ambiente virtual que os testes criaram, o syft acha cada versão fixada
duas vezes (uma no `requirements.txt`, uma instalada em `.venv`), acha o pytest e as dependências dele,
que nunca chegam à imagem, e não acha nenhum pacote do Debian, porque a imagem base não está no
repositório. **Um SBOM descreve aquilo de que foi feito**, e o que roda é a imagem, e é por isso que o
estágio lê a imagem.
