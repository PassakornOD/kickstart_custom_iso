Create a custom RHEL/CentOS 7 kickstart boot image
===

Build Docker image
---
```
docker build -t create_ks_bootiso .
```

Remove unused docker images
---
```
docker images -a --filter=dangling=true -q | xargs -r docker rmi
```

Download th CD / DVD boot images
---

* [Download RHEL 8.10 boot](https://access.cdn.redhat.com/content/origin/files/sha256/6c/6ced368628750ff3ea8a2fc52a371ba368d3377b8307caafda69070849a9e4e7/rhel-8.10-x86_64-boot.iso?user=2e18a59e2d837436ee0e14b72f2269f3&


Create custom boot image
---

Example:
```
docker run --privileged -v $(pwd):/opt/work -t create_ks_bootiso \
    /bin/sh customiso \
    --isolinuxcfg isolinux.cfg \
    --grubcfg grub.cfg \
    --kickstart rhel8_10_ks.cfg \
    --output-bootiso rhel7.7_custom_install.iso \
    rhel-server-7.7-x86_64-dvd.iso
```

Remove all stoped dockers
---
```
docker ps --filter=status=created --filter=status=exited -q | xargs -r docker rm
```

Check validity of your Kickstart file
---

Example:
```
docker run -v $(pwd):/opt/work -t create_ks_bootiso \
    ksvalidator --version RHEL7 /opt/work/ks.cfg
```

Encrypting passwords for rootpw
---

Example:
```
docker run -i -t create_ks_bootiso rootpw --sha512
```
# ks_rhel8_custom_iso
