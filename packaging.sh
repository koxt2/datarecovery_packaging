#!/bin/bash
set -euo pipefail

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
version="0.7.0"

base_dir="/home/richard/Projects/github/DataRecovery"
obs_dir="/home/richard/Projects/obs"
pkg_dir="/home/richard/Projects/github/datarecovery_packaging"
proj_dir="/home/richard/Projects"

files(){
    for target in "${version_targets[@]}"; do
        "${mode}_${target}_files"
    done
}

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

#======================================================================
# TEST
#======================================================================

test_meson_version(){
    cd "$base_dir"
    sed -i "2s/version: 'v[0-9.]*'/version: 'v$version'/" meson.build
    cd "$pkg_dir"
}

test_app_changelog(){
    cd "$base_dir"
    date_string=$(date -u '+%Y-%m-%d')
    sed -i "0,/^## \[[Uu]nreleased\]/s//## [v$version] - $date_string/" "$base_dir/CHANGELOG.md"
    cd "$pkg_dir"
}

test_meta_info() {
    local metainfo_file="$base_dir/data/com.github.koxt2.datarecovery.metainfo.xml"
    local release_version="${version#v}"
    local release_heading="## [v$version]"
    local release_date
    local release_header
    local entry_file
    local metainfo_tmp
    local item
    local -a changelog_items

    if grep -Fq "<release version=\"$release_version\"" "$metainfo_file"; then
        return 0
    fi

    release_header=$(awk -v heading="$release_heading" 'index($0, heading) == 1 { print; exit }' "$base_dir/CHANGELOG.md")
    if [[ -z "$release_header" ]]; then
        printf 'No changelog entry found for %s\n' "$release_heading" >&2
        return 1
    fi
    release_date="${release_header##* - }"

    mapfile -t changelog_items < <(
        awk -v heading="$release_heading" '
            index($0, heading) == 1 { in_release=1; next }
            in_release && /^## \[/ { exit }
            in_release && /^- / {
                items[++count] = substr($0, 3)
                next
            }
            in_release && /^[[:space:]]+[^[:space:]]/ && count {
                sub(/^[[:space:]]+/, "")
                items[count] = items[count] " " $0
            }
            END {
                for (i=1; i<=count; i++) print items[i]
            }
        ' "$base_dir/CHANGELOG.md"
    )
    if (( ${#changelog_items[@]} == 0 )); then
        printf 'No changelog items found for %s\n' "$release_heading" >&2
        return 1
    fi

    entry_file=$(mktemp)
    metainfo_tmp=$(mktemp "$metainfo_file.XXXXXX")
    {
        printf '    <release version="%s" date="%s">\n' "$release_version" "$release_date"
        printf '      <description>\n'
        printf '        <p>Release v%s</p>\n' "$release_version"
        printf '        <ul>\n'
        for item in "${changelog_items[@]}"; do
            item=$(printf '%s' "$item" | sed \
                -e 's/&/\&amp;/g' \
                -e 's/</\&lt;/g' \
                -e 's/>/\&gt;/g')
            printf '          <li>%s</li>\n' "$item"
        done
        printf '        </ul>\n'
        printf '      </description>\n'
        printf '    </release>\n'
    } > "$entry_file"

    if ! awk -v entry_file="$entry_file" '
        !inserted && /<releases>/ {
            print
            while ((getline line < entry_file) > 0) print line
            close(entry_file)
            inserted=1
            next
        }
        { print }
        END { if (!inserted) exit 1 }
    ' "$metainfo_file" > "$metainfo_tmp"; then
        rm -f "$entry_file" "$metainfo_tmp"
        printf 'Could not find a <releases> element in %s\n' "$metainfo_file" >&2
        return 1
    fi

    mv "$metainfo_tmp" "$metainfo_file"
    rm -f "$entry_file"
}

test_commit_tag(){
    cd "$base_dir"
    git add .
    git commit -m "Release v$version"
    git tag -a v$version -m "Release v$version"
    cd "$pkg_dir"
}

test_create_source_tarball(){
    cd "$base_dir"
    git archive \
        --format=tar.gz \
        --prefix="DataRecovery-$version/" \
        -o "$pkg_dir/v$version.tar.gz" \
        v$version
}

test_debian_files(){
    cd "$pkg_dir"
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
    cd "$obs_dir/home:koxt2:debian/datarecovery_test"
    osc addremove
    osc commit
}

test_ubuntu_files(){
    cd "$pkg_dir"
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
    cd "$obs_dir/home:koxt2:ubuntu/datarecovery_test"
    osc addremove
    osc commit
}

test_fedora_files(){
    cd "$pkg_dir"
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
    cd "$obs_dir/home:koxt2:fedora/datarecovery_test"
    osc addremove
    osc commit
}

test_opensuse_files(){
    cd "$pkg_dir"
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
    cd "$obs_dir/home:koxt2:openSUSE/datarecovery_test"
    osc addremove
    osc commit
}

test_arch_files(){
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

test_arch_version(){
    sed -i "s/^pkgver=.*/pkgver=$version/" "$obs_dir/home:koxt2:arch/datarecovery_test/PKGBUILD"
    
}

test_arch_commit(){
    cd "$obs_dir/home:koxt2:arch/datarecovery_test"
    osc addremove
    osc commit
}

test_cleanup(){
    cd "$pkg_dir"
    rm ./*.tar.gz
    cd "$base_dir"
    git tag -d "v$version"
    git reset origin/main --hard
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
    cd $base_dir
    git add .
    git commit -m "Release v$version"
    git tag -a v$version -m "Release v$version"
    git push origin main --tags
}

release_github_release(){
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

release_get_source(){
    cd "$base_dir"
    wget https://github.com/koxt2/DataRecovery/archive/refs/tags/v$version.tar.gz
    archive="v$version.tar.gz"
}   

release_cleanup(){
    cd "$pkg_dir"
    rm ./*.tar.gz
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
    cd "$pkg_dir"
    target_debian_dir="$obs_dir/home:koxt2:debian/datarecovery"
    find "$target_debian_dir" -mindepth 1 -not -path "$target_debian_dir/.osc" -not -path "$target_debian_dir/.osc/*" -delete
    for f in changelog compat control copyright rules dsc; do
        cp "debian/debian.$f" "$target_debian_dir/debian.$f"
    done
    cp "$base_dir/v$version.tar.gz" "$target_debian_dir/v$version.orig.tar.gz"
    cd "$obs_dir/home:koxt2:debian/datarecovery"
    osc addremove
    osc commit
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
    cd "$pkg_dir"
    target_ubuntu_dir="$obs_dir/home:koxt2:ubuntu/datarecovery"
    find "$target_ubuntu_dir" -mindepth 1 -not -path "$target_ubuntu_dir/.osc" -not -path "$target_ubuntu_dir/.osc/*" -delete
    for f in changelog compat control copyright rules dsc; do
        cp "debian/debian.$f" "$target_ubuntu_dir/debian.$f"
    done
    cp "$base_dir/v$version.tar.gz" "$target_ubuntu_dir/v$version.orig.tar.gz"
    cd "$obs_dir/home:koxt2:ubuntu/datarecovery"
    osc addremove
    osc commit
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
    cd "$pkg_dir/suse"
    target_suse_dir="$obs_dir/home:koxt2:openSUSE/datarecovery"
    find "$target_suse_dir" -mindepth 1 \
        -not -path "$target_suse_dir/.osc" -not -path "$target_suse_dir/.osc/*" \
        -not -path "$target_suse_dir/.git" -not -path "$target_suse_dir/.git/*" \
        -not -name .gitignore -not -name .gitattributes -delete
    for f in datarecovery.changes datarecovery.spec datarecovery-rpmlintrc; do
        cp "$f" "$target_suse_dir/$f"
    done
    cp "$base_dir/v$version.tar.gz" "$target_suse_dir"
    cd "$obs_dir/home:koxt2:openSUSE/datarecovery"
    git add -A
    git commit -m "Update to $version"
    git push
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
    test_meta_info "$version" "$base_dir" "$pkg_dir"

    test_commit_tag "$version" "$base_dir" "$pkg_dir"

    test_create_source_tarball "$version" "$base_dir" "$pkg_dir"

    files "$version" "$obs_dir" "$pkg_dir"
    version "$version" "$obs_dir"
    changelog "$user" "$email" "$version" "$base_dir" "$obs_dir"

    commit_repos "$obs_dir"

    test_cleanup
}

release_main(){
    release_meson_version "$version" "$base_dir"
    release_app_changelog "$version" "$base_dir"
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
