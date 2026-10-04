fedora_version(){
    sed -i "4s/^Version:        .*/Version:        $version/" "$pkg_dir/copr/datarecovery.spec"
}

fedora_changelog(){
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

fedora_commit() {
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