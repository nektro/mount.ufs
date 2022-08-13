# mount.ufs
![loc](https://sloc.xyz/github/nektro/mount.ufs)
[![license](https://img.shields.io/github/license/nektro/mount.ufs.svg)](https://github.com/nektro/mount.ufs/blob/master/LICENSE)

A FUSE filesystem client for mounting UFS partitions, mainly used by FreeBSD and its derivatives.

Entirely WIP and experimental until further notice. Any research notes or PRs welcome through any of my contact avenues.

## Current Status
- [x] Get libfuse passthrough example building with Zig
    - [x] `xmp_init`
    - [x] `xmp_getattr`
    - [x] `xmp_access`
    - [x] `xmp_readlink`
    - [ ] `xmp_readdir`
    - [ ] `xmp_mknod`
    - [ ] `xmp_mkdir`
    - [ ] `xmp_unlink`
    - [ ] `xmp_rmdir`
    - [ ] `xmp_symlink`
    - [ ] `xmp_rename`
    - [ ] `xmp_link`
    - [ ] `xmp_chmod`
    - [ ] `xmp_chown`
    - [ ] `xmp_truncate`
    - [ ] `xmp_create`
    - [ ] `xmp_open`
    - [ ] `xmp_read`
    - [ ] `xmp_write`
    - [ ] `xmp_statfs`
    - [ ] `xmp_release`
    - [ ] `xmp_fsync`
    - [ ] `xmp_lseek`
    - [ ] `xmp_utimens`
    - [ ] `xmp_fallocate`
    - [ ] `xmp_setxattr`
    - [ ] `xmp_getxattr`
    - [ ] `xmp_listxattr`
    - [ ] `xmp_removexattr`
    - [ ] `xmp_copy_file_range`
- [ ] Port passthrough code to be pure Zig
- [ ] Read access UFS
- [ ] Write access UFS

## License
GPL-2.0
