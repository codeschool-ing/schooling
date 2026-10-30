---
title: Marketplace images and their four names
version: 1
---

"Ubuntu 24.04" sounds like the name of an image. On Azure it is the name of a whole family, and a
machine cannot be created from a family. **A Marketplace image is named by four names**, joined
with colons into what Azure calls a URN: the *publisher*, who made it; the *offer*, a group of
related images; the *SKU*, one edition within the offer; and the *version*, one build of that
edition.

| | Ubuntu 24.04 | what the name is |
|---|---|---|
| publisher | `Canonical` | the organisation that publishes it |
| offer | `ubuntu-24_04-lts` | a group of related images |
| SKU | `server` | one edition: here generation 2 on x64 |
| version | `latest`, or a build number | one build of the SKU |

Put together, `Canonical:ubuntu-24_04-lts:server:latest`. Nothing in the four is derived from the
others, and the offer is the one that surprises people: Canonical's offer for 22.04 is
`0001-com-ubuntu-server-jammy`, for 24.04 it is `ubuntu-24_04-lts`, and before 20.04 it was
`UbuntuServer`. A URN is copied from a list, never typed from memory.

## The list the CLI carries with it

`az vm image list` answers without a subscription, which makes it the one image command this
course can run:

```
ana@laptop:~/azure$ az vm image list --output table
WARNING: Failed to retrieve image alias doc 'https://azcliprod.blob.core.windows.net/cli/vm/aliases.json'. Error: 'ConnectionError'. Use local copy instead.
WARNING: You are viewing an offline list of images, use --all to retrieve an up-to-date list
Architecture    Offer                         Publisher               Sku                                 Urn                                                                             UrnAlias                 Version
--------------  ----------------------------  ----------------------  ----------------------------------  ------------------------------------------------------------------------------  -----------------------  ---------
x64             azurelinux-4                  microsoftazurelinux     4                                   microsoftazurelinux:azurelinux-4:4:latest                                       AzureLinux4              latest
Arm64           azurelinux-4                  microsoftazurelinux     4-arm64                             microsoftazurelinux:azurelinux-4:4-arm64:latest                                 AzureLinux4Arm64         latest
x64             azurelinux-4                  microsoftazurelinux     4-gen1                              microsoftazurelinux:azurelinux-4:4-gen1:latest                                  AzureLinux4Gen1          latest
x64             CentOS                        OpenLogic               8_5-gen2                            OpenLogic:CentOS:8_5-gen2:latest                                                CentOS85Gen2             latest
x64             debian-11                     Debian                  11-backports-gen2                   Debian:debian-11:11-backports-gen2:latest                                       Debian11                 latest
x64             flatcar-container-linux-free  kinvolk                 stable-gen2                         kinvolk:flatcar-container-linux-free:stable-gen2:latest                         FlatcarLinuxFreeGen2     latest
x64             openSUSE-leap-15-4            SUSE                    gen2                                SUSE:openSUSE-leap-15-4:gen2:latest                                             OpenSuseLeap154Gen2      latest
x64             RHEL                          RedHat                  8-lvm-gen2                          RedHat:RHEL:8-lvm-gen2:latest                                                   RHELRaw8LVMGen2          latest
x64             sles-15-sp3                   SUSE                    gen2                                SUSE:sles-15-sp3:gen2:latest                                                    SuseSles15SP3            latest
x64             0001-com-ubuntu-server-jammy  Canonical               22_04-lts-gen2                      Canonical:0001-com-ubuntu-server-jammy:22_04-lts-gen2:latest                    Ubuntu2204               latest
x64             WindowsServer                 MicrosoftWindowsServer  2022-datacenter-g2                  MicrosoftWindowsServer:WindowsServer:2022-datacenter-g2:latest                  Win2022Datacenter        latest
x64             WindowsServer                 MicrosoftWindowsServer  2022-datacenter-azure-edition-core  MicrosoftWindowsServer:WindowsServer:2022-datacenter-azure-edition-core:latest  Win2022AzureEditionCore  latest
x64             WindowsServer                 MicrosoftWindowsServer  2019-datacenter-gensecond           MicrosoftWindowsServer:WindowsServer:2019-datacenter-gensecond:latest           Win2019Datacenter        latest
x64             WindowsServer                 MicrosoftWindowsServer  2016-datacenter-gensecond           MicrosoftWindowsServer:WindowsServer:2016-datacenter-gensecond:latest           Win2016Datacenter        latest
x64             WindowsServer                 MicrosoftWindowsServer  2012-R2-Datacenter                  MicrosoftWindowsServer:WindowsServer:2012-R2-Datacenter:latest                  Win2012R2Datacenter      latest
x64             WindowsServer                 MicrosoftWindowsServer  2012-Datacenter                     MicrosoftWindowsServer:WindowsServer:2012-Datacenter:latest                     Win2012Datacenter        latest
```

The two warnings are worth reading before the table. The CLI first tried to download a short
document of image aliases that Microsoft publishes, could not reach it, and fell back to a copy
built into this version of the CLI; then it said what that means. **This is an offline list of
sixteen popular images, frozen into CLI 2.91.0, and not what Azure offers today.** The laptop these
transcripts were recorded on is refused the host that document lives on. A machine on the open
internet fetches it and prints neither warning.

The difference is not cosmetic. The copy built into this CLI has `Ubuntu2204` and no Ubuntu 24.04
at all. The document it failed to fetch, read on GitHub on 30 October 2026, has eighteen aliases,
among them `Ubuntu2404` for `Canonical:ubuntu-24_04-lts:server:latest`. So `--image Ubuntu2404`
means that URN on a machine that reached the document, and means nothing on one that did not.
**An alias belongs to the CLI, and Azure has never heard of it.** A Bicep file or an ARM template
names the four parts, which is what this course does from here on.

