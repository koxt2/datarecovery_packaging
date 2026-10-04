#!/bin/bash
arch_version(){
    sed -i "s/^pkgver=.*/pkgver=$version/" "$pkg_dir/aur/PKGBUILD"
    sed -i -E \
        -e "s|^([[:space:]]*pkgver = ).*|\\1$version|" \
        -e "s|^([[:space:]]*source = )datarecovery-[^:]*::https://github.com/koxt2/DataRecovery/archive/refs/tags/v[^[:space:]]*|\\1datarecovery-$version.tar.gz::https://github.com/koxt2/DataRecovery/archive/refs/tags/v$version.tar.gz|" \
        "$pkg_dir/aur/.SRCINFO"
}

arch_commit(){
    # ssh-keygen -t ed25519 -C "richard@opensusetumbleweed" -f ~/.ssh/arch-tumbleweed
    # cat ~/.ssh/arch-tumbleweed.pub
    # Then add printout to aur profile
    # Tell ssh to use the key for aur
    
    #cat >> ~/.ssh/config << 'EOF'
    #Host aur.archlinux.org
    #  IdentityFile ~/.ssh/arch-tumbleweed
    #  IdentitiesOnly yes
    #  User aur
    
    #EOF
    
    #chmod 600 ~/.ssh/config
    
    # Accept key from aur
    #ssh -T aur@aur.archlinux.org
    
    target_dir="$pkg_dir/aur"
    git -C "$target_dir" add PKGBUILD .SRCINFO
    git -C "$target_dir" commit -m "Update to v$version"
    git -C "$target_dir" push
}