#!/bin/bash

debian_files(){
    cd "$pkg_dir"
    target_debian_dir="$obs_dir/home:koxt2:debian/datarecovery_test"
    find "$target_debian_dir" -mindepth 1 -not -path "$target_debian_dir/.osc" -not -path "$target_debian_dir/.osc/*" -delete
    for f in changelog compat control copyright rules dsc; do
        cp "debian/debian.$f" "$target_debian_dir/debian.$f"
    done

    cp "$pkg_dir/v$version.tar.gz" "$target_debian_dir/v$version.orig.tar.gz"
}

debian_version(){
    sed -i "s/^Version: .*/Version: $version-1/" "$obs_dir/home:koxt2:debian/datarecovery_test/debian.dsc"
}

debian_changelog(){
    target_debian_dir="$obs_dir/home:koxt2:debian/datarecovery_test"
    date_string=$(LC_ALL=C date -u '+%a, %-d %b %Y %H:%M:%S +0000')
    formatted_changelog=$(sed -n "/^## \[v$version\]/,/^## \[/p" $base_dir/CHANGELOG.md |
        sed '$d' |
        sed -n 's/^- /  * /p')

    changelog="datarecovery ($version-1) UNRELEASED; urgency=medium
$formatted_changelog

 -- $user <$email> $date_string
 "

    {
        printf '%s\n' "$changelog"
        cat "$target_debian_dir/debian.changelog"
    } > "$target_debian_dir/debian.changelog.tmp"

    mv "$target_debian_dir/debian.changelog.tmp" "$target_debian_dir/debian.changelog"
}

debian_commit(){
    cd "$obs_dir/home:koxt2:debian/datarecovery_test"
    osc update
    osc addremove
    osc commit
}
