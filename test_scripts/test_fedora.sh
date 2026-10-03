#!/bin/bash

fedora_files(){
    cd "$pkg_dir"
    target_dir="$obs_dir/home:koxt2:fedora/datarecovery_test"
    find "$target_dir" -mindepth 1 -not -path "$target_dir/.osc" -not -path "$target_dir/.osc/*" -delete
    cp "copr/datarecovery.spec" "$target_dir/datarecovery.spec"
    cp "copr/datarecovery-rpmlintrc" "$target_dir/datarecovery-rpmlintrc"
    cp "v$version.tar.gz" "$target_dir/v$version.tar.gz"
}

fedora_version(){
    sed -i "4s/^Version:        .*/Version:        $version/" "$obs_dir/home:koxt2:fedora/datarecovery_test/datarecovery.spec"
}   

fedora_changelog(){
    target_dir="$obs_dir/home:koxt2:fedora/datarecovery_test"
        fed_date_string=$(LC_ALL=C date -u '+%a %b %-d %Y')
    fed_formatted_changelog=$(sed -n "/^## \[v$version\]/,/^## \[/p" "$base_dir/CHANGELOG.md" |
        sed '$d' |
        sed -n 's/^[[:space:]]*-[[:space:]]*/- /p')

    fed_changelog="* $fed_date_string $user <$email> - $version
$fed_formatted_changelog
"
        awk -v changelog="$fed_changelog" '
        /^%changelog$/ {
            print
            printf "%s\n", changelog
            next
        }
        { print }
    ' "$target_dir/datarecovery.spec" > "$target_dir/datarecovery.spec.tmp"

mv "$target_dir/datarecovery.spec.tmp" "$target_dir/datarecovery.spec"
}

fedora_commit(){
    cd "$obs_dir/home:koxt2:fedora/datarecovery_test"
    osc update
    osc addremove
    osc commit
}