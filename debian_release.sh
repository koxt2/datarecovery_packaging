#!/bin/bash
set -euo pipefail

user=koxt2
email=koxt2@protonmail.com
version="0.6.2"

base_dir="/home/richard/Projects/github/DataRecovery"
obs_dir="/home/richard/Projects/obs"

meson_version(){
    sed -i "2s/version: 'v[0-9.]*'/version: 'v$version'/" meson.build
}

debian_version(){
    sed -i "5s/^Version: .*/Version: $version/" packaging/obs/deb/datarecovery.dsc
    sed -i "11s/^ 0 0 datarecovery_[0-9.]*\.orig\.tar\.gz/ 0 0 datarecovery_$version.orig.tar.gz/" packaging/obs/deb/datarecovery.dsc
}

debian_changelog(){
    deb_date_string=$(LC_ALL=C date -u '+%a, %-d %b %Y %H:%M:%S +0000')
    deb_formatted_changelog=$(sed -n "/^## \[v$version\]/,/^## \[/p" CHANGELOG.md |
        sed '$d' |
        sed -n 's/^- /  * /p')

    deb_changelog="datarecovery ($version-1) UNRELEASED; urgency=medium
$deb_formatted_changelog

 -- $user <$email>  $deb_date_string
 "

    {
        printf '%s\n' "$deb_changelog"
        cat packaging/obs/deb/debian.changelog
    } > packaging/obs/deb/debian.changelog.tmp

    mv packaging/obs/deb/debian.changelog.tmp packaging/obs/deb/debian.changelog
}

commit_tag(){
    cd $base_dir
    git add .
    git commit -m "Release v$version"
    git tag -a v$version -m "Release v$version"
    #git push origin main --tags
}

debian_build(){
    git archive \
        --format=tar.gz \
        --prefix="DataRecovery-$version/" \
        -o "$base_dir/v$version.tar.gz" \
        v$version \
        -- . ':(exclude)debian' ':(exclude)packaging' 

    rm $obs_dir/home:koxt2:debian/datarecovery/*.tar.gz
    cp "$base_dir/v$version.tar.gz" "$obs_dir/home:koxt2:debian/datarecovery/v$version.orig.tar.gz"
    cp -R "$base_dir/packaging/obs/deb/." "$obs_dir/home:koxt2:debian/datarecovery"
    cd $obs_dir/home:koxt2:debian/datarecovery
    
    osc build Debian_12
    read -r -p "Press Enter to continue..."

    osc build Debian_13
    read -r -p "Press Enter to continue..."
    cd $base_dir
}

debian_commit(){
    cd $obs_dir/home:koxt2:debian/datarecovery
    osc addremove
    osc commit
}

cleanup(){
    rm "$base_dir/v$version.tar.gz"
}
main(){
    cd $base_dir
    meson_version
    debian_version
    debian_changelog
    commit_tag
    debian_build
    #fedora_copr_build
    #commit_github
    #commit_repos
    cleanup
}

main
