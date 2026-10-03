#!/bin/bash

meson_version(){
    cd "$base_dir"
    sed -i "2s/version: 'v[0-9.]*'/version: 'v$version'/" meson.build
    cd "$pkg_dir"
}

app_changelog(){
    cd "$base_dir"
    date_string=$(date -u '+%Y-%m-%d')
    sed -i "0,/^## \[[Uu]nreleased\]/s//## [v$version] - $date_string/" "$base_dir/CHANGELOG.md"
    cd "$pkg_dir"
}

meta_info() {
    local metainfo_file="$base_dir/data/com.github.koxt2.datarecovery.metainfo.xml"
    local release_version="${version#v}"
    local release_heading="## [v$version]"
    local release_date
    local release_header
    local entry_file
    local metainfo_tmp
    local item
    local -a changelog_items

    if grep -Fq "<release version=\"$release_version\"" "$metainfo_file"; then
        return 0
    fi

    release_header=$(awk -v heading="$release_heading" 'index($0, heading) == 1 { print; exit }' "$base_dir/CHANGELOG.md")
    if [[ -z "$release_header" ]]; then
        printf 'No changelog entry found for %s\n' "$release_heading" >&2
        return 1
    fi
    release_date="${release_header##* - }"

    mapfile -t changelog_items < <(
        awk -v heading="$release_heading" '
            index($0, heading) == 1 { in_release=1; next }
            in_release && /^## \[/ { exit }
            in_release && /^- / {
                items[++count] = substr($0, 3)
                next
            }
            in_release && /^[[:space:]]+[^[:space:]]/ && count {
                sub(/^[[:space:]]+/, "")
                items[count] = items[count] " " $0
            }
            END {
                for (i=1; i<=count; i++) print items[i]
            }
        ' "$base_dir/CHANGELOG.md"
    )
    if (( ${#changelog_items[@]} == 0 )); then
        printf 'No changelog items found for %s\n' "$release_heading" >&2
        return 1
    fi

    entry_file=$(mktemp)
    metainfo_tmp=$(mktemp "$metainfo_file.XXXXXX")
    {
        printf '    <release version="%s" date="%s">\n' "$release_version" "$release_date"
        printf '      <description>\n'
        printf '        <p>Release v%s</p>\n' "$release_version"
        printf '        <ul>\n'
        for item in "${changelog_items[@]}"; do
            item=$(printf '%s' "$item" | sed \
                -e 's/&/\&amp;/g' \
                -e 's/</\&lt;/g' \
                -e 's/>/\&gt;/g')
            printf '          <li>%s</li>\n' "$item"
        done
        printf '        </ul>\n'
        printf '      </description>\n'
        printf '    </release>\n'
    } > "$entry_file"

    if ! awk -v entry_file="$entry_file" '
        !inserted && /<releases>/ {
            print
            while ((getline line < entry_file) > 0) print line
            close(entry_file)
            inserted=1
            next
        }
        { print }
        END { if (!inserted) exit 1 }
    ' "$metainfo_file" > "$metainfo_tmp"; then
        rm -f "$entry_file" "$metainfo_tmp"
        printf 'Could not find a <releases> element in %s\n' "$metainfo_file" >&2
        return 1
    fi

    mv "$metainfo_tmp" "$metainfo_file"
    rm -f "$entry_file"
}

commit_tag(){
    cd "$base_dir"
    git add .
    git commit -m "Release v$version"
    git tag -a v$version -m "Release v$version"
    cd "$pkg_dir"
}

create_source_tarball(){
    cd "$base_dir"
    git archive \
        --format=tar.gz \
        --prefix="DataRecovery-$version/" \
        -o "$pkg_dir/v$version.tar.gz" \
        v$version
}