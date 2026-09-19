# DataRecovery Release Workflow

## Meson Build

```
meson setup builddir
meson setup --reconfigure builddir
alias rebuild='meson compile -C builddir && sudo meson install -C builddir'
rebuild && datarecovery
sudo ninja -C builddir uninstall
```

---

## Versioning, Changelogs, and Commit and Tag

### 1. Update Version Numbers
Update the following files with the new version:
- `meson.build` (line 2: `version: 'v0.2.0'`)
- `packaging/obs/rpm/_service` (line 7: `versionformat`)
- `packaging/obs/deb/datarecovery.dsc` (line 5: `Version:`)
- `packaging/obs/deb/datarecovery.dsc` (line 11: `0 0 datarecovery_0.2.0.orig.tar.gz`) 
- `aur/PKGBUILD` (line 3: `pkgver=`)
- `copr/datarecovery.spec` (line 4: `Version:`)

### 2. Update Changelogs
- `CHANGELOG.md`: Add new version section with changes
- `debian/changelog`: Add new entry at the top
- `obs/deb/debian.changelog`: Add new entry at the top
- `obs/rpm/datarecovery.spec`: Add new entry in `%changelog` section
- `copr/datarecovery.spec`: Add new entry in `%changelog` section
- `data/com.github.koxt2.datarecovery.metainfo.xml`: Add new <release> entry

### 3. Commit and Tag
```bash
git rm --cached src/gtk/custom_signature_dialog.cmb src/gtk/smart_dialog.cmb
cd /home/richard/Projects/github/DataRecovery
git add .
git commit -m "Release v0.2.0"
git tag -a v0.2.0 -m "Release v0.2.0"
git push origin main --tags
```