Filtering works on the offline list too, and shows how little of it there is:

```
ana@laptop:~/azure$ az vm image list --publisher Canonical --output table
WARNING: Failed to retrieve image alias doc 'https://azcliprod.blob.core.windows.net/cli/vm/aliases.json'. Error: 'ConnectionError'. Use local copy instead.
WARNING: You are viewing an offline list of images, use --all to retrieve an up-to-date list
Architecture    Offer                         Publisher    Sku             Urn                                                           UrnAlias    Version
--------------  ----------------------------  -----------  --------------  ------------------------------------------------------------  ----------  ---------
x64             0001-com-ubuntu-server-jammy  Canonical    22_04-lts-gen2  Canonical:0001-com-ubuntu-server-jammy:22_04-lts-gen2:latest  Ubuntu2204  latest
```

For the real catalogue, `--all` asks Azure, and Azure needs an account:

```
ana@laptop:~/azure$ az vm image list --all --publisher Canonical --offer ubuntu-24_04-lts --output table
ERROR: Please run 'az login' to setup account.
ana@laptop:~/azure$ az vm image show --urn Canonical:ubuntu-24_04-lts:server:latest
ERROR: Please run 'az login' to setup account.
```

With a subscription, Microsoft's documentation describes the usual way down the four names as one
command for each: `az vm image list-publishers`, `list-offers --publisher Canonical`, `list-skus
--offer ubuntu-24_04-lts`, and `az vm image list --all` with the three names to see every version.
`--all` across the whole Marketplace takes several minutes, by the documentation's own account,
which is why the narrowed form exists. These were not run in this course: they need a subscription.

`az vm image show`, refused above, is the one to run before using an image from a publisher you
have not used before. Its answer carries a `plan` field. **When `plan` is not `null`, the image
has its own licence terms.** They are accepted once per subscription, with `az vm image terms
accept`, before any template can create a machine from it; the plan's three names then go into
the machine's declaration as well. Canonical's Ubuntu images have no plan; many of the
Marketplace's commercial images, such as a database server sold by its vendor, do.

## `latest` is a question asked at creation

The fourth name is the one that changes. A publisher builds a new version of a SKU whenever it
ships fixes, and the version is a number; Microsoft's documentation shows an Ubuntu 18.04 build
called `18.04.201901220`. **`latest` is not a version. It is a question, and Azure answers it at
the moment a machine is created.** Two machines created from the same URN a month apart are
created from two different builds, and a template that has not changed says nothing about which.

That is the right default for a single machine somebody looks after, which then starts with the
month's fixes. It is the wrong one for a group of machines that must be the same, which is why the
scale sets of lesson 4 and the gallery of this lesson's last section care about it. A pinned
version, such as `18.04.201901220`, makes every creation identical; it also keeps you on that
build until somebody edits the file. The usual way out of that trade is to pin your own image
rather than somebody else's, which is the next two sections.

## Naming one in Bicep

Here is the machine the shop's order API would run on, declared with a Marketplace image. The
network interface and the key are parameters, because `azure-foundations` lesson 16 built the
network and nothing here depends on how. Save it as `vm.bicep`:

```bicep
// vm.bicep
param location string = 'brazilsouth'
param adminUsername string = 'ana'
param sshPublicKey string
param nicId string

resource vm 'Microsoft.Compute/virtualMachines@2024-07-01' = {
  name: 'shop-web-1'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D2s_v5'
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'ubuntu-24_04-lts'
        sku: 'server'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    securityProfile: {
      securityType: 'TrustedLaunch'
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
    }
    osProfile: {
      computerName: 'shop-web-1'
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: sshPublicKey
            }
          ]
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicId
        }
      ]
    }
  }
}
```

`Standard_D2s_v5` is the size lesson 1 found as the CLI's default. The security profile is written
out whole, as the last section said it should be: Trusted Launch, with Secure Boot and the virtual
TPM both on. Compile it:

```
ana@laptop:~/azure$ bicep build vm.bicep
ana@laptop:~/azure$ jq ".resources[0].properties.storageProfile.imageReference" vm.json
{
  "publisher": "Canonical",
  "offer": "ubuntu-24_04-lts",
  "sku": "server",
  "version": "latest"
}
```

No warnings, and the four names reach the template exactly as written. **The compiler does not
know which images exist.** All four are plain strings to it, `latest` included; a SKU that Canonical
has never published compiles just as cleanly, and only Azure, asked with a subscription, would
refuse it. The compiler is not strict about the security type either. Misspell it:

```
ana@laptop:~/azure$ sed -i "s/TrustedLaunch/TrustedLaunh/" vm.bicep
ana@laptop:~/azure$ bicep build vm.bicep
ana@laptop:~/azure$ jq ".resources[0].properties.securityProfile" vm.json
{
  "securityType": "TrustedLaunh",
  "uefiSettings": {
    "secureBootEnabled": true,
    "vTpmEnabled": true
  }
}
ana@laptop:~/azure$ sed -i "s/TrustedLaunh/TrustedLaunch/" vm.bicep
```

Nothing was refused. The compiler knows `securityType` as a string that is usually one of a few
values, so `TrustedLaunh` went into the template as written, and what Azure does with it is decided
when the request arrives, not here. Lesson 1's rule covers what the compiler refuses; this is the
other half, a value nothing on the laptop checks. The second `sed` put the spelling back, and the
file is ready for the next section.
