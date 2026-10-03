#!/bin/bash

opensuse_files(){
    cd "$pkg_dir"
    target_dir="$obs_dir/home:koxt2:openSUSE/datarecovery_test"
    find "$target_dir" -mindepth 1 -not -path "$target_dir/.osc" -not -path "$target_dir/.osc/*" -delete
    cp "suse/datarecovery.spec" "$target_dir/datarecovery.spec"
    cp "suse/datarecovery-rpmlintrc" "$target_dir/datarecovery-rpmlintrc"
    cp "suse/datarecovery.changes" "$target_dir/datarecovery.changes"
    cp "v$version.tar.gz" "$target_dir/v$version.tar.gz"
}

opensuse_version(){
    sed -i "20s/^Version:        .*/Version:        $version/" "$obs_dir/home:koxt2:openSUSE/datarecovery_test/datarecovery.spec"
}

opensuse_changelog(){
    target_dir="$obs_dir/home:koxt2:openSUSE/datarecovery_test"
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
    cd "$obs_dir/home:koxt2:openSUSE/datarecovery_test"
    osc update
    osc addremove
    osc commit
}