#!/bin/bash -xe
sudo pip install awscli

bn="$(git rev-parse --abbrev-ref HEAD)"
case "$bn" in
    master)
        # install pacman-build
        install -d /tmp/pacman
        curl -LO http://pkgs.merelinux.org/stable/pacman-latest-x86_64.pkg.tar.xz
        tar -C /tmp/pacman -xf pacman-latest-x86_64.pkg.tar.xz 2>/dev/null

        install -d ./var/lib/pacman
        sudo /tmp/pacman/bin/pacman -Sy --config /tmp/pacman/etc/pacman.conf \
            -r . --noconfirm pacman-build
        sudo sed -i '/bsdtar -xf .*dbfile/s@-C@--no-fflags -C@' bin/repo-add

        # Sync down existing files in the staging repo
        install -d pkgs/testing pkgs/staging
        aws s3 sync s3://pkgs.merelinux.org/staging/ pkgs/staging/

        # Grab the testing dbs
        curl -fsL http://pkgs.merelinux.org/testing/main.db.tar.gz \
            -o pkgs/testing/main.db.tar.gz
        curl -fsL http://pkgs.merelinux.org/testing/main.files.tar.gz \
            -o pkgs/testing/main.files.tar.gz

        # Copy over the staging files to testing
        find "pkgs/staging" -name "*.pkg*" | while read -r file ; do
            mv -v "$file" pkgs/testing
            ./bin/repo-add -R pkgs/testing/main.db.tar.gz "pkgs/testing/${file##*/}"
        done
        find pkgs/staging -name "*.src.tar.xz" -exec mv -v '{}' pkgs/testing/ \;

        aws s3 sync pkgs s3://pkgs.merelinux.org
        aws s3 rm --recursive s3://pkgs.merelinux.org/pkgs/staging/
        sleep 5
        ;;
    *)
        install -d pkgs/staging
        if [ -d "$(pwd)/.mere/pkgs" ] ; then
            find "$(pwd)/.mere/pkgs" -type f -exec mv -v '{}' pkgs/staging/ \;
            aws s3 sync pkgs s3://pkgs.merelinux.org
        fi
        ;;
esac
