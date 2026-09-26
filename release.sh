#!/bin/bash
set -euo pipefail

user=koxt2
email=koxt2@protonmail.com
version="0.6.1"

base_dir="/home/richard/Projects/github/DataRecovery"
obs_dir="/home/richard/Projects/obs"
pkg_dir="/home/richard/Projects/github/datarecovery_packaging"

version_targets=(fedora)

########## Meson and app's changelog ##########
##############################################
meson_version(){
    sed -i "2s/version: 'v[0-9.]*'/version: 'v$version'/" meson.build
}

app_changelog(){
    date_string=$(date -u '+%Y-%m-%d')
    sed -i "0,/^## \[[Uu]nreleased\]/s//## [v$version] - $date_string/" "$base_dir/CHANGELOG.md"
}

########## Commit and Tag ##########
commit_tag(){
    cd $base_dir
    git add .
    git commit -m "Release v$version"
    git tag -a v$version -m "Release v$version"
    #git push origin main --tags
}
########## Release on github ##########
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

########## Get Source ##########
get_source(){
   wget https://github.com/koxt2/DataRecovery/archive/refs/tags/v$version.tar.gz
   archive="v$version.tar.gz"
}   

########## Debian (obs) ##########

debian_version(){
    sed -i "5s/^Version: .*/Version: $version-1/" ./debian/dsc
    archive_checksum=$(md5sum "$archive" | awk '{print $1}')
    archive_size=$(stat --format='%s' "$archive")
    sed -i -E "/^Files:/,/^Package-List:/ s|^ [^[:space:]]+ [0-9]+ v?[0-9.]+\.orig\.tar\.gz$| $archive_checksum $archive_size v$version.orig.tar.gz|" "./debian/dsc"
}

debian_changelog(){
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
        cat "./debian/changelog"
    } > "./debian/changelog.tmp"

    mv "./debian/changelog.tmp" "./debian/changelog"
}

debian_commit(){
    target_dir="$obs_dir/home:koxt2:debian/datarecovery"
    cd "$target_dir"
    osc update
    rm -f ./*.tar.gz
    rm -f ./*.dsc
    rm -f ./debian.*
    cd "$pkg_dir"
    cp "$archive" "$target_dir/v$version.orig.tar.gz"
    for f in changelog compat control copyright rules; do
        cp "debian/$f" "$target_dir/debian.$f"
    done
    cp "debian/dsc" "$target_dir/debian.dsc"
    cd "$target_dir"
    osc addremove
    osc commit
}

fedora_version(){
    sed -i "4s/^Version:        .*/Version:        $version/" packaging/copr/datarecovery.spec
}

fedora_changelog(){
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
    ' packaging/copr/datarecovery.spec > packaging/copr/datarecovery.spec.tmp

mv packaging/copr/datarecovery.spec.tmp packaging/copr/datarecovery.spec
}

fedora_commit(){
    mkdir -p "$pkg_dir"/copr/temp/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}
    cp "$pkg_dir/copr/datarecovery.spec" "$pkg_dir/copr/temp/SPECS/"
    cp "$pkg_dir/copr/datarecovery-rpmlintrc" "$pkg_dir/copr/temp/SOURCES/"
    cp "$pkg_dir/$archive" "$pkg_dir/copr/temp/SOURCES/v$version.tar.gz"
    #wget -O "$topdir/SOURCES/v$version.tar.gz" \
    #  "https://github.com/koxt2/DataRecovery/archive/refs/tags/v$version.tar.gz"

    rpmbuild -bs --define "_topdir $pkg_dir/copr/temp" \
      "$pkg_dir/copr/temp/SPECS/datarecovery.spec"

    copr build koxt2/datarecovery \
      "$pkg_dir/copr/temp/SRPMS/datarecovery-$version-0.src.rpm"

    rm -rf "$pkg_dir/copr/temp"
}

########## Setup 
version(){
    for target in "${version_targets[@]}"; do
        "${target}_version"
    done
}

changelog(){
    for target in "${version_targets[@]}"; do
        "${target}_changelog"
    done
}

commit_repos(){
    for target in "${version_targets[@]}"; do
        "${target}_commit"
    done
}

main(){
    #meson_version
    #app_changelog
    #commit_tag
    #github_release

    get_source

    #version
    #changelog
    commit_repos
}

main
