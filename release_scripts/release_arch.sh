arch_version(){
    sed -i "s/^pkgver=.*/pkgver=$version/" "$pkg_dir/aur/PKGBUILD"
    sed -i -E \
        -e "s|^([[:space:]]*pkgver = ).*|\\1$version|" \
        -e "s|^([[:space:]]*source = )datarecovery-[^:]*::https://github.com/koxt2/DataRecovery/archive/refs/tags/v[^[:space:]]*|\\1datarecovery-$version.tar.gz::https://github.com/koxt2/DataRecovery/archive/refs/tags/v$version.tar.gz|" \
        "$pkg_dir/aur/.SRCINFO"
}

arch_commit(){
    target_dir="$proj_dir/aur/datarecovery"
    git -C "$target_dir" pull --ff-only
    cp "$pkg_dir/aur/PKGBUILD" "$target_dir/PKGBUILD"
    cp "$pkg_dir/aur/.SRCINFO" "$target_dir/.SRCINFO"
    git -C "$target_dir" add PKGBUILD .SRCINFO
    git -C "$target_dir" -c user.name="$user" -c user.email="$email" \
        commit -m "Update to v$version" -- PKGBUILD .SRCINFO
    git -C "$target_dir" push
}