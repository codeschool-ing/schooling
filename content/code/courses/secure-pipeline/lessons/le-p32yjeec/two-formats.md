---
title: CycloneDX and SPDX, field by field
version: 1
---

There are two standard formats, and the first question people ask is which one is better. **They
carry nearly the same information, grew up answering different questions, and every serious tool
reads and writes both.** The useful skill is reading either, and knowing where each keeps a given
fact.

- **CycloneDX** comes from OWASP and grew out of security work: tracking components to match them
  against vulnerabilities. It is published as the Ecma standard ECMA-424.
- **SPDX** comes from the Linux Foundation and grew out of licence compliance: recording what
  licence every file and package carries. Version 2.2.1 is the international standard ISO/IEC
  5962:2021.

### The document around the list

Strip out the long lists and look at what each document says about itself. CycloneDX first:

```
ana@vm:~/linkbox$ jq "del(.components, .dependencies) | .metadata |= {timestamp, component}" ~/sbom/linkbox.cdx.json
{
  "$schema": "http://cyclonedx.org/schema/bom-1.7.schema.json",
  "bomFormat": "CycloneDX",
  "specVersion": "1.7",
  "serialNumber": "urn:uuid:a4721878-b418-4a79-9735-d7010d555998",
  "version": 1,
  "metadata": {
    "timestamp": "2026-10-23T08:54:37-03:00",
    "component": {
      "bom-ref": "00c172294fdeb85b",
      "type": "container",
      "name": "localhost:5000/linkbox",
      "version": "main"
    }
  }
}
```

Then SPDX:

```
ana@vm:~/linkbox$ jq "del(.packages, .files, .relationships, .hasExtractedLicensingInfos)" ~/sbom/linkbox.spdx.json
{
  "spdxVersion": "SPDX-2.3",
  "dataLicense": "CC0-1.0",
  "SPDXID": "SPDXRef-DOCUMENT",
  "name": "localhost:5000/linkbox",
  "documentNamespace": "https://anchore.com/syft/image/localhost-5000/linkbox-474ec5dd-b5ba-4cd2-9f5c-4806d7d145df",
  "creationInfo": {
    "licenseListVersion": "3.29",
    "creators": [
      "Organization: Anchore, Inc",
      "Tool: syft-1.54.1"
    ],
    "created": "2026-10-23T11:54:37Z"
  }
}
```

Both say what they are and in which version of their format, who made them (syft 1.54.1), when, and
what they describe. They say it in different places: CycloneDX keeps the subject in
`metadata.component`, the image `localhost:5000/linkbox` at `main`; SPDX gives the document a `name`
and, inside the `relationships` left out above, a `DESCRIBES` relationship from the document to the
image's package. Each document has an identity of its own, a `serialNumber` in CycloneDX and a
`documentNamespace` in SPDX, which is new on every run, so two SBOMs of the same image are still two
documents.

### One package, twice

gunicorn as CycloneDX describes it:

```
ana@vm:~/linkbox$ jq ".components[] | select(.name == \"gunicorn\") | {type, name, version, licenses, purl}" ~/sbom/linkbox.cdx.json
{
  "type": "library",
  "name": "gunicorn",
  "version": "22.0.0",
  "licenses": [
    {
      "license": {
        "id": "MIT"
      }
    }
  ],
  "purl": "pkg:pypi/gunicorn@22.0.0"
}
```

And as SPDX does:

```
ana@vm:~/linkbox$ jq ".packages[] | select(.name == \"gunicorn\") | {name, SPDXID, versionInfo, supplier, licenseDeclared, purl: (.externalRefs[] | select(.referenceType == \"purl\") | .referenceLocator)}" ~/sbom/linkbox.spdx.json
{
  "name": "gunicorn",
  "SPDXID": "SPDXRef-Package-python-gunicorn-a4b2c9daf4751987",
  "versionInfo": "22.0.0",
  "supplier": "Person: Benoit Chesneau (benoitc@gunicorn.org)",
  "licenseDeclared": "MIT",
  "purl": "pkg:pypi/gunicorn@22.0.0"
}
```

The same five facts, under different names: what it is, its name, its version, its licence, and the
purl that identifies it anywhere. SPDX adds a `supplier`, read from the package's metadata, and an
`SPDXID` that other parts of the document point at. It also separates the licence the package
**declares** from the licence somebody **concluded** after looking, which syft leaves as
`NOASSERTION` because it did not look; that distinction is the licence-compliance heritage showing.
The filters above keep the output short: both documents carry more for every package, the CPE
identifiers older vulnerability databases use and the paths of the files syft read.

### The two side by side

| what | CycloneDX | SPDX |
|---|---|---|
| format and version | `bomFormat`, `specVersion` | `spdxVersion` |
| identity of the document | `serialNumber` | `documentNamespace`, `SPDXID` |
| made by, and when | `metadata.tools`, `metadata.timestamp` | `creationInfo.creators`, `creationInfo.created` |
| what it describes | `metadata.component` | a `DESCRIBES` relationship |
| one package | an entry of `components` | an entry of `packages` |
| version | `version` | `versionInfo` |
| identifier | `purl`, and `cpe` | `externalRefs` of type `purl` and `cpe23Type` |
| licence | `licenses` | `licenseDeclared` and `licenseConcluded` |
| supplier | `author` or `supplier` | `supplier`, `originator` |
| what depends on what | `dependencies` | `relationships` such as `DEPENDS_ON` |
| files | components of type `file` | `files`, and `CONTAINS` relationships |

Every one of the NTIA's minimum elements from the first section has a home in both: supplier, name,
version, identifier, relationships, author, timestamp.

### Why the SPDX file is bigger

The SPDX document is about two and a half times the size of the CycloneDX one for the same image.
Both record the files syft found in the image; SPDX also records a relationship for each file it
lists and repeats the identifiers for every package in `externalRefs`. Neither is wrong, and the
size rarely matters, but it explains why the two files of one run never look alike.

### Which to keep

This course keeps both, because generating both costs one run of syft and a few hundred kilobytes.
When one has to be chosen, the consumer decides: a vulnerability platform or a signing tool may want
CycloneDX, a legal team auditing licences may ask for SPDX, a customer's contract may name one.
**Ask the reader before choosing the format**, which is a rule this lesson's scanning section turns
out to apply to more than the format.
