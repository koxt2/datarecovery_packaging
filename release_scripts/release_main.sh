#!/bin/bash
set -euo pipefail

user=koxt2
email=koxt2@protonmail.com
version="0.6.1"

base_dir="/home/richard/Projects/github/DataRecovery"
obs_dir="/home/richard/Projects/obs"
pkg_dir="/home/richard/Projects/github/datarecovery_packaging"
proj_dir="/home/richard/Projects"

version_targets=(ubuntu)

source "release_upstream_setup.sh"
source "release_debian.sh"
source "release_ubuntu.sh"
source "release_fedora.sh"
source "release_opensuse.sh"
source "release_arch.sh"

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
    #meson_version "$version" "$base_dir"
    #app_changelog "$version" "$base_dir"
    #commit_tag "$version" "$base_dir"
    #github_release "$version" "$base_dir"

    get_source "$version" "$base_dir"

    version "$version" "$pkg_dir"
    changelog "$user" "$email" "$version" "$base_dir" "$pkg_dir"
    commit_repos 
}

main