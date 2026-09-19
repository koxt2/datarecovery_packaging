#!/bin/bash
set -euo pipefail

user=koxt2
email=koxt2@protonmail.com
version="0.6.1"

base_dir="/home/richard/Projects/github/DataRecovery"
obs_dir="/home/richard/Projects/obs/home:koxt2:Debian/datarecovery"

########## Meson 
meson_version(){
    sed -i "2s/version: 'v[0-9.]*'/version: 'v$version'/" meson.build
}

########## Debian
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

debian_build(){
    rm $obs_dir/*.tar.gz
    cp "$base_dir/v$version.tar.gz" "$base_dir/packaging/obs/deb/v$version.orig.tar.gz"
    cp -R "$base_dir/packaging/obs/deb/." "$obs_dir/"
    cd $obs_dir
    osc build
    cd $base_dir
}

debian_commit(){
    cd $obs_dir
    osc addremove
    osc commit
}
########## Setup 
version(){
    meson_version
    debian_version
}

changelog(){
    debian_changelog
}

build(){
    
    #git archive \
    #--format=tar.gz \
    #--prefix="DataRecovery-0.6.1/" \
    #v0.6.1 \
    #-o "../DataRecovery/v0.6.1.tar.gz"
    cd $base_dir

    git archive \
    --format=tar.gz \
    --prefix="DataRecovery-$version/" \
    -o "../DataRecovery/v$version.tar.gz" \
    v$version
    
    debian_build
}

commit(){
    debian_commit
}

cleanup(){
    rm "$base_dir/packaging/obs/deb/"*.tar.gz
    rm "$base_dir/v$version.tar.gz"
}
main(){
    cd $base_dir
    #version
    changelog
    #build
    #commit
    #cleanup
}

main
