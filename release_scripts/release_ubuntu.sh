ubuntu_version(){
    sed -i "5s/^Version: .*/Version: $version-1/" "$pkg_dir/debian/debian.dsc"
}

ubuntu_changelog(){
    if grep -q "^datarecovery ($version-1) " "$pkg_dir/debian/debian.changelog"; then
        return
    fi

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
        cat "$pkg_dir/debian/debian.changelog"
    } > "$pkg_dir/debian/debian.changelog.tmp"

    mv "$pkg_dir/debian/debian.changelog.tmp" "$pkg_dir/debian/debian.changelog"
}

ubuntu_commit() {
    cd "$pkg_dir"
    target_ubuntu_dir="$obs_dir/home:koxt2:ubuntu/datarecovery"
    find "$target_ubuntu_dir" -mindepth 1 -not -path "$target_ubuntu_dir/.osc" -not -path "$target_ubuntu_dir/.osc/*" -delete
    for f in changelog compat control copyright rules dsc; do
        cp "debian/debian.$f" "$target_ubuntu_dir/debian.$f"
    done
    cp "$base_dir/v$version.tar.gz" "$target_ubuntu_dir/v$version.orig.tar.gz"
    cd "$obs_dir/home:koxt2:ubuntu/datarecovery"
    osc addremove
    osc commit
}