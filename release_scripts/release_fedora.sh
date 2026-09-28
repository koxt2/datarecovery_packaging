fedora_version(){
    sed -i "4s/^Version:        .*/Version:        $version/" "$pkg_dir/datarecovery.spec"
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