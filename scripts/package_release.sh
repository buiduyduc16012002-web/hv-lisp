#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(git rev-parse --show-toplevel)"
version="$(tr -d '[:space:]' < "$repo_dir/VERSION")"
archive_name="hvlisp-v${version}.zip"
output_dir="${1:-$repo_dir/dist}"

if [[ -n "${GITHUB_REF_NAME:-}" && "${GITHUB_REF_TYPE:-}" == "tag" && "${GITHUB_REF_NAME}" != "v${version}" ]]; then
  echo "Tag ${GITHUB_REF_NAME} does not match VERSION ${version}." >&2
  exit 1
fi

mkdir -p "$output_dir"
git -C "$repo_dir" archive \
  --format=zip \
  --prefix="HVLisp/" \
  --output="$output_dir/$archive_name" \
  HEAD \
  VERSION LICENSE README.md CHANGELOG.md CONTRIBUTING.md SECURITY.md \
  IP_PROVENANCE.md RELEASE_CHECKLIST.md TEST_REPORT.md update.ps1 docs examples src lenh

(
  cd "$output_dir"
  sha256sum "$archive_name" > CHECKSUMS.txt
)

echo "$output_dir/$archive_name"
echo "$output_dir/CHECKSUMS.txt"
