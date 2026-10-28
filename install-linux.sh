#!/bin/bash
set -euo pipefail
package_root=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
# shellcheck source=scripts/common-linux.sh
source "$package_root/scripts/common-linux.sh"
init_paths

# Check the pet payload before touching an installation.
(cd "$package_root" && sha256sum -c SHA256SUMS) || die 'Package integrity check failed.'
[[ "$(python3 "$package_root/scripts/pet-field.py" id "$package_root/pet.json")" == von ]] || die 'Invalid package ID.'
[[ "$(python3 "$package_root/scripts/pet-field.py" displayName "$package_root/pet.json")" == Von ]] || die 'Invalid package name.'
[[ "$(python3 "$package_root/scripts/pet-field.py" spritesheetPath "$package_root/pet.json")" == spritesheet.webp ]] || die 'Invalid sprite path.'
[[ "$(python3 "$package_root/scripts/pet-field.py" spriteVersionNumber "$package_root/pet.json")" == 1 ]] || die 'Unsupported sprite version.'
mkdir -p "$pets_root"
acquire_lock
stage=''
rollback=''
committed=0
cleanup() {
	local status=$?
	if [[ -n "$rollback" && -d "$rollback" ]]; then
		if [[ "$committed" == 1 ]]; then
			rm -rf "$rollback"
		elif [[ ! -e "$target" ]]; then
			mv "$rollback" "$target" || printf 'Von: restore manually from %s\n' "$rollback" >&2
		fi
	fi
	[[ -z "$stage" || ! -d "$stage" ]] || rm -rf "$stage"
	rmdir "$lock" 2>/dev/null || true
	exit "$status"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
find_von
[[ -n "$target" ]] || target="$pets_root/von"
stage=$(mktemp -d "$pets_root/.von-stage.XXXXXX")
# Retain unrelated files in an existing Von directory.
if [[ -d "$target" ]]; then cp -R "$target/." "$stage/"; fi
cp "$package_root/spritesheet.webp" "$stage/spritesheet.webp"
printf '{\n  "id": "%s",\n  "displayName": "Von",\n  "description": "Armed & Dangerous",\n  "spriteVersionNumber": 1,\n  "spritesheetPath": "spritesheet.webp"\n}\n' "$pet_id" >"$stage/pet.json"
(cd "$stage" && sha256sum pet.json spritesheet.webp >.von-codex-pet.sha256)
chmod 755 "$stage"
chmod 644 "$stage/pet.json" "$stage/spritesheet.webp" "$stage/.von-codex-pet.sha256"
if [[ -d "$target" ]]; then
	rollback=$(mktemp -d "$pets_root/.von-rollback.XXXXXX")
	rmdir "$rollback"
	mv "$target" "$rollback"
fi
mv "$stage" "$target"
stage=''
committed=1
printf 'Von installed at %s\nSelect Von in Codex Pets; reopen Codex if the picker is stale.\n' "$target"
