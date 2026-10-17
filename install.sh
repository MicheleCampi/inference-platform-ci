#!/usr/bin/env bash
# Install pinned artifacts into DEST, verifying each SHA-256 before use:
#   bash install.sh DEST LOCK [NAME...]
# LOCK has one "name url sha256" line per artifact. With NAMEs, only those
# entries are installed, and a NAME missing from LOCK fails the run.
# Linux amd64 only.
set -euo pipefail
[ $# -ge 2 ] || { echo "usage: install.sh DEST LOCK [NAME...]" >&2; exit 2; }
dest=$1 lock=$2; shift 2
mkdir -p "$dest"
dl=$(mktemp -d); trap 'rm -rf "$dl"' EXIT
seen=" "
while read -r name url sha; do
  case "$name" in ''|'#'*) continue ;; esac
  if [ $# -gt 0 ]; then case " $* " in *" $name "*) ;; *) continue ;; esac; fi
  # Prefixed with the name: two artifacts can share a basename upstream.
  f="$dl/$name.$(basename "$url")"
  curl -fsSL --retry 3 -o "$f" "$url"
  got=$(sha256sum "$f" | cut -d' ' -f1)
  if [ "$got" != "$sha" ]; then echo "checksum mismatch for $name: expected $sha, got $got" >&2; exit 1; fi
  case "$(basename "$url")" in
    *.zip)    python3 -m zipfile -e "$f" "$dl/$name.x" && install -m 0755 "$dl/$name.x/$name" "$dest/$name" ;;
    *.tar.gz) mkdir -p "$dl/$name.x" && tar -xzf "$f" -C "$dl/$name.x" && install -m 0755 "$(find "$dl/$name.x" -type f -name "$name" | head -1)" "$dest/$name" ;;
    *.py)     install -m 0644 "$f" "$dest/$name.py" ;;
    *.yaml)   install -m 0644 "$f" "$dest/$name.yaml" ;;
    *.*)      echo "no install rule for $name" >&2; exit 1 ;;
    *)        install -m 0755 "$f" "$dest/$name" ;;
  esac
  seen="$seen$name "
  echo "ok $name ${sha:0:12}"
done < "$lock"
for n in "$@"; do case "$seen" in *" $n "*) ;; *) echo "$n is not in $lock" >&2; exit 1 ;; esac; done
