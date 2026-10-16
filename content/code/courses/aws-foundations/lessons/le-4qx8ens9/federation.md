---
title: Federated identities, signed in somewhere else
version: 1
---

**A federated identity is a principal that AWS did not create and does not hold a credential
for.** Somebody else signs it in, an identity provider such as GitHub, Google or the company's
directory, and hands it a signed statement. AWS checks the signature, finds a role whose trust
policy accepts that statement, and gives back a role session like the one in the previous section.
The wrong picture is that federation makes IAM users for outside people. **No IAM user is created
and no long-term key exists on AWS's side**, which is the whole point: the password stays with the
provider, and the session dies on its own.

Two standards carry the statement, and IAM has a kind of provider for each:

| | **OpenID Connect (OIDC)** | **SAML 2.0** |
|---|---|---|
| the statement | a JSON web token, signed by the provider | an XML assertion, signed by the provider |
| typical provider | GitHub Actions, Google, a Kubernetes cluster | a corporate directory: Entra ID, Okta, AD FS |
| the STS call | `AssumeRoleWithWebIdentity` | `AssumeRoleWithSAML` |
| IAM resource | `oidc-provider/<host>` | `saml-provider/<name>` |

For people, the usual answer today is IAM Identity Center, which speaks SAML to the directory once
and manages the roles for you; lesson 11 is about it. **For a machine outside AWS, OIDC is the
answer**, and the shop's deployer is the example.

## GitHub Actions as an OIDC provider

Every GitHub Actions run can ask GitHub for a token, signed by the issuer
`token.actions.githubusercontent.com`, that says which repository, branch and workflow it is. IAM
is told to trust that issuer once per account:

```
ana@laptop:~/aws$ aws iam create-open-id-connect-provider --url https://token.actions.githubusercontent.com --client-id-list sts.amazonaws.com
{
    "OpenIDConnectProviderArn": "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
}
ana@laptop:~/aws$ aws iam get-open-id-connect-provider --open-id-connect-provider-arn arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com
{
    "Url": "token.actions.githubusercontent.com",
    "ClientIDList": [
        "sts.amazonaws.com"
    ],
    "ThumbprintList": [],
    "CreateDate": "2026-10-16T16:06:33.079357+00:00",
    "Tags": []
}
```

`sts.amazonaws.com` is the **audience**: the token has to say it was minted for AWS, so a token
GitHub made for some other service is refused. `--thumbprint-list` was left out on purpose; AWS's
reference for the command says IAM then fetches the provider's certificate thumbprint itself, and
moto stored an empty list.

Now `deployer` can trust GitHub instead of bia. This trust policy replaces the one from the
previous section; save it as `~/aws/deployer-github.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub": "repo:shop/web:ref:refs/heads/main"
        }
      }
    }
  ]
}
```

**The `sub` line is the one that matters.** Every workflow in every repository on GitHub gets its
tokens from the same issuer, so a trust policy with only the `aud` line trusts all of them,
strangers included. `repo:shop/web:ref:refs/heads/main` narrows it to the `main` branch of the
shop's `web` repository. `Principal` says `Federated` instead of `AWS`, and the action is the
web-identity one.

```
ana@laptop:~/aws$ aws iam update-assume-role-policy --role-name deployer --policy-document file://deployer-github.json
ana@laptop:~/aws$ aws iam get-role --role-name deployer --query "Role.AssumeRolePolicyDocument.Statement[0].Principal"
{
    "Federated": "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
}
```

A workflow would now call `AssumeRoleWithWebIdentity` with its token. **That call is not signed
with any AWS key**, because the token is the credential, so the command line can send it with
`--no-sign-request`. In moto, with a token that is plainly not one:

```
ana@laptop:~/aws$ aws sts assume-role-with-web-identity --no-sign-request --role-arn arn:aws:iam::123456789012:role/deployer --role-session-name run-1207 --web-identity-token not-a-real-token --query "{User:AssumedRoleUser,Key:Credentials.AccessKeyId}"
{
    "User": {
        "AssumedRoleId": "ARO123EXAMPLE123:run-1207",
        "Arn": "arn:aws:sts::123456789012:assumed-role/deployer/run-1207"
    },
    "Key": "ASIARZPUZDIKB7J62LAY"
}
```

**moto handed out a session for a made-up token. AWS would refuse it**: it checks the token's
signature against the keys the provider publishes, its expiry, and then the `aud` and `sub`
conditions of the trust policy. None of that was run here. moto also fills `AssumedRoleId` with a
placeholder, `ARO123EXAMPLE123`, where AWS puts the role's own id. The shape of the answer is
AWS's, though: an `ASIA` key and an `assumed-role/deployer/...` session, with **no secret ever
stored in GitHub**.

