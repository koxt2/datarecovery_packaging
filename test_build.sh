#!/bin/bash
set -euo pipefail

user=koxt2
email=koxt2@protonmail.com
version="0.6.2.WIP"

base_dir="/home/richard/Projects/github/DataRecovery"
obs_dir="/home/richard/Projects/obs"
pkg_dir="/home/richard/Projects/github/datarecovery_packaging"

version_targets=(arch)

########## Meson and app's changelog ##########
##############################################
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

########## Commit and Tag ##########
commit_tag(){
    cd $base_dir
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

########## Debian ##########
debian_files(){
    cd "$pkg_dir"
    target_dir="$obs_dir/home:koxt2:debian/datarecovery_test"
    find "$target_dir" -mindepth 1 -not -path "$target_dir/.osc" -not -path "$target_dir/.osc/*" -delete
    for f in changelog compat control copyright rules dsc; do
        if [[ "$f" == dsc ]]; then
            cp "debian/$f" "$target_dir/datarecovery.dsc"
        else
            cp "debian/$f" "$target_dir/debian.$f"
        fi
    done

    cp "$pkg_dir/v$version.tar.gz" "$target_dir/v$version.orig.tar.gz"
}

debian_version(){
    sed -i "s/^Version: .*/Version: $version-1/" "$obs_dir/home:koxt2:debian/datarecovery_test/datarecovery.dsc"
}

debian_changelog(){
    target_dir="$obs_dir/home:koxt2:debian/datarecovery_test"
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
        cat "$target_dir/debian.changelog"
    } > "$target_dir/debian.changelog.tmp"

    mv "$target_dir/debian.changelog.tmp" "$target_dir/debian.changelog"
}

debian_commit(){
    cd "$obs_dir/home:koxt2:debian/datarecovery_test"
    #osc update
    osc addremove
    osc commit
}

########## Fedora ##########
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
    #osc update
    osc addremove
    osc commit
}

########## openSUSE ##########
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
$osc_date_string $user <$email>

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
    #osc update
    osc addremove
    osc commit
}

########## Arch ##########
arch_files(){
    cd "$pkg_dir"
    target_dir="$obs_dir/home:koxt2:arch/datarecovery_test"
    find "$target_dir" -mindepth 1 -not -path "$target_dir/.osc" -not -path "$target_dir/.osc/*" -delete
    cp "aur/PKGBUILD" "$target_dir/PKGBUILD"
    sed -i \
        -e 's|^source=|#source=|' \
        -e 's|^#source=("v\$pkgver\.tar\.gz")$|source=("v$pkgver.tar.gz")|' \
        "$target_dir/PKGBUILD"
    cp "v$version.tar.gz" "$target_dir/v$version.tar.gz"
}

arch_version(){
    sed -i "s/^pkgver=.*/pkgver=$version/" "$obs_dir/home:koxt2:arch/datarecovery_test/PKGBUILD"
    
}

arch_commit(){
    cd "$obs_dir/home:koxt2:arch/datarecovery_test"
    #osc update
    osc addremove
    osc commit
}

########## Setup 
files(){
    for target in "${version_targets[@]}"; do
        "${target}_files"
    done
}

version(){
    for target in "${version_targets[@]}"; do
        "${target}_version"
    done
}

changelog(){
    for target in "${version_targets[@]}"; do
        [[ "$target" == "arch" ]] && continue
        "${target}_changelog"
    done
}

commit_repos(){
    for target in "${version_targets[@]}"; do
        "${target}_commit"
    done
}

cleanup(){
    cd "$pkg_dir"
    rm ./*.tar.gz
    cd "$base_dir"
    git tag -d "v$version"
    git reset origin/main --hard
}
main(){
    meson_version
    app_changelog
    commit_tag

    create_source_tarball

    files
    version
    changelog
    commit_repos
    cleanup
}

main