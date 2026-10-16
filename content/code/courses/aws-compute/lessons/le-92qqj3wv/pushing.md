---
title: Pushing, and what a push is made of
version: 1
---

`docker push` looks like one upload of one thing called the image. **It is a sequence.** The
registry is asked which layers it already has, and the missing ones are uploaded one at a time.
Last of all comes a small JSON file, the manifest, that lists them. What the registry calls the
image is that manifest, and the digest that names the image is the manifest's own hash. This
section builds an image, takes it apart, and gives moto the one piece of a push that moto
understands.

## An image to push

Docker is the one the `docker` course installs, and the web server image is the one lesson 8 ran.
If it is not on your machine yet, pull it once:

```sh
docker pull nginx:1.29-alpine
```

The image this lesson pushes is that web server with a page of its own. Two files in a directory
`web` beside your terminal: the page, written by the first command below, and this Dockerfile:

```dockerfile
# web/Dockerfile
FROM nginx:1.29-alpine
COPY index.html /usr/share/nginx/html/index.html
```

```
ana@laptop:~/aws$ echo '<h1>shop 1.0.0</h1>' > web/index.html
ana@laptop:~/aws$ docker build -q --provenance=false -t shop/web:1.0.0 web
sha256:dd3256cc31f2bad262adcc72ff42e9868bb9371c066dc39934c050dd1f1adf47
ana@laptop:~/aws$ docker tag shop/web:1.0.0 123456789012.dkr.ecr.sa-east-1.amazonaws.com/shop/web:1.0.0
ana@laptop:~/aws$ docker image ls --format '{{.Repository}}:{{.Tag}}  {{.ID}}' | grep shop/web
123456789012.dkr.ecr.sa-east-1.amazonaws.com/shop/web:1.0.0  dd3256cc31f2
shop/web:1.0.0  dd3256cc31f2
```

`--provenance=false` keeps the image to one manifest. Without it, Docker 29 attaches a provenance
attestation, a signed record of how the image was built, and the image becomes an index of two
manifests. That is a good default for a real pipeline and a distraction when taking one image
apart. `docker tag` gave the same image a second name, and **the two names share one id**:
tagging copies nothing.

## The push, as AWS documents it

On AWS, these are the two commands that send the image. **They were not run for this lesson**,
because moto answers ECR's API, the JSON calls the AWS command line makes, and not the registry
protocol that `docker login`, `docker push` and `docker pull` speak. There is nothing on port 4567
for Docker to push to.

```sh
aws ecr get-login-password --region sa-east-1 |
  docker login --username AWS --password-stdin 123456789012.dkr.ecr.sa-east-1.amazonaws.com
docker push 123456789012.dkr.ecr.sa-east-1.amazonaws.com/shop/web:1.0.0
```

The first half of the login is an API call, so moto does answer it:

```
ana@laptop:~/aws$ aws ecr get-login-password
123456789012-auth-token
ana@laptop:~/aws$ aws ecr get-authorization-token --query 'authorizationData[0].[proxyEndpoint,expiresAt]'
[
    "https://123456789012.dkr.ecr.sa-east-1.amazonaws.com",
    "2014-12-31T23:00:00-03:00"
]
```

On AWS the password is a token made from your IAM credentials and **valid for 12 hours**, which is
why a pipeline logs in again on every run instead of storing a password. The user name is always
the literal word `AWS`. moto prints a fixed string and an expiry in 2014, and both are
placeholders: no token from moto would open a real registry, and none is needed here.

What `docker push` then does is in ECR's API reference, call by call. `BatchCheckLayerAvailability`
asks which of the image's layers the repository already holds. For each one it does not,
`InitiateLayerUpload`, `UploadLayerPart` and `CompleteLayerUpload` send it. Then `PutImage` is
called **once**, with the manifest and the tag. A layer the registry already has is skipped, so
the second push of an image that changed one small file sends very little.

## The manifest, taken out of the image

The manifest is inside the image Docker already has, and `docker save` writes the image out as an
archive of blobs named by their digests:

```
ana@laptop:~/aws$ docker image inspect --format '{{.Id}}' shop/web:1.0.0
sha256:dd3256cc31f2bad262adcc72ff42e9868bb9371c066dc39934c050dd1f1adf47
ana@laptop:~/aws$ D=$(docker image inspect --format '{{.Id}}' shop/web:1.0.0 | cut -d: -f2)
ana@laptop:~/aws$ docker save shop/web:1.0.0 | tar -xO "blobs/sha256/$D" > manifest.json
ana@laptop:~/aws$ jq '{mediaType, config: .config.digest, layers: [.layers[].size]}' manifest.json
{
  "mediaType": "application/vnd.oci.image.manifest.v1+json",
  "config": "sha256:1b730d61533d59a77f6755c7ae771d67f67966d82328658de4d7a34d869a15a5",
  "layers": [
    3864189,
    1870921,
    627,
    956,
    404,
    1210,
    1399,
    20248489,
    231
  ]
}
ana@laptop:~/aws$ sha256sum manifest.json
dd3256cc31f2bad262adcc72ff42e9868bb9371c066dc39934c050dd1f1adf47  manifest.json
```

