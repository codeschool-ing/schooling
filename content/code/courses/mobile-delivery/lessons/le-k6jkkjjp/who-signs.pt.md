---
title: Quem assina: o Xcode, uma ferramenta ou um serviço
version: 1
---

**A maioria das equipes não deveria gerenciar certificados e perfis à mão, e a pergunta é só qual
máquina faz isso por ela.** Três respostas são comuns, uma por tipo de equipe. *Nenhuma foi rodada
para este curso: elas precisam de um Mac, de uma conta Apple ou dos dois.*

## A assinatura automática do Xcode

Marque **Automatically manage signing** na aba *Signing & Capabilities* do target, escolha a
equipe, e o Xcode cria o certificado, registra o App ID e o aparelho, e baixa um perfil. Para um
desenvolvedor num Mac, essa é a resposta certa e não precisa de mais nada.

Ela deixa de ser a resposta certa no dia em que há dois Macs ou um pipeline. Cada Mac cria o seu
próprio certificado de desenvolvimento, a chave privada do certificado de distribuição mora no
chaveiro de quem o criou, e um servidor de build não tem uma pessoa para clicar em *Fix Issue*.

## Um conjunto compartilhado, guardado em outro lugar

O **fastlane match** guarda os certificados e perfis da equipe criptografados num repositório git
privado ou num bucket na nuvem, e toda máquina, inclusive o pipeline, busca o mesmo conjunto em vez
de criar o seu. Uma pessoa os cria uma vez; as outras só leem. A lição 11 roda o Fastlane, e a lição
10 é onde um pipeline precisa disso.

```
# Matchfile: one encrypted set of certificates and profiles for the whole team
git_url("https://git.example.com/planner-certificates.git")
type("appstore")
app_identifier("com.example.planner")
```

## Um serviço que guarda as credenciais

O **EAS do Expo** gera ele mesmo o certificado de distribuição e os perfis, guarda-os nos seus
servidores e assina nos Macs hospedados dele. Para uma equipe de React Native sem Mac, é o desvio
que a lição 10 nomeia. O **Xcode Cloud**, serviço da própria Apple, faz o mesmo para um projeto
Xcode. O preço dos dois é o mesmo: as credenciais ficam com outra pessoa, e você confia ao controle
de acesso dela a sua capacidade de publicar.

```json
{
  "build": {
    "production": {
      "ios": { "credentialsSource": "remote" }
    }
  }
}
```

Essa é a parte do `eas.json` que diz "o EAS guarda as credenciais"; `local` significaria que você
as fornece a partir de um arquivo.

## O Android, para comparar

O Android tem a mesma divisão com menos cerimônia. O assistente *Generate Signed Bundle* do Android
Studio é a resposta de "um desenvolvedor"; o bloco `signingConfigs` do Gradle lendo o caminho de um
keystore e as senhas do ambiente é a resposta de "pipeline"; e o Play App Signing, da lição 1, já é
um serviço guardando a chave que importa.

```kotlin
// build.gradle.kts: the release build reads its upload key from the environment
android {
    signingConfigs {
        create("release") {
            storeFile = file(System.getenv("UPLOAD_KEYSTORE") ?: "upload.jks")
            storePassword = System.getenv("UPLOAD_PASS")
            keyAlias = "upload"
            keyPassword = System.getenv("UPLOAD_PASS")
        }
    }
    buildTypes { getByName("release") { signingConfig = signingConfigs.getByName("release") } }
}
```
