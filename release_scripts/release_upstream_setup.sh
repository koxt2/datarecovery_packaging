meson_version(){
    sed -i "2s/version: 'v[0-9.]*'/version: 'v$version'/" "$base_dir/meson.build"
}

app_changelog(){
    date_string=$(date -u '+%Y-%m-%d')
    sed -i "0,/^## \[[Uu]nreleased\]/s//## [v$version] - $date_string/" "$base_dir/CHANGELOG.md"
}

commit_tag(){
    cd $base_dir
    git add .
    git commit -m "Release v$version"
    git tag -a v$version -m "Release v$version"
    git push origin main --tags
}

github_release(){
    command -v gh >/dev/null || {
        printf '%s\n' 'GitHub CLI (gh) is required to create the release.' >&2
        return 1
    }

    notes_file=$(mktemp)
    awk -v release="v$version" '
        index($0, "## [" release "]") == 1 { found=1; next }
        found && /^## \[/ { exit }
        found { print }
    ' "$base_dir/CHANGELOG.md" > "$notes_file"

    gh release create "v$version" \
        --repo koxt2/DataRecovery \
        --title "v$version" \
        --notes-file "$notes_file"

    rm -f "$notes_file"
}

get_source(){
    cd "$base_dir"
    wget https://github.com/koxt2/DataRecovery/archive/refs/tags/v$version.tar.gz
    archive="v$version.tar.gz"
}   