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
    osc addremove
    osc commit
}