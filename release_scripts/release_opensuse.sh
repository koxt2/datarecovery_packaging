opensuse_version(){
    sed -i "20s/^Version:        .*/Version:        $version/" "$pkg_dir/suse/datarecovery.spec"
}

opensuse_changelog(){
    target_dir="$pkg_dir/suse"
    osc_date_string=$(LC_ALL=C date -u '+%a %b %d %H:%M:%S UTC %Y')
    osc_formatted_changelog=$(sed -n "/^## \[v$version\]/,/^## \[/p" "$base_dir/CHANGELOG.md" |
        sed '$d' |
        sed -n 's/^[[:space:]]*-[[:space:]]*/  * /p')

    osc_changelog="-------------------------------------------------------------------
$osc_date_string - $user <$email>

- Update to $version
$osc_formatted_changelog
"

    {
        printf '%s\n' "$osc_changelog"
        cat "$target_dir/datarecovery.changes"
    } > "$target_dir/datarecovery.changes.tmp"

    mv "$target_dir/datarecovery.changes.tmp" "$target_dir/datarecovery.changes"
}

opensuse_commit(){
    cd "$pkg_dir/suse"
    target_suse_dir="$obs_dir/home:koxt2:openSUSE/datarecovery"
    find "$target_suse_dir" -mindepth 1 \
        -not -path "$target_suse_dir/.osc" -not -path "$target_suse_dir/.osc/*" \
        -not -path "$target_suse_dir/.git" -not -path "$target_suse_dir/.git/*" \
        -not -name .gitignore -not -name .gitattributes -delete
    for f in datarecovery.changes datarecovery.spec datarecovery-rpmlintrc; do
        cp "$f" "$target_suse_dir/$f"
    done
    cp "$base_dir/v$version.tar.gz" "$target_suse_dir"
    cd "$obs_dir/home:koxt2:openSUSE/datarecovery"
    git add -A
    git commit -m "Update to $version"
    git push
}