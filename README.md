# inference-platform-ci

Pinned tools and shared verification helpers for the repositories of one LLM inference platform: [gke-llm-inference-platform](https://github.com/MicheleCampi/gke-llm-inference-platform), [model-promotion-bridge](https://github.com/MicheleCampi/model-promotion-bridge) and [vllm-coldstart-operator](https://github.com/MicheleCampi/vllm-coldstart-operator). Each consumer pins a tag of this repository together with the commit that tag must resolve to, and checks both with `tag_is`: a moved tag fails its run.

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
