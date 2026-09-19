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

## Release

### 1. Update Version Numbers
- `meson.build` (line 2: `version: 'v0.2.0'`)
- `packaging/copr/datarecovery.spec` (line 4: `Version:`)
- `packaging/obs/suse/datarecovery.spec` (line 20: `Version:`)
- `packaging/obs/deb/datarecovery.dsc` (line 5: `Version:`, line 11: `0 0 v0.2.0.orig.tar.gz`)

### 2. Update Changelogs
- `CHANGELOG.md`
- `data/com.github.koxt2.datarecovery.metainfo.xml`
- `packaging/copr/datarecovery.spec`
- `packaging/obs/suse/datarecovery.changes`
- `debian/changelog`
- `packaging/obs/deb/debian.changelog`

### 3. Commit and Tag
```bash
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

## Test Build
### 1. Create a tarball
```bash

cd /home/richard/Projects/github/DataRecovery
git archive --format=tar.gz --prefix=DataRecovery-0.6.1/ v0.6.1 -o ../DataRecovery/v0.6.1.tar.gz

cd /home/richard/Projects/github
tar --transform 's,^DataRecovery,DataRecovery-0.6.1,' --exclude='builddir' --exclude='docs' --exclude='.gitignore' --exclude='*.cmb' --exclude='workflow.md' --exclude='new_workflow.md' --exclude='.git' -czf DataRecovery/v0.6.1.tar.gz DataRecovery/
```

### 2. openSUSE
Get the repo if not already ```osc checkout home:koxt2/datarecovery```
``` bash
cd /home/richard/Projects/obs/home:koxt2:openSUSE/datarecovery/

rm <previous_build>

cp /home/richard/Projects/github/DataRecovery/v0.6.0.tar.gz /home/richard/Projects/github/DataRecovery/packaging/obs/suse/

cp -R /home/richard/Projects/github/DataRecovery/packaging/obs/suse/. /home/richard/Projects/obs/home:koxt2:openSUSE/datarecovery/

osc build
```

### Debian
Get the repo if not already ```osc checkout home:koxt2:datarecovery:deb```
```bash
cd /home/richard/Projects/obs/home:koxt2:datarecovery:deb/datarecovery/

rm <previous_tar>

cp /home/richard/Projects/github/DataRecovery/v0.6.0.tar.gz /home/richard/Projects/github/DataRecovery/packaging/obs/deb/v0.6.0.orig.tar.gz

cp -R /home/richard/Projects/github/DataRecovery/packaging/obs/deb/. ./

osc build
```

### Fedora
Get the repo if not already ```osc checkout home:koxt2:datarecovery:fed```
```bash
cd /home/richard/Projects/obs/home:koxt2:datarecovery:fed/datarecovery/

cp -R /home/richard/Projects/github/DataRecovery/packaging/copr/. ./

osc build --no-verify
```



## Publish
### 1. openSUSE

Push to gitea
Set the remote if not already ```git remote add datarecovery gitea@src.opensuse.org:koxt2/datarecovery```
``` bash
git add .

git commit

git push datarecovery
```

### 2. Fedora
``` bash
cd /home/richard/Projects/obs/home:koxt2:datarecovery:fed/datarecovery/

osc addremove

osc commit

Copr
 Now uses webhooks to rebuild automatically
 - Copr automatically rebuilds from GitHub (disabled, it rebuilt every commit)
 - Web: https://copr.fedorainfracloud.org/coprs/koxt2/datarecovery/
 - Click package → "Rebuild" button
 - Or: Edit package and trigger new build from tag v0.2.0
 - 

### 2. Debian (obs)

```bash

osc addremove

osc commit
```

- Just ```:q!``` the commit messgage and choose ```continue```


```