### 4. Create GitHub Release
- Go to [GitHub Releases](https://github.com/koxt2/DataRecovery/releases)
- Click "Draft a new release"
- Choose tag: `v0.2.0`
- Copy changelog from `CHANGELOG.md`
- Publish release

## Create a tarball for OBS (Debian) and Launchpad
### 1. Create a tarball 
```bash
cd /home/richard/Projects/github
tar --transform 's,^DataRecovery,datarecovery-0.5.0,' --exclude='.git' --exclude='aur' --exclude='builddir' --exclude='packaging' --exclude='debian' --exclude='docs' --exclude='.gitignore' --exclude='*.pyc' --exclude='__pycache__' --exclude='*.cmb' --exclude='workflow.md' -czf DataRecovery/datarecovery_0.5.0.orig.tar.gz DataRecovery/
```

## Build Packages
### 1. AUR

#### On desktop (one-time)
```bash
# Generate SSH key for the container
ssh-keygen -t ed25519 -C "richard@opensusetumbleweed" -f ~/.ssh/arch-container

# Add SSH config so you can connect with just 'ssh arch-container'
cat >> ~/.ssh/config << 'EOF'
Host arch-container
  HostName 192.168.0.30
  User builder
  Port 2223
  IdentityFile ~/.ssh/arch-container
EOF
```

#### On server (one-time)
```bash
# Create the storage directory and authorize your openSUSE key
mkdir -p ~/storage/arch/.ssh
chmod 700 ~/storage/arch/.ssh
echo "$(cat)" > ~/storage/arch/.ssh/authorized_keys
# paste your ~/.ssh/arch-container.pub content, then Ctrl+D
chmod 600 ~/storage/arch/.ssh/authorized_keys

# Deploy the quadlet files and start the container
cp arch.container arch.network ~/.config/containers/systemd/
```

#### Inside container (one-time)
```bash
ssh -p 2223 builder@192.168.0.30
# or: ssh arch-container

# Git identity
git config --global user.name "koxt2"
git config --global user.email "koxt2@protonmail.com"

# Generate AUR SSH key
ssh-keygen -t ed25519 -C "aur" -f ~/.ssh/aur_id_ed25519
# → copy contents of ~/.ssh/aur_id_ed25519.pub
# → paste into https://aur.archlinux.org/account/ → SSH Public Key → Save

# Configure SSH for AUR
cat >> ~/.ssh/config << 'EOF'
Host aur.archlinux.org
  IdentityFile ~/.ssh/aur_id_ed25519
  User aur
EOF
chmod 600 ~/.ssh/config

# Clone AUR package repo and DataRecovery source
git clone ssh://aur@aur.archlinux.org/datarecovery.git
git clone https://github.com/koxt2/DataRecovery.git
```

#### Release workflow from inside container
```bash
git -C ~/DataRecovery pull
cp ~/DataRecovery/packaging/aur/PKGBUILD ~/datarecovery/
cd ~/datarecovery
makepkg --printsrcinfo > .SRCINFO
git add PKGBUILD .SRCINFO
git commit -m "Update to v0.5.0"
git push
```

### 2. Copr
* now uses webhooks to rebuild automatically
- Copr automatically rebuilds from GitHub
- Web: https://copr.fedorainfracloud.org/coprs/koxt2/datarecovery/
- Click package → "Rebuild" button
- Or: Edit package and trigger new build from tag v0.2.0

### 3. Launchpad

#### Container Setup (First Time)
Build the image and create the named container on the server:
```bash
# On the server — from the DataRecovery repo root
podman build -t datarecovery-ppa-image packaging/launchpad/

# Create the named container, mounting the repo and your GPG home
podman create -it --name datarecovery-ppa \
    -v /path/to/DataRecovery:/work/DataRecovery \
    -v ~/.gnupg:/root/.gnupg \
    datarecovery-ppa-image
```

Import your GPG signing key (if your key isn't already in `~/.gnupg` on the server):
```bash
# Export from your desktop
gpg --export-secret-keys --armor koxt2@protonmail.com > datarecovery-ppa.asc

# Copy to server (adjust address)
scp datarecovery-ppa.asc user@server:~/

# On the server — import the key
gpg --import ~/datarecovery-ppa.asc
rm ~/datarecovery-ppa.asc          # remove the private key file after import
```

The `~/.gnupg` bind-mount means the container always sees your server's keyring — no re-import needed after rebuilding the image.

#### Build and Upload
```bash
podman start -ai datarecovery-ppa

export DEBEMAIL="koxt2@protonmail.com"  
export DEBFULLNAME="koxt2"  
export GPG_TTY=$(tty)  

cd /work/DataRecovery

RELEASES="noble questing"  

for RELEASE in $RELEASES; do
    echo "========================================="
    echo "Building for $RELEASE..."
    echo "========================================="
    
    mkdir -p /work/DataRecovery/launchpad/ppa-$RELEASE
    
    cp /work/DataRecovery/datarecovery_0.4.1.orig.tar.gz /work/DataRecovery/launchpad/ppa-$RELEASE/
    
    cd /work/DataRecovery/launchpad/ppa-$RELEASE
    tar -xzf datarecovery_0.4.1.orig.tar.gz
    
    cp -r /work/DataRecovery/DataRecovery/debian datarecovery-0.4.1/
    cd datarecovery-0.4.1
    
    # Update changelog for this specific release (only in extracted dir)
    dch -b --newversion 0.4.1-1~${RELEASE}1 -D $RELEASE "Build for $RELEASE" </dev/null
    
    debuild -S -sa
    
    cd /work/DataRecovery/launchpad/ppa-$RELEASE
    dput --force ppa:koxt2/datarecovery datarecovery_0.4.1-1~${RELEASE}1_source.changes
    
    echo "✓ Done with $RELEASE"
    echo ""
done

# Cleanup
echo "All releases uploaded successfully!"
exit
```

### 4. Update openSUSE security:forensics

1. **Sync upstream to your fork:**
    ```bash
    git fetch upstream
    git rebase upstream/master
    git push origin master --force
    ```

2. **Update the spec file version as needed.**

3. **Update the `.changes` file:**
    Example entry:
    ```
    -------------------------------------------------------------------
    Sun Nov 30 23:37:00 UTC 2025 - koxt2 <koxt2@protonmail.com>

    - Update to release 0.2.0
      * File type selection dialog
      * Bug fixes
    ```
4. Add the tarball

5. **Commit and push changes:**
    ```bash
    git add datarecovery.changes datarecovery.spec
    git commit -m "Update to vx.x.x"
    git push
    ```

6. **Open a pull request.**

### To edit a release
```bash
git add data/com.github.koxt2.datarecovery.metainfo.xml
git commit --amend --no-edit
git tag -d v0.4.1 && git tag v0.4.1

git push origin main --force
git push origin v0.4.1 --force
```
