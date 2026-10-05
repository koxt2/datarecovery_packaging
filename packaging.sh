#!/bin/bash
set -euo pipefail
version="0.7.1"

mode=(
    test
    #release
)

version_targets=(
  arch
  debian
  ubuntu
  fedora
  opensuse
)

user=koxt2
email=koxt2@protonmail.com

base_dir="/home/richard/Projects/github/DataRecovery"
obs_dir="/home/richard/Projects/obs"
pkg_dir="/home/richard/Projects/github/datarecovery_packaging"
proj_dir="/home/richard/Projects"

version(){
    for target in "${version_targets[@]}"; do
        "${mode}_${target}_version"
    done
}

changelog(){
    for target in "${version_targets[@]}"; do
        [[ "$target" == "arch" ]] && continue
        "${mode}_${target}_changelog"
    done
}

commit_repos(){
    for target in "${version_targets[@]}"; do
        "${mode}_${target}_commit"
    done
}

meta_info(){
    metainfo_file="$base_dir/data/com.github.koxt2.datarecovery.metainfo.xml"
    date_string=$(date -u '+%Y-%m-%d')
    items=$(sed -n "/^## \[v$version\]/,/^## \[/p" "$base_dir/CHANGELOG.md" |
        sed '$d' |
        sed -n -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' \
               -e 's|^- \(.*\)|          <li>\1</li>|p')

    entry="    <release version=\"$version\" date=\"$date_string\">
      <description>
        <p>Release v$version</p>
        <ul>
$items
        </ul>
      </description>
    </release>"

    awk -v entry="$entry" '/<releases>/ && !done { print; print entry; done=1; next } { print }' \
        "$metainfo_file" > "$metainfo_file.tmp"

    mv "$metainfo_file.tmp" "$metainfo_file"
}

#======================================================================
# TEST
#======================================================================
test_files(){
    for target in "${version_targets[@]}"; do
        "test_${target}_files"
    done
}

test_meson_version(){
    sed -i "2s/version: 'v[0-9.]*'/version: 'v$version'/" "$base_dir/meson.build"
}

test_app_changelog(){
    date_string=$(date -u '+%Y-%m-%d')
    sed -i "0,/^## \[[Uu]nreleased\]/s//## [v$version] - $date_string/" "$base_dir/CHANGELOG.md"
}

test_commit_tag(){
    git -C "$base_dir" add .
    git -C "$base_dir" commit -m "Release v$version"
    git -C "$base_dir" tag -a v$version -m "Release v$version"
}

test_create_source_tarball(){
    git -C "$base_dir" archive \
        --format=tar.gz \
        --prefix="DataRecovery-$version/" \
        -o "$pkg_dir/v$version.tar.gz" \
        v$version
}

test_debian_files(){
    target_debian_dir="$obs_dir/home:koxt2:debian/datarecovery_test"
    find "$target_debian_dir" -mindepth 1 -not -path "$target_debian_dir/.osc" -not -path "$target_debian_dir/.osc/*" -delete
    for f in changelog compat control copyright rules dsc; do
        cp "debian/debian.$f" "$target_debian_dir/debian.$f"
    done

    cp "$pkg_dir/v$version.tar.gz" "$target_debian_dir/v$version.orig.tar.gz"
}

test_debian_version(){
    sed -i "s/^Version: .*/Version: $version-1/" "$obs_dir/home:koxt2:debian/datarecovery_test/debian.dsc"
}

test_debian_changelog(){
    target_debian_dir="$obs_dir/home:koxt2:debian/datarecovery_test"
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
        cat "$target_debian_dir/debian.changelog"
    } > "$target_debian_dir/debian.changelog.tmp"

    mv "$target_debian_dir/debian.changelog.tmp" "$target_debian_dir/debian.changelog"
}

test_debian_commit(){
    osc -C "$obs_dir/home:koxt2:debian/datarecovery_test" update
    osc -C "$obs_dir/home:koxt2:debian/datarecovery_test" addremove
    osc -C "$obs_dir/home:koxt2:debian/datarecovery_test" commit
}

test_ubuntu_files(){
    target_ubuntu_dir="$obs_dir/home:koxt2:ubuntu/datarecovery_test"
    find "$target_ubuntu_dir" -mindepth 1 -not -path "$target_ubuntu_dir/.osc" -not -path "$target_ubuntu_dir/.osc/*" -delete
    for f in changelog compat control copyright rules dsc; do
        cp "debian/debian.$f" "$target_ubuntu_dir/debian.$f"
    done

    cp "$pkg_dir/v$version.tar.gz" "$target_ubuntu_dir/v$version.orig.tar.gz"
}

