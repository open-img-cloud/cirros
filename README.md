<p align="center">
  <a href="https://openimages.cloud/images/cirros/">
    <img src="https://openimages.cloud/img/og/cirros.png" alt="CirrOS test image for OpenStack" width="720">
  </a>
</p>

<p align="center">
  <a href="https://openimages.cloud/images/cirros/"><img alt="Latest version" src="https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fimages.openimages.cloud%2Fcirros%2Flatest%2FMANIFEST.json&query=%24.version&label=latest&color=2459c4&cacheSeconds=3600"></a>
  <a href="https://github.com/open-img-cloud/cirros/actions/workflows/release.yml"><img alt="Release" src="https://github.com/open-img-cloud/cirros/actions/workflows/release.yml/badge.svg"></a>
  <a href="https://openimages.cloud/verify/"><img alt="Signed with Sigstore cosign" src="https://img.shields.io/badge/signed-Sigstore%20cosign-2459c4"></a>
  <a href="https://openimages.cloud/quality/"><img alt="Boot-tested on OpenStack" src="https://img.shields.io/badge/boot--tested-OpenStack-2459c4"></a>
  <a href="LICENSE"><img alt="License GPL-2.0" src="https://img.shields.io/badge/license-GPL--2.0-555"></a>
</p>

<p align="center">
  <a href="https://openimages.cloud/images/cirros/"><b>Catalog page</b></a> ·
  <a href="https://images.openimages.cloud/cirros/latest/">Download</a> ·
  <a href="https://openimages.cloud/verify/">Verify</a> ·
  <a href="https://github.com/open-img-cloud/docs">Documentation</a> ·
  <a href="https://github.com/open-img-cloud/cirros/issues">Report an issue</a>
</p>

> [!WARNING]
> **Test image, not for production.** CirrOS has a **well-known password**
> (`cirros` / `gocubsgo`, accepted on the console and over SSH) and passwordless `sudo`.
> Use it to check that a cloud works, never to run anything. It does not follow the
> catalog's hardening rules (no cloud-init, SSH password login kept), on purpose.

[CirrOS](https://github.com/cirros-dev/cirros) is the tiny Linux image OpenStack uses to test
itself: Tempest, DevStack and most smoke checks boot it because it weighs about 20 MB and is up
in seconds. This repository republishes the official x86_64 disk image **unchanged**: verified
against the upstream checksum, signed with Sigstore cosign and boot-tested on a real OpenStack,
so operators get it from the same signed, versioned place as the rest of the
[openimages.cloud](https://openimages.cloud) catalog.

## At a glance

| | |
|---|---|
| **Upstream** | [CirrOS](https://github.com/cirros-dev/cirros) `x86_64-disk.img` from [download.cirros-cloud.net](https://download.cirros-cloud.net/), checked against its `SHA256SUMS` |
| **Default user** | `cirros`, password `gocubsgo` (well known), SSH key from the metadata too, passwordless `sudo` |
| **Metadata** | its own client (`cirros-ds`, not cloud-init): config drive, EC2-style metadata service, NoCloud (JSON meta-data only) |
| **Firmware** | BIOS or UEFI (hybrid disk) |
| **Format** | qcow2, x86_64, 112 MiB virtual disk, root filesystem grown to the disk at first boot |
| **Version** | the upstream release, e.g. `0.6.3` ([all versions](https://images.openimages.cloud/cirros/versions.json)); pre-releases are ignored |
| **Support** | follows upstream, which releases irregularly (0.6.3 in September 2024) |

## Quick start

```sh
# Latest version and its file name, from the signed manifest
M=https://images.openimages.cloud/cirros/latest/MANIFEST.json
V=$(curl -fsS $M | jq -r .version); F=$(curl -fsS $M | jq -r .filename)
curl -fLO https://images.openimages.cloud/cirros/$V/$F
# Same bytes as upstream: this hash is the one in its SHA256SUMS
sha256sum "$F"
curl -fsS https://download.cirros-cloud.net/$V/SHA256SUMS | grep x86_64-disk.img
```

<details>
<summary><b>OpenStack</b></summary>

```sh
openstack image create --disk-format qcow2 --container-format bare \
  --property os_distro=cirros --property os_version=$V \
  --property hw_rng_model=virtio \
  --file "$F" "CirrOS $V"
```

Do not set `hw_qemu_guest_agent=yes`: CirrOS has no guest agent. For Tempest, point
`[compute] image_ref` (and `image_ref_alt`) at this image, with `image_ssh_user = cirros`
and `image_ssh_password = gocubsgo` under `[validation]`.

</details>

<details>
<summary><b>Proxmox VE</b></summary>

The disk boots on Proxmox (BIOS or OVMF) and gets its address by DHCP; log in on the
console as `cirros` / `gocubsgo`. Key injection from the Proxmox cloud-init drive is not
expected to work: CirrOS reads only JSON metadata and ignores `#cloud-config` user data.

</details>

<details>
<summary><b>Verify the signature</b></summary>

```sh
curl -fLO https://images.openimages.cloud/cirros/$V/$F.bundle
cosign verify-blob "$F" --bundle "$F.bundle" \
  --certificate-identity-regexp '^https://github.com/open-img-cloud/\.github/\.github/workflows/build-(libguestfs|dib|nix-flake|freebsd)-image\.yml@' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com
```

</details>

## What this image changes

Nothing. The published qcow2 is the upstream file byte for byte (only renamed to
`cirros-<version>-x86_64.qcow2`); the build fails if its SHA-256 differs from the one in the
upstream `SHA256SUMS`. What this repository adds is around the image, not in it:

- verification of the upstream download against its checksum;
- a Sigstore cosign signature, checksums and a `MANIFEST.json` with the build provenance;
- a boot test on every release, against the catalog's **minimal** contract for test images:
  SSH as `cirros` with the key injected from the metadata, DNS, hostname from the metadata,
  root filesystem grown, passwordless `sudo`, IPv6 address and egress. The cloud-init and
  guest agent checks of the [full contract](https://openimages.cloud/quality/) do not apply,
  and the password login is reported, not refused.

## How releases happen

1. Every day at 07:32 UTC a watcher looks for a new stable CirrOS release and opens a pull
   request that bumps [`VERSION`](VERSION).
2. Merging it is all it takes: the release is tagged, verified, signed, boot-tested and
   published, then `latest/` and the [catalog](https://openimages.cloud/images/) move to it.

This repository only holds what is specific to CirrOS: [`VERSION`](VERSION),
[`build/detect-upstream.sh`](build/detect-upstream.sh) and thin workflows calling the shared
pipeline in [`open-img-cloud/.github`](https://github.com/open-img-cloud/.github).

## License

The build tooling in this repository is under [GPL-2.0](LICENSE). The image keeps the licensing
terms of CirrOS: its build code is under GPL-2.0, and the image bundles free software under the
license of each component (Linux kernel, BusyBox, Dropbear, ...). This project is not affiliated
with the CirrOS project.
