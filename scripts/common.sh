#!/bin/bash
# Shared installer helpers; run install.sh or uninstall.sh.
set -euo pipefail

die() {
	printf 'Von: %s\n' "$*" >&2
	exit 1
}

init_paths() {
	codex_root="${CODEX_HOME:-${HOME:?HOME must be set}/.codex}"
	case "$codex_root" in /*) ;; *) die 'CODEX_HOME must be an absolute path.' ;; esac
	pets_root="$codex_root/pets"
	target=''
	pet_id='von'
}

find_von() {
	local name path actual_id actual_name file
	for name in von von-blink; do
		path="$pets_root/$name"
		if [[ -e "$path" || -L "$path" ]]; then
			[[ ! -L "$path" && -d "$path" ]] || die "Refusing non-directory or symlink: $path"
			for file in pet.json spritesheet.webp .von-codex-pet.sha256; do
				[[ ! -L "$path/$file" ]] || die "Refusing managed-file symlink: $path/$file"
			done
			[[ -f "$path/pet.json" && -f "$path/spritesheet.webp" ]] || die "Incomplete or unrelated directory: $path"
			actual_id=$(/usr/bin/plutil -extract id raw -o - "$path/pet.json") || die 'Invalid pet metadata.'
			actual_name=$(/usr/bin/plutil -extract displayName raw -o - "$path/pet.json") || die 'Missing pet name.'
			[[ "$actual_id" == "$name" && "$actual_name" == Von ]] || die "Directory belongs to another pet: $path"
			[[ -z "$target" ]] || die 'Both current and legacy Von directories exist; resolve them manually before continuing.'
			target="$path"
			# Used by install.sh after this function returns.
			# shellcheck disable=SC2034
			pet_id="$name"
		fi
	done
}

acquire_lock() {
	lock="$pets_root/.von-codex-pet.lock"
	mkdir "$lock" 2>/dev/null || die "Another operation may be running: $lock"
}