test_ubuntu_version(){
    sed -i "s/^Version: .*/Version: $version-1/" "$obs_dir/home:koxt2:ubuntu/datarecovery_test/debian.dsc"
}

test_ubuntu_changelog(){
    target_ubuntu_dir="$obs_dir/home:koxt2:ubuntu/datarecovery_test"
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
        cat "$target_ubuntu_dir/debian.changelog"
    } > "$target_ubuntu_dir/debian.changelog.tmp"

    mv "$target_ubuntu_dir/debian.changelog.tmp" "$target_ubuntu_dir/debian.changelog"
}

test_ubuntu_commit(){
    osc -C "$obs_dir/home:koxt2:ubuntu/datarecovery_test" update
    osc -C "$obs_dir/home:koxt2:ubuntu/datarecovery_test" addremove
    osc -C "$obs_dir/home:koxt2:ubuntu/datarecovery_test" commit
}

test_fedora_files(){
    target_dir="$obs_dir/home:koxt2:fedora/datarecovery_test"
    find "$target_dir" -mindepth 1 -not -path "$target_dir/.osc" -not -path "$target_dir/.osc/*" -delete
    cp "copr/datarecovery.spec" "$target_dir/datarecovery.spec"
    cp "copr/datarecovery-rpmlintrc" "$target_dir/datarecovery-rpmlintrc"
    cp "v$version.tar.gz" "$target_dir/v$version.tar.gz"
}

test_fedora_version(){
    sed -i "4s/^Version:        .*/Version:        $version/" "$obs_dir/home:koxt2:fedora/datarecovery_test/datarecovery.spec"
}   

test_fedora_changelog(){
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

test_fedora_commit(){
    osc -C "$obs_dir/home:koxt2:fedora/datarecovery_test" update
    osc -C "$obs_dir/home:koxt2:fedora/datarecovery_test" addremove
    osc -C "$obs_dir/home:koxt2:fedora/datarecovery_test" commit
}

test_opensuse_files(){
    target_dir="$obs_dir/home:koxt2:openSUSE/datarecovery_test"
    find "$target_dir" -mindepth 1 -not -path "$target_dir/.osc" -not -path "$target_dir/.osc/*" -delete
    cp "suse/datarecovery.spec" "$target_dir/datarecovery.spec"
    cp "suse/datarecovery-rpmlintrc" "$target_dir/datarecovery-rpmlintrc"
    cp "suse/datarecovery.changes" "$target_dir/datarecovery.changes"
    cp "v$version.tar.gz" "$target_dir/v$version.tar.gz"
}

test_opensuse_version(){
    sed -i "20s/^Version:        .*/Version:        $version/" "$obs_dir/home:koxt2:openSUSE/datarecovery_test/datarecovery.spec"
}

test_opensuse_changelog(){
    target_dir="$obs_dir/home:koxt2:openSUSE/datarecovery_test"
    osc_date_string=$(LC_ALL=C date -u '+%a %b %d %H:%M:%S UTC %Y')
    osc_formatted_changelog=$(sed -n "/^## \[v$version\]/,/^## \[/p" "$base_dir/CHANGELOG.md" |
        sed '$d' |
        sed -n 's/^[[:space:]]*-[[:space:]]*/  * /p')

    osc_changelog="-------------------------------------------------------------------
$osc_date_string - $user <$email>

- Update to $version
$osc_formatted_changelog
"

    {
        printf '%s\n' "$osc_changelog"
        cat "$target_dir/datarecovery.changes"
    } > "$target_dir/datarecovery.changes.tmp"

    mv "$target_dir/datarecovery.changes.tmp" "$target_dir/datarecovery.changes"
}

test_opensuse_commit(){
    osc -C "$obs_dir/home:koxt2:openSUSE/datarecovery_test" update
    osc -C "$obs_dir/home:koxt2:openSUSE/datarecovery_test" addremove
    osc -C "$obs_dir/home:koxt2:openSUSE/datarecovery_test" commit
}

test_arch_files(){
    target_dir="$obs_dir/home:koxt2:arch/datarecovery_test"
    find "$target_dir" -mindepth 1 -not -path "$target_dir/.osc" -not -path "$target_dir/.osc/*" -delete
    cp "aur/PKGBUILD" "$target_dir/PKGBUILD"
    sed -i \
        -e 's|^source=|#source=|' \
        -e 's|^#source=("v\$pkgver\.tar\.gz")$|source=("v$pkgver.tar.gz")|' \
        "$target_dir/PKGBUILD"
    cp "v$version.tar.gz" "$target_dir/v$version.tar.gz"
}

test_arch_version(){
    sed -i "s/^pkgver=.*/pkgver=$version/" "$obs_dir/home:koxt2:arch/datarecovery_test/PKGBUILD"
    
}

test_arch_commit(){
    osc -C "$obs_dir/home:koxt2:arch/datarecovery_test" update
    osc -C "$obs_dir/home:koxt2:arch/datarecovery_test" addremove
    osc -C "$obs_dir/home:koxt2:arch/datarecovery_test" commit
}

test_cleanup(){
    rm ./*.tar.gz
    git -C "$base_dir" tag -d "v$version"
    git -C "$base_dir" reset origin/main --hard
}

#======================================================================
# RELEASE
#======================================================================

release_meson_version(){
    sed -i "2s/version: 'v[0-9.]*'/version: 'v$version'/" "$base_dir/meson.build"
}

release_app_changelog(){
    date_string=$(date -u '+%Y-%m-%d')
    sed -i "0,/^## \[[Uu]nreleased\]/s//## [v$version] - $date_string/" "$base_dir/CHANGELOG.md"
}

release_commit_tag(){
    git -C $base_dir add .
    git -C $base_dir commit -m "Release v$version"
    git -C $base_dir tag -a v$version -m "Release v$version"
    git -C $base_dir push origin main --tags
}

release_github_release(){
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

release_get_source(){
    wget -P "$base_dir" https://github.com/koxt2/DataRecovery/archive/refs/tags/v$version.tar.gz
    archive="v$version.tar.gz"
}   

release_cleanup(){
    rm -f "$base_dir"/v$version.tar.gz*
}

release_debian_version(){
    sed -i "5s/^Version: .*/Version: $version-1/" "$pkg_dir/debian/debian.dsc"
}

release_debian_changelog(){
    if grep -q "^datarecovery ($version-1) " "$pkg_dir/debian/debian.changelog"; then
        return
    fi

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
        cat "$pkg_dir/debian/debian.changelog"
    } > "$pkg_dir/debian/debian.changelog.tmp"

    mv "$pkg_dir/debian/debian.changelog.tmp" "$pkg_dir/debian/debian.changelog"
}