## A SAML provider

A SAML provider is made from the identity provider's **metadata document**, an XML file the
directory exports, holding its name, its sign-in address and the certificate it signs with. The
command line refuses a document shorter than 1000 characters before sending anything:

```
ana@laptop:~/aws$ aws iam create-saml-provider --name shop-idp --saml-metadata-document '<EntityDescriptor entityID="https://idp.shop.example.com/saml"/>'

aws: [ERROR]: An error occurred (ParamValidation): Parameter validation failed:
Invalid length for parameter SAMLMetadataDocument, value: 64, valid min length: 1000
```

A believable one needs a certificate. These commands make a throwaway one with `openssl`, which
Ubuntu installs by default, and write a minimal metadata document around it, in `~/aws`:

```sh
openssl req -x509 -newkey rsa:2048 -nodes -days 365 -subj /CN=idp.shop.example.com \
  -keyout idp.key -out idp.crt 2>/dev/null
cert=$(grep -v CERTIFICATE idp.crt | tr -d '\n')
cat > idp-metadata.xml <<EOF
<EntityDescriptor xmlns="urn:oasis:names:tc:SAML:2.0:metadata" entityID="https://idp.shop.example.com/saml">
  <IDPSSODescriptor protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
    <KeyDescriptor use="signing">
      <KeyInfo xmlns="http://www.w3.org/2000/09/xmldsig#">
        <X509Data><X509Certificate>$cert</X509Certificate></X509Data>
      </KeyInfo>
    </KeyDescriptor>
    <SingleSignOnService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect"
                         Location="https://idp.shop.example.com/saml/sso"/>
  </IDPSSODescriptor>
</EntityDescriptor>
EOF
```

```
ana@laptop:~/aws$ wc -c idp-metadata.xml
1668 idp-metadata.xml
ana@laptop:~/aws$ aws iam create-saml-provider --name shop-idp --saml-metadata-document file://idp-metadata.xml
{
    "SAMLProviderArn": "arn:aws:iam::123456789012:saml-provider/shop-idp"
}
ana@laptop:~/aws$ printf '%1000s' '' > blank.xml; aws iam create-saml-provider --name blank --saml-metadata-document file://blank.xml
{
    "SAMLProviderArn": "arn:aws:iam::123456789012:saml-provider/blank"
}
ana@laptop:~/aws$ aws iam list-saml-providers --query "SAMLProviderList[].Arn"
[
    "arn:aws:iam::123456789012:saml-provider/shop-idp",
    "arn:aws:iam::123456789012:saml-provider/blank"
]
```

A role for the directory's users would trust `saml-provider/shop-idp` as its `Federated`
principal, with the action `sts:AssumeRoleWithSAML`. **moto does not read the document**: a file of
1000 spaces was accepted the same way, by the third command above. AWS parses the metadata and
refuses a document it cannot read; that was not run here.

## What the account holds now

```
ana@laptop:~/aws$ aws iam list-users --query "Users[].[UserName,UserId]" --output text
bia	js9pb6447kryw6le9a1i
caio	uamtq0s7tvnse8tqk0us
dani	c9jkpficj8fz3num8nga
ana@laptop:~/aws$ aws iam list-roles --query "Roles[].[RoleName,RoleId,Arn]" --output text
deployer	AROARZPUZDIKPPMZN5TQR	arn:aws:iam::123456789012:role/deployer
ana@laptop:~/aws$ aws iam list-open-id-connect-providers --query "OpenIDConnectProviderList[].Arn" --output text
arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com
```

Three users, one role, one OIDC provider and the two SAML providers. **Only bia holds a credential
that lasts**, a password and an access key. caio and dani have none yet, the role has none by
construction, and the sessions GitHub would receive end on their own.

## Which principal, for whom

| who needs AWS | the principal | where in this course |
|---|---|---|
| a person in the company | federation through IAM Identity Center, ending in a role session | lesson 11 |
| a program running on AWS | a role, handed to the machine | lesson 10 |
| a pipeline outside AWS | an OIDC provider and a role, as above | this lesson |
| another company's account | a role it may assume, with an external id | lesson 9 |
| a program that can do nothing else | an IAM user with an access key, rotated | lesson 12 |
| closing the account, the support plan | the root user, with MFA | lesson 1 |

**Read down the second column and roles are almost everywhere.** IAM users with keys are the last
row but one, and the root user the last, which is the order of preference too.
