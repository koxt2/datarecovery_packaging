#!/bin/bash
set -euo pipefail
base_dir="/home/richard/Projects/github/DataRecovery"
pkg_dir="/home/richard/Projects/github/datarecovery_packaging"
obs_dir="/home/richard/Projects/obs/home:koxt2:debian/datarecovery"

user=koxt2
email=koxt2@protonmail.com
version=$(sed -nE "s/^[[:space:]]*version:[[:space:]]*'v?([^']+)'.*$/\1/p" "$base_dir/meson.build" | head -n 1)

dsc(){
    sed -i "s/^Version: .*/Version: $version-1/" "$pkg_dir/debian/dsc"
    sed -i -E "/^Files:/,/^Package-List:/ s|^ [^[:space:]]+ [0-9]+ v?[0-9.]+\.orig\.tar\.gz$| 0 0 v$version.orig.tar.gz|" "$pkg_dir/debian/dsc"
}

changelog(){
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
        cat "$pkg_dir/debian/changelog"
    } > "$pkg_dir/debian/changelog.tmp"

    mv "$pkg_dir/debian/changelog.tmp" "$pkg_dir/debian/changelog"
}

commit_tag(){
    cd $base_dir
    git add .
    git commit -m "Release v$version"
    git tag -a v$version -m "Release v$version"
    cd $pkg_dir
}

build_debian_obs(){
    ################### this needs putting back to what is previously on github
    archive="$pkg_dir/debian/v$version.orig.tar.gz"

    git -C "$base_dir" archive \
        --format=tar.gz \
        --prefix="DataRecovery-$version/" \
        -o "$archive" \
        v$version

    archive_checksum=$(md5sum "$archive" | awk '{print $1}')
    archive_size=$(stat --format='%s' "$archive")
    sed -i -E "/^Files:/,/^Package-List:/ s|^ [^[:space:]]+ [0-9]+ v?[0-9.]+\.orig\.tar\.gz$| $archive_checksum $archive_size v$version.orig.tar.gz|" "$pkg_dir/debian/dsc"

    rm -f "$obs_dir"/*.tar.gz
    cp "$archive" "$obs_dir/v$version.orig.tar.gz"

    for file in control rules changelog compat copyright; do
        cp "$pkg_dir/debian/$file" "$obs_dir/$file"
    done
    dsc_file="datarecovery_${version}-1.dsc"
    cp "$pkg_dir/debian/dsc" "$obs_dir/$dsc_file"

    cd "$obs_dir"
    
    osc build --vm-type=qemu --clean Debian_12 x86_64 "$dsc_file"
    read -r -p "Press Enter to continue..."

    osc build --vm-type=qemu --clean Debian_13 x86_64 "$dsc_file"
    read -r -p "Press Enter to continue..."
}

commit(){
    cd "$obs_dir"
    osc addremove
    osc commit
}

cleanup(){
    rm "$pkg_dir/debian/v$version.orig.tar.gz"
}

main(){
    dsc
    changelog
    commit_tag
    build_debian_obs
    #commit
    #cleanup
}

main