release_debian_commit() {
    target_debian_dir="$obs_dir/home:koxt2:debian/datarecovery"
    find "$target_debian_dir" -mindepth 1 -not -path "$target_debian_dir/.osc" -not -path "$target_debian_dir/.osc/*" -delete
    for f in changelog compat control copyright rules dsc; do
        cp "debian/debian.$f" "$target_debian_dir/debian.$f"
    done
    cp "$base_dir/v$version.tar.gz" "$target_debian_dir/v$version.orig.tar.gz"
    osc -C "$obs_dir/home:koxt2:debian/datarecovery" addremove
    osc -C "$obs_dir/home:koxt2:debian/datarecovery" commit
}

release_ubuntu_version(){
    sed -i "5s/^Version: .*/Version: $version-1/" "$pkg_dir/debian/debian.dsc"
}

release_ubuntu_changelog(){
    if grep -q "^datarecovery ($version-1) " "$pkg_dir/debian/debian.changelog"; then
        return
    fi

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
        cat "$pkg_dir/debian/debian.changelog"
    } > "$pkg_dir/debian/debian.changelog.tmp"

    mv "$pkg_dir/debian/debian.changelog.tmp" "$pkg_dir/debian/debian.changelog"
}

release_ubuntu_commit() {
    target_ubuntu_dir="$obs_dir/home:koxt2:ubuntu/datarecovery"
    find "$target_ubuntu_dir" -mindepth 1 -not -path "$target_ubuntu_dir/.osc" -not -path "$target_ubuntu_dir/.osc/*" -delete
    for f in changelog compat control copyright rules dsc; do
        cp "debian/debian.$f" "$target_ubuntu_dir/debian.$f"
    done
    cp "$base_dir/v$version.tar.gz" "$target_ubuntu_dir/v$version.orig.tar.gz"
    osc -C "$obs_dir/home:koxt2:ubuntu/datarecovery" addremove
    osc -C "$obs_dir/home:koxt2:ubuntu/datarecovery" commit
}

release_fedora_version(){
    sed -i "4s/^Version:        .*/Version:        $version/" "$pkg_dir/copr/datarecovery.spec"
}

release_fedora_changelog(){
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
    ' "$pkg_dir/copr/datarecovery.spec" > "$pkg_dir/copr/datarecovery.spec.tmp"

mv "$pkg_dir/copr/datarecovery.spec.tmp" "$pkg_dir/copr/datarecovery.spec"
}

