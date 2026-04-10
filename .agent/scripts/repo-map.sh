#!/bin/bash
# repo-map.sh — Zero-dependency code skeleton generator
# Outputs class/function/interface signatures per file, saving tokens
# vs reading full source files. Usage: repo-map.sh [directory]
# Exit 0 on success, 1 on critical error.

TARGET_DIR="${1:-.}"
[ -d "$TARGET_DIR" ] || { echo "[repo-map] ERROR: '$TARGET_DIR' is not a directory" >&2; exit 1; }

CTAGS_OK=false; command -v ctags &>/dev/null && CTAGS_OK=true

indent() { printf "%$(( $1 * 2 ))s" ""; }

# Extract signatures via grep — one pass, all languages, deduplicated
sigs() {
    local f="$1" d="$2"; local i; i="$(indent "$d")"
    {
        grep -hE '^[[:space:]]*(class[[:space:]]+[A-Z]|(async[[:space:]]+)?def[[:space:]]+[a-z_])' "$f" 2>/dev/null        # Python
        grep -hE '(export[[:space:]]+)?(default[[:space:]]+)?(async[[:space:]]+)?(class[[:space:]]+[A-Z]|function[[:space:]]+[a-zA-Z]|interface[[:space:]]+[A-Z]|type[[:space:]]+[A-Z]|enum[[:space:]]+[A-Z])' "$f" 2>/dev/null  # JS/TS
        grep -hE '^[[:space:]]*(func[[:space:]]|type[[:space:]]+[A-Z])' "$f" 2>/dev/null                                          # Go
        grep -hE '^[[:space:]]*(pub[[:space:]]+)?(async[[:space:]]+)?(fn[[:space:]]|struct[[:space:]]|enum[[:space:]]|impl|trait[[:space:]])' "$f" 2>/dev/null       # Rust
        grep -hE '^[[:space:]]*(public|private|protected|abstract)?[[:space:]]*(class|interface|enum)[[:space:]]+[A-Z]' "$f" 2>/dev/null  # Java
        grep -hE '^[[:space:]]*(class[[:space:]]+[A-Z]|module[[:space:]]+[A-Z]|def[[:space:]]+[a-z_])' "$f" 2>/dev/null         # Ruby
        grep -hE '^[[:space:]]*(class[[:space:]]+[A-Z]|function[[:space:]]+[a-z_]|interface[[:space:]]+[A-Z]|trait[[:space:]]+[A-Z])' "$f" 2>/dev/null            # PHP
        grep -hE '^[[:space:]]*(public[[:space:]]+|private[[:space:]]+|protected[[:space:]]+)?(class|struct|enum|namespace|interface)[[:space:]]+[A-Za-z_]' "$f" 2>/dev/null  # C#/C++
        grep -hE '^[[:space:]]*(function[[:space:]]+[a-zA-Z_]|[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*\(\)[[:space:]]*\{)' "$f" 2>/dev/null | grep -v '^[[:space:]]*#'  # Shell
    } | grep -vE '^[[:space:]]*echo ' | sed "s/^[[:space:]]*/${i}/" | sort -u
}

sigs_ctags() {
    local f="$1" d="$2"; local i; i="$(indent "$d")"
    ctags --extras= --fields=+K -o - "$f" 2>/dev/null | awk -v i="$i" -F'\t' '{print i $1" ("$4")"}' | sort -u
}

# --- Main ---------------------------------------------------------------------

prev="" cnt=0
while IFS= read -r fp; do
    [ -r "$fp" ] || continue
    # Skip binaries (ELF/PE/unknown via mime-type)
    if command -v file &>/dev/null; then
        mt="$(file -b --mime-type "$fp" 2>/dev/null)"
        case "$mt" in application/x-executable|application/x-pie-executable|application/x-dosexec|application/octet-stream) continue;; esac
    fi
    rel="${fp#"$TARGET_DIR"/}"; [ "$rel" = "$fp" ] && rel="${fp#./}"
    dir="$(dirname "$rel")"; base="$(basename "$rel")"; [ "$dir" = "." ] && dir=""
    depth=0; [ -n "$dir" ] && depth="$(echo "$dir" | awk -F/ '{print NF}')"
    # Print directory tree on change
    if [ "$dir" != "$prev" ]; then
        if [ -n "$dir" ]; then
            c=0; IFS=/ read -ra P <<< "$dir"; for p in "${P[@]}"; do echo "$(indent "$c")${p}/"; c=$((c+1)); done
        fi; prev="$dir"
    fi
    echo "$(indent "$depth")${base}"; cnt=$((cnt+1))
    sd=$((depth+1))
    if $CTAGS_OK; then sigs_ctags "$fp" "$sd"; else sigs "$fp" "$sd"; fi
done < <(
    find "$TARGET_DIR" -mindepth 1 \
        -type d \( -name node_modules -o -name .git -o -name target -o -name dist -o -name .next \
            -o -name __pycache__ -o -name .venv -o -name build -o -name vendor -o -name venv \) -prune -o \
        -type f \( -name '*.py' -o -name '*.js' -o -name '*.ts' -o -name '*.jsx' -o -name '*.tsx' \
            -o -name '*.go' -o -name '*.rs' -o -name '*.java' -o -name '*.rb' -o -name '*.php' \
            -o -name '*.cs' -o -name '*.cpp' -o -name '*.h' -o -name '*.sh' \) \
        -print 2>/dev/null | sort
)

[ "$cnt" -eq 0 ] && echo "(no source files found in '$TARGET_DIR')"
exit 0