**The image's id is the manifest's digest, and the digest is the SHA-256 of the manifest's
bytes.** `sha256sum` printed the same 64 characters `docker image inspect` did. Nothing else
decides it, so two people who build the same bytes get the same digest, and changing one byte
anywhere changes it.

The manifest lists one config and nine layers. The first eight are `nginx:1.29-alpine`'s own
layers, byte for byte, and they add up to 25,988,195 bytes. The ninth is the `COPY` line of the
Dockerfile, and its 231 bytes are a compressed archive holding `index.html`. **Those 25,988,426
bytes, about 26 MB, are what ECR stores and what it charges for**, because a registry keeps
layers compressed; `docker image ls` reports the larger, unpacked size.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"A tag and a digest both point at one manifest. The manifest lists a config and nine layers by digest: eight layers of nginx:1.29-alpine totalling 25,988,195 bytes and one of 231 bytes added by COPY. A push uploads the layers and the config first and the manifest last.\"><defs><marker id=\"ecr-anat-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"110\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a tag, which you choose</text><rect x=\"20\" y=\"44\" width=\"180\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"110\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">shop/web:1.0.0</text><text x=\"110\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a digest, which is computed</text><rect x=\"20\" y=\"132\" width=\"180\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"110\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">sha256:…</text><text x=\"110\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the sha256 of the manifest</text><rect x=\"258\" y=\"44\" width=\"190\" height=\"128\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"353\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">manifest</text><text x=\"353\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a short JSON file</text><text x=\"353\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">listing every piece</text><text x=\"353\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">by its digest</text><path d=\"M200 64 L256 84\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#ecr-anat-ah)\"></path><path d=\"M200 152 L256 132\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#ecr-anat-ah)\"></path><rect x=\"500\" y=\"30\" width=\"200\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"600\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">config</text><text x=\"600\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">command, ports, environment</text><rect x=\"500\" y=\"92\" width=\"200\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"600\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">8 layers of nginx:1.29-alpine</text><text x=\"600\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">25,988,195 bytes, compressed</text><rect x=\"500\" y=\"154\" width=\"200\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"600\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">1 layer from COPY index.html</text><text x=\"600\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">231 bytes</text><path d=\"M448 80 L498 56\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#ecr-anat-ah)\"></path><path d=\"M448 108 L498 116\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#ecr-anat-ah)\"></path><path d=\"M448 140 L498 176\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#ecr-anat-ah)\"></path><path d=\"M40 250 L680 250\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"360\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">a push sends the blobs on the right first, then the manifest, which carries the tag</text></svg>", "caption": "What an image is to a registry. The tag and the digest both point at one manifest, and the manifest points at everything else by digest. Change one byte of a layer and its digest changes, so the manifest's does too."}
```

## The one part moto takes

`PutImage` is an API call, so moto accepts it:

```
ana@laptop:~/aws$ aws ecr put-image --repository-name shop/web --image-tag 1.0.0 --image-manifest file://manifest.json --query image.imageId
{
    "imageDigest": "sha256:11e030171210d110509505b40732d187e3f6d9523af5a3083263a644563ce41f",
    "imageTag": "1.0.0"
}
ana@laptop:~/aws$ aws ecr describe-images --repository-name shop/web
{
    "imageDetails": [
        {
            "registryId": "123456789012",
            "repositoryName": "shop/web",
            "imageDigest": "sha256:11e030171210d110509505b40732d187e3f6d9523af5a3083263a644563ce41f",
            "imageTags": [
                "1.0.0"
            ],
            "imageSizeInBytes": 12552,
            "imagePushedAt": "2026-10-16T13:25:51-03:00",
            "imageManifestMediaType": "application/vnd.oci.image.manifest.v1+json"
        }
    ]
}
```

Read that answer against the manifest above and three things in it are moto's rather than AWS's.

**The digest is different.** moto computes its own, from the list of layer digests, where AWS's
digest is the manifest's SHA-256: the value `sha256sum` printed, and the one `docker push` reports
when it finishes. AWS also lets the caller state the digest it expects, and refuses the call with
`ImageDigestDoesNotMatchException` when the two disagree.

**`imageSizeInBytes` is the config's size in moto.** On AWS it is the compressed layers, the 26 MB
above.

**On AWS this call would have been refused.** None of the nine layers was ever uploaded, and
`PutImage` answers a manifest naming layers the repository does not hold with
`LayersNotFoundException`. moto stores manifests without layers, which is enough to study tags,
digests and policies, and not enough to pull anything back.

There is one job AWS documents for `PutImage` on its own: **giving an image that is already in the
repository another tag**, without pulling it or pushing it again. The manifest is fetched with
`aws ecr batch-get-image` and put back under the new tag, and the next section does exactly that.