release_fedora_commit() {
    #copr-cli isn't available in opensuse sooo....
    #python3 -m venv ~/.venvs/copr && ~/.venvs/copr/bin/pip install copr-cli
    #ln -s ~/.venvs/copr/bin/copr-cli ~/.local/bin/copr-cli
    # Then create the API config:
    # Log in at https://copr.fedorainfracloud.org/api/.
    # Copy the config block it shows into ~/.config/copr.
    # Check it works with copr-cli list koxt2.
    git -C "$pkg_dir" add copr/datarecovery.spec
    git -C "$pkg_dir" commit -m "Update copr spec to v$version"
    git -C "$pkg_dir" push
    copr-cli buildscm koxt2/datarecovery \
        --clone-url https://github.com/koxt2/datarecovery_packaging.git \
        --commit main --subdir copr --spec datarecovery.spec --type git --nowait

}

release_opensuse_version(){
    sed -i "20s/^Version:        .*/Version:        $version/" "$pkg_dir/suse/datarecovery.spec"
}

release_opensuse_changelog(){
    target_dir="$pkg_dir/suse"
    osc_date_string=$(LC_ALL=C date -u '+%a %b %d %H:%M:%S UTC %Y')
    osc_formatted_changelog=$(sed -n "/^## \[v$version\]/,/^## \[/p" "$base_dir/CHANGELOG.md" |
        sed '$d' |
        sed -n 's/^[[:space:]]*-[[:space:]]*/  * /p')

    osc_changelog="-------------------------------------------------------------------
$osc_date_string - $user <$email>

- Update to $version
$osc_formatted_changelog
"

    {
        printf '%s\n' "$osc_changelog"
        cat "$target_dir/datarecovery.changes"
    } > "$target_dir/datarecovery.changes.tmp"

    mv "$target_dir/datarecovery.changes.tmp" "$target_dir/datarecovery.changes"
}

release_opensuse_commit(){
    target_suse_dir="$obs_dir/home:koxt2:openSUSE/datarecovery"
    find "$target_suse_dir" -mindepth 1 \
        -not -path "$target_suse_dir/.osc" -not -path "$target_suse_dir/.osc/*" \
        -not -path "$target_suse_dir/.git" -not -path "$target_suse_dir/.git/*" \
        -not -name .gitignore -not -name .gitattributes -delete
    for f in  suse/datarecovery.changes suse/datarecovery.spec suse/datarecovery-rpmlintrc; do
        cp "$f" "$target_suse_dir/$f"
    done
    cp "$base_dir/v$version.tar.gz" "$target_suse_dir"
    git -C "$obs_dir/home:koxt2:openSUSE/datarecovery" add -A
    git -C "$obs_dir/home:koxt2:openSUSE/datarecovery" commit -m "Update to $version"
    git -C "$obs_dir/home:koxt2:openSUSE/datarecovery" push
}

release_arch_version(){
    sed -i "s/^pkgver=.*/pkgver=$version/" "$pkg_dir/aur/PKGBUILD"
    sed -i -E \
        -e "s|^([[:space:]]*pkgver = ).*|\\1$version|" \
        -e "s|^([[:space:]]*source = )datarecovery-[^:]*::https://github.com/koxt2/DataRecovery/archive/refs/tags/v[^[:space:]]*|\\1datarecovery-$version.tar.gz::https://github.com/koxt2/DataRecovery/archive/refs/tags/v$version.tar.gz|" \
        "$pkg_dir/aur/.SRCINFO"
}

release_arch_commit(){
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

test_main(){
    test_meson_version "$version" "$base_dir" "$pkg_dir"
    test_app_changelog "$version" "$base_dir" "$pkg_dir"
    meta_info "$version" "$base_dir" "$pkg_dir"

    test_commit_tag "$version" "$base_dir" "$pkg_dir"

    test_create_source_tarball "$version" "$base_dir" "$pkg_dir"

    test_files "$version" "$obs_dir" "$pkg_dir"
    version "$version" "$obs_dir"
    changelog "$user" "$email" "$version" "$base_dir" "$obs_dir"

    commit_repos "$obs_dir"

    test_cleanup
}

release_main(){
    release_meson_version "$version" "$base_dir"
    release_app_changelog "$version" "$base_dir"
    meta_info "$version" "$base_dir"
    release_commit_tag "$version" "$base_dir"
    
    release_github_release "$version" "$base_dir"

    release_get_source "$version" "$base_dir"

    version "$version" "$pkg_dir"
    changelog "$user" "$email" "$version" "$base_dir" "$pkg_dir"
    
    commit_repos

    release_cleanup
}

if (( ${#mode[@]} != 1 )); then
    printf 'Uncomment exactly one mode (test or release), found %d\n' "${#mode[@]}" >&2
    exit 1
fi

case "$mode" in
    release|test) "${mode}_main" ;;
    *) printf 'mode must be "release" or "test", got: %s\n' "$mode" >&2; exit 1 ;;
esac
