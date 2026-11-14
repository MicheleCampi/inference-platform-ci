# inference-platform-ci

[![ci](https://github.com/MicheleCampi/inference-platform-ci/actions/workflows/ci.yml/badge.svg)](https://github.com/MicheleCampi/inference-platform-ci/actions/workflows/ci.yml)

Pinned tools and shared verification helpers for the CI of six repositories: [aws-ecs-delivery-platform](https://github.com/MicheleCampi/aws-ecs-delivery-platform), [eks-llm-inference-platform](https://github.com/MicheleCampi/eks-llm-inference-platform), [gke-llm-inference-platform](https://github.com/MicheleCampi/gke-llm-inference-platform), [llm-inference-platform](https://github.com/MicheleCampi/llm-inference-platform), [model-promotion-bridge](https://github.com/MicheleCampi/model-promotion-bridge) and [vllm-coldstart-operator](https://github.com/MicheleCampi/vllm-coldstart-operator). Each consumer pins a tag of this repository together with the commit that tag must resolve to, and its run fails if the tag resolves anywhere else: gke checks with `tag_is` from `lib.sh`, the others with the same comparison in their install or validate script.

| File | What it is |
|---|---|
| `tools.lock` | name, URL and SHA-256 of every tool the platform's CI downloads |
| `versions.env` | versions shared by more than one repository: the Kubernetes JSON schemas |
| `requirements.in` | direct Python dependencies: PyYAML, jsonschema |
| `requirements.lock` | generated from `requirements.in` by pip-compile, every hash pinned |
| `install.sh DEST LOCK [NAME...]` | downloads the named entries of a lock, verifies each SHA-256, installs them in DEST |
| `install-python.sh DEST REQS` | a venv in DEST with REQS installed, every hash checked |
| `lib.sh` | `pass`, `check`, `expect_reject`, `same`, `exit_code` and `tag_is`, sourced by the validate scripts |
| `selftest.sh` | each helper and installer must accept what it should accept and reject what it should reject, for the reason named |

Run the self-test with `bash selftest.sh` (bash, curl, git, python3 and network access; Linux amd64). CI runs it on every push and pull request, then lints the workflow with the pinned actionlint.

## Updating a pin

Change the URL and the hash together, after checking the hash against the upstream release's own checksum file; tag a new version; then move each consumer to the new tag and commit, one pull request each.

Python dependencies: edit `requirements.in`, then regenerate the lock with pip-tools 7.6.2 and Python 3.12 (the Python of the `ubuntu-24.04` runner):

    pip-compile --generate-hashes --allow-unsafe --no-strip-extras --output-file requirements.lock requirements.in

## trivy: signature verified before pinning

The Trivy ecosystem was compromised in March 2026 (advisory "Trivy ecosystem
supply chain temporarily compromised": malicious binary v0.69.4, hijacked tags
of `trivy-action` and `setup-trivy`). So trivy is installed here as the release
binary, never through those actions, and its pin was set only after checking
the Sigstore signature, with the signer restricted to the trivy repository and
the release tag (the advisory accepts any `aquasecurity/` workflow):

    T=https://github.com/aquasecurity/trivy/releases/download/v0.76.2
    for f in trivy_0.76.2_Linux-64bit.tar.gz trivy_0.76.2_checksums.txt; do
      curl -fsSLO "$T/$f" && curl -fsSLO "$T/$f.sigstore.json"
      cosign verify-blob \
        --certificate-identity-regexp '^https://github\.com/aquasecurity/trivy/\.github/workflows/[^@]+@refs/tags/v0\.76\.2$' \
        --certificate-oidc-issuer https://token.actions.githubusercontent.com \
        --bundle "$f.sigstore.json" "$f"
    done
    grep ' trivy_0.76.2_Linux-64bit.tar.gz$' trivy_0.76.2_checksums.txt

Result on 14/11/2026: both `Verified OK`; signer
`https://github.com/aquasecurity/trivy/.github/workflows/reusable-release.yaml@refs/tags/v0.76.2`;
signed 2026-11-05 12:47:20 UTC; SHA-256
`bc0fc726e017b8927a62b2d3531d7a84ee01769daf5c99ed866dced54089fdbf`, equal to the
signed checksum file and to `tools.lock`. v0.76.2 is outside every range in the
trivy security advisories (the latest fixes are in v0.72.0).

Limit: cosign v3.1.4 itself was checked only against the SHA-256 in its own
release (`cosign_checksums.txt`), downloaded over TLS from GitHub; that is
where this chain of trust starts.

