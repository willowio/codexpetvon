#!/bin/bash
set -euo pipefail
package_root=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
# shellcheck source=scripts/common.sh
source "$package_root/scripts/common.sh"
init_paths
if [[ ! -d "$pets_root" ]]; then
	printf 'Von is not installed.\n'
	exit 0
fi
acquire_lock
trap 'rmdir "$lock" 2>/dev/null || true' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
find_von
if [[ -z "$target" ]]; then
	printf 'Von is not installed.\n'
	exit 0
fi
[[ -f "$target/.von-codex-pet.sha256" ]] || die 'No installer receipt. Run install.sh before using this uninstaller.'
# Compare only the two fixed managed paths; never accept paths supplied by a receipt.
expected=$(cat "$target/.von-codex-pet.sha256")
actual=$(cd "$target" && /usr/bin/shasum -a 256 pet.json spritesheet.webp)
[[ "$actual" == "$expected" ]] || die 'Von files changed since installation; leaving them intact.'
rm "$target/pet.json" "$target/spritesheet.webp" "$target/.von-codex-pet.sha256"
if ! rmdir "$target" 2>/dev/null; then
	printf 'Von removed; extra files retained at %s\n' "$target"
else
	printf 'Von removed.\n'
fi
printf 'Select another pet in Codex if Von was active.\n'
