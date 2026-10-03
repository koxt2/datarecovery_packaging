#!/bin/bash

set -euo pipefail

user=koxt2
email=koxt2@protonmail.com
version="0.6.2.WIP"

base_dir="/home/richard/Projects/github/DataRecovery"
obs_dir="/home/richard/Projects/obs"
pkg_dir="/home/richard/Projects/github/datarecovery_packaging"

version_targets=(opensuse)

source "test_upstream_setup.sh"
source "test_debian.sh"
source "test_ubuntu.sh"
source "test_fedora.sh"
source "test_opensuse.sh"
source "test_arch.sh"

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
    meson_version "$version" "$base_dir" "$pkg_dir"
    app_changelog "$version" "$base_dir" "$pkg_dir"
    meta_info "$version" "$base_dir" "$pkg_dir"
    
    commit_tag "$version" "$base_dir" "$pkg_dir"

    create_source_tarball "$version" "$base_dir" "$pkg_dir"

    files "$version" "$obs_dir" "$pkg_dir"
    version "$version" "$obs_dir"
    changelog "$user" "$email" "$version" "$base_dir" "$obs_dir"
    
    commit_repos "$obs_dir"
    
    cleanup
}

main