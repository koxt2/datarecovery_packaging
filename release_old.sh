#!/bin/bash
set -euo pipefail

user=koxt2
email=koxt2@protonmail.com
version="0.6.2"

base_dir="/home/richard/Projects/github/DataRecovery"
obs_dir="/home/richard/Projects/obs"

version_targets=(fedora)





########## Version ########## 
#############################
meson_version(){
    sed -i "2s/version: 'v[0-9.]*'/version: 'v$version'/" meson.build
}

debian_version(){
    sed -i "5s/^Version: .*/Version: $version/" packaging/obs/deb/datarecovery.dsc
    sed -i "11s/^ 0 0 datarecovery_[0-9.]*\.orig\.tar\.gz/ 0 0 datarecovery_$version.orig.tar.gz/" packaging/obs/deb/datarecovery.dsc
}

fedora_version(){
    sed -i "4s/^Version:        .*/Version:        $version/" packaging/copr/datarecovery.spec
}
#############################





########## Changelog ##########
###############################
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

fedora_changelog(){
    fed_date_string=$(LC_ALL=C date -u '+%a %b %-d %Y')
    fed_formatted_changelog=$(sed -n "/^## \[v$version\]/,/^## \[/p" CHANGELOG.md |
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
#############################




########## Test build ##########
################################
debian_build(){
    #git archive \
    #    --format=tar.gz \
    #    --prefix="DataRecovery-$version/" \
    #    -o "$base_dir/packaging/obs/deb/v$version.orig.tar.gz" \
    #    v$version \
    #    -- . ':(exclude)debian' \
    #    -- . ':(exclude)packaging'

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

########## Fedora




fedora_build(){
    rm $obs_dir/home:koxt2:fedora/datarecovery/*.tar.gz
    cp "$base_dir/v$version.tar.gz" "$obs_dir/home:koxt2:fedora/datarecovery"
    cp -R "$base_dir/packaging/copr/." "$obs_dir/home:koxt2:fedora/datarecovery"
    cd $obs_dir/home:koxt2:fedora/datarecovery
    
    osc build --no-verify --checks Fedora_43
    rpmlint -r "$base_dir/packaging/copr/datarecovery-rpmlintrc" /var/tmp/build-root/Fedora_43-x86_64/home/abuild/rpmbuild/RPMS/noarch/datarecovery-$version-0.noarch.rpm
    read -r -p "Press Enter to continue..."
    
    osc build --no-verify --checks Fedora_44
    rpmlint -r "$base_dir/packaging/copr/datarecovery-rpmlintrc" /var/tmp/build-root/Fedora_44-x86_64/home/abuild/rpmbuild/RPMS/noarch/datarecovery-$version-0.noarch.rpm
    read -r -p "Press Enter to continue..."
    
    osc build --no-verify --checks Fedora_Rawhide
    rpmlint -r "$base_dir/packaging/copr/datarecovery-rpmlintrc" /var/tmp/build-root/Fedora_Rawhide-x86_64/home/abuild/rpmbuild/RPMS/noarch/datarecovery-$version-0.noarch.rpm
    read -r -p "Press Enter to continue..."
    
    cd $base_dir
}

########## Setup 
version(){
    for target in "${version_targets[@]}"; do
        "${target}_version"
    done
    
    meson_version
}

changelog(){
    for target in "${version_targets[@]}"; do
        "${target}_changelog"
    done
}

commit_tag(){
    cd $base_dir
    git add .
    git commit -m "Release v$version"
    git tag -a v$version -m "Release v$version"
    git push origin main --tags
}

build(){
    git archive \
        --format=tar.gz \
        --prefix="DataRecovery-$version/" \
        -o "$base_dir/v$version.tar.gz" \
        v$version \
        -- . ':(exclude)debian' ':(exclude)packaging'    
    
    for target in "${version_targets[@]}"; do
        "${target}_build"
    done
}

fedora_copr_build(){
    command -v copr-cli >/dev/null || {
        printf '%s\n' 'copr-cli is required to submit the Copr build.' >&2
        return 1
    }

    copr-cli buildscm \
        --clone-url https://github.com/koxt2/DataRecovery.git \
        --commit "v$version" \
        --spec packaging/copr/datarecovery.spec \
        --method rpkg \
        --nowait \
        koxt2/datarecovery
}

commit_repos(){
    debian_commit
    fedora_commit
}

cleanup(){
    #rm "$base_dir/packaging/obs/deb/"*.tar.gz
    rm "$base_dir/v$version.tar.gz"
}
main(){
    cd $base_dir
    version
    changelog
    commit_tag
    build
    fedora_copr_build
    #commit_github
    #commit_repos
    cleanup
}

main
