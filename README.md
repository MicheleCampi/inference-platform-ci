# inference-platform-ci

[![ci](https://github.com/MicheleCampi/inference-platform-ci/actions/workflows/ci.yml/badge.svg)](https://github.com/MicheleCampi/inference-platform-ci/actions/workflows/ci.yml)

Pinned tools and shared verification helpers for the CI of six repositories: [aws-ecs-delivery-platform](https://github.com/MicheleCampi/aws-ecs-delivery-platform), [eks-llm-inference-platform](https://github.com/MicheleCampi/eks-llm-inference-platform), [gke-llm-inference-platform](https://github.com/MicheleCampi/gke-llm-inference-platform), [llm-inference-platform](https://github.com/MicheleCampi/llm-inference-platform), [model-promotion-bridge](https://github.com/MicheleCampi/model-promotion-bridge) and [vllm-coldstart-operator](https://github.com/MicheleCampi/vllm-coldstart-operator). Each consumer pins a tag of this repository together with the commit that tag must resolve to, and its run fails if the tag resolves anywhere else: gke checks with `tag_is` from `lib.sh`, the others with the same comparison in their install or validate script.

| File | What it is |
|---|---|
| `tools.lock` | name, URL and SHA-256 of every tool the platform's CI downloads |
| `versions.env` | versions shared by more than one repository: the Kubernetes JSON schemas |
| `requirements.lock` | PyYAML, every hash pinned |
| `install.sh DEST LOCK [NAME...]` | downloads the named entries of a lock, verifies each SHA-256, installs them in DEST |
| `install-python.sh DEST REQS` | a venv in DEST with REQS installed, every hash checked |
| `lib.sh` | `pass`, `check`, `expect_reject`, `same`, `exit_code` and `tag_is`, sourced by the validate scripts |
| `selftest.sh` | each helper and installer must accept what it should accept and reject what it should reject, for the reason named |

Run the self-test with `bash selftest.sh` (bash, curl, git, python3 and network access; Linux amd64). CI runs it on every push and pull request, then lints the workflow with the pinned actionlint.

## Updating a pin

Change the URL and the hash together, after checking the hash against the upstream release's own checksum file; tag a new version; then move each consumer to the new tag and commit, one pull request each.
