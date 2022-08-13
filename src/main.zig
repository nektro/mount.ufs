const std = @import("std");
const string = [*:0]const u8;
const mstring = [*:0]u8;
const stringarray = [*:null]const ?string;
const linux = std.os.linux;
const mode_t = std.os.linux.mode_t;
const size_t = usize;
const ssize_t = isize;
const off_t = std.os.linux.off_t;
const dev_t = std.os.linux.dev_t;
const uid_t = std.os.linux.uid_t;
const gid_t = std.os.linux.gid_t;
const timespec = std.os.linux.timespec;

const c = @cImport({
    @cDefine("FUSE_USE_VERSION", "31");
    @cInclude("fuse3/fuse.h");
});

pub export fn main(argc: c_int, argv: stringarray) c_int {
    _ = umask(0);
    return fuse_main(argc, argv, &xmp_oper, null);
}

// #include <sys/stat.h>
// mode_t umask(mode_t mask);
extern fn umask(mask: mode_t) mode_t;

// pub const fuse_main = @compileError("unable to translate C expr: unexpected token '*'"); // /nix/store/6hb0kxxm0h76p0dzhsbhdighrv6sxm17-fuse-3.10.5/include/fuse3/fuse.h:878:9
// #define fuse_main(argc, argv, op, private_data)    fuse_main_real(argc, argv, op, sizeof(*(op)), private_data)
// int fuse_main_real(int argc, char *argv[], const struct fuse_operations *op, size_t op_size, void *private_data);
export fn fuse_main(argc: c_int, argv: stringarray, op: *const fuse_operations, private_data: ?*anyopaque) c_int {
    return fuse_main_real(argc, @ptrCast([*c]const [*c]const u8, argv), op, @sizeOf(c.fuse_operations), private_data);
}
extern fn fuse_main_real(argc: c_int, argv: stringarray, op: *const fuse_operations, op_size: size_t, private_data: ?*anyopaque) c_int;

export const xmp_oper: fuse_operations = .{
    .init = xmp_init,
    .getattr = xmp_getattr,
    .access = xmp_access,
    .readlink = xmp_readlink,
    .readdir = xmp_readdir,
    .mknod = xmp_mknod,
    .mkdir = xmp_mkdir,
    .symlink = xmp_symlink,
    .unlink = xmp_unlink,
    .rmdir = xmp_rmdir,
    .rename = xmp_rename,
    .link = xmp_link,
    .chmod = xmp_chmod,
    .chown = xmp_chown,
    .truncate = xmp_truncate,
    .open = xmp_open,
    .create = xmp_create,
    .read = xmp_read,
    .write = xmp_write,
    .statfs = xmp_statfs,
    .release = xmp_release,
    .fsync = xmp_fsync,
    .lseek = xmp_lseek,

    .utimens = xmp_utimens,

    .fallocate = xmp_fallocate,

    .setxattr = xmp_setxattr,
    .getxattr = xmp_getxattr,
    .listxattr = xmp_listxattr,
    .removexattr = xmp_removexattr,

    .copy_file_range = xmp_copy_file_range,
};

const fuse_operations = extern struct {
    init: fn (*c.fuse_conn_info, *c.fuse_config) callconv(.C) ?*anyopaque,
    getattr: fn (string, *std.os.linux.Stat, *c.fuse_file_info) callconv(.C) c_int,
    access: fn (string, c_int) callconv(.C) c_int,
    readlink: fn (string, mstring, size_t) callconv(.C) c_int,
    readdir: fn (string, *anyopaque, c.fuse_fill_dir_t, off_t, *c.fuse_file_info, c.fuse_readdir_flags) callconv(.C) c_int,
    mknod: fn (string, mode_t, dev_t) callconv(.C) c_int,
    mkdir: fn (string, mode_t) callconv(.C) c_int,
    unlink: fn (string) callconv(.C) c_int,
    rmdir: fn (string) callconv(.C) c_int,
    symlink: fn (string, string) callconv(.C) c_int,
    rename: fn (string, string, c_uint) callconv(.C) c_int,
    link: fn (string, string) callconv(.C) c_int,
    chmod: fn (string, mode_t, *c.fuse_file_info) callconv(.C) c_int,
    chown: fn (string, uid_t, gid_t, *c.fuse_file_info) callconv(.C) c_int,
    truncate: fn (string, off_t, *c.fuse_file_info) callconv(.C) c_int,
    create: fn (string, mode_t, *c.fuse_file_info) callconv(.C) c_int,
    open: fn (string, *c.fuse_file_info) callconv(.C) c_int,
    read: fn (string, mstring, size_t, off_t, *c.fuse_file_info) callconv(.C) c_int,
    write: fn (string, string, size_t, off_t, *c.fuse_file_info) callconv(.C) c_int,
    statfs: fn (string, *Statvfs) callconv(.C) c_int,
    release: fn (string, *c.fuse_file_info) callconv(.C) c_int,
    fsync: fn (string, c_int, *c.fuse_file_info) callconv(.C) c_int,
    lseek: fn (string, off_t, c_int, *c.fuse_file_info) callconv(.C) off_t,
    utimens: fn (string, *const [2]timespec, *c.fuse_file_info) callconv(.C) c_int,
    fallocate: fn (string) callconv(.C) c_int,
    setxattr: fn (string, string, string, size_t, c_int) callconv(.C) c_int,
    getxattr: fn (string, string, mstring, size_t) callconv(.C) c_int,
    listxattr: fn (string, mstring, size_t) callconv(.C) c_int,
    removexattr: fn (string, string) callconv(.C) c_int,
    copy_file_range: fn (string, *c.fuse_file_info, off_t, string, *c.fuse_file_info, off_t, size_t, c_int) callconv(.C) ssize_t,
};

// static void *xmp_init(struct fuse_conn_info *conn, struct fuse_config *cfg)
export fn xmp_init(conn: *c.fuse_conn_info, cfg: *c.fuse_config) ?*anyopaque {
    _ = conn;
    cfg.use_ino = 1;

    // Pick up changes from lower filesystem right away. This is also necessary for better hardlink
    // support. When the kernel calls the unlink() handler, it does not know the inode of the
    // to-be-removed entry and can therefore not invalidate the cache of the associated inode -
    // resulting in an incorrect st_nlink value being reported for any remaining hardlinks to this inode.
    cfg.entry_timeout = 0;
    cfg.attr_timeout = 0;
    cfg.negative_timeout = 0;
    return null;
}

// static int xmp_getattr(const char *path, struct stat *stbuf, struct fuse_file_info *fi)
export fn xmp_getattr(path: string, stbuf: *linux.Stat, fi: *c.fuse_file_info) c_int {
    _ = fi;

    if (lstat(path, stbuf) == -1) {
        return -errno;
    }
    return 0;
}

// static int xmp_access(const char *path, int mask)
extern fn xmp_access(path: string, mask: c_int) c_int;

// static int xmp_readlink(const char *path, char *buf, size_t size)
extern fn xmp_readlink(path: string, buf: mstring, size: size_t) c_int;

// static int xmp_readdir(const char *path, void *buf, fuse_fill_dir_t filler, off_t offset, struct fuse_file_info *fi, enum fuse_readdir_flags flags)
extern fn xmp_readdir(path: string, buf: *anyopaque, filler: c.fuse_fill_dir_t, offset: off_t, fi: *c.fuse_file_info, flags: c.fuse_readdir_flags) c_int;

// static int xmp_mknod(const char *path, mode_t mode, dev_t rdev)
extern fn xmp_mknod(path: string, mode: mode_t, rdev: dev_t) c_int;

// static int xmp_mkdir(const char *path, mode_t mode)
extern fn xmp_mkdir(path: string, mode: mode_t) c_int;

// static int xmp_unlink(const char *path)
extern fn xmp_unlink(path: string) c_int;

// static int xmp_rmdir(const char *path)
extern fn xmp_rmdir(path: string) c_int;

// static int xmp_symlink(const char *from, const char *to)
extern fn xmp_symlink(from: string, to: string) c_int;

// static int xmp_rename(const char *from, const char *to, unsigned int flags)
extern fn xmp_rename(from: string, to: string, flags: c_uint) c_int;

// static int xmp_link(const char *from, const char *to)
extern fn xmp_link(from: string, to: string) c_int;

// static int xmp_chmod(const char *path, mode_t mode, struct fuse_file_info *fi)
extern fn xmp_chmod(path: string, mode: mode_t, fi: *c.fuse_file_info) c_int;

// static int xmp_chown(const char *path, uid_t uid, gid_t gid, struct fuse_file_info *fi)
extern fn xmp_chown(path: string, uid: uid_t, gid: gid_t, fi: *c.fuse_file_info) c_int;

// static int xmp_truncate(const char *path, off_t size, struct fuse_file_info *fi)
extern fn xmp_truncate(path: string, size: off_t, fi: *c.fuse_file_info) c_int;

// static int xmp_create(const char *path, mode_t mode, struct fuse_file_info *fi)
extern fn xmp_create(path: string, mode: mode_t, fi: *c.fuse_file_info) c_int;

// static int xmp_open(const char *path, struct fuse_file_info *fi)
extern fn xmp_open(path: string, fi: *c.fuse_file_info) c_int;

// static int xmp_read(const char *path, char *buf, size_t size, off_t offset, struct fuse_file_info *fi)
extern fn xmp_read(path: string, buf: mstring, size: size_t, offset: off_t, fi: *c.fuse_file_info) c_int;

// static int xmp_write(const char *path, const char *buf, size_t size, off_t offset, struct fuse_file_info *fi)
extern fn xmp_write(path: string, buf: string, size: size_t, offset: off_t, fi: *c.fuse_file_info) c_int;

// static int xmp_statfs(const char *path, struct statvfs *stbuf)
extern fn xmp_statfs(path: string, stbuf: *Statvfs) c_int;

// static int xmp_release(const char *path, struct fuse_file_info *fi)
extern fn xmp_release(path: string, fi: *c.fuse_file_info) c_int;

// static int xmp_fsync(const char *path, int isdatasync, struct fuse_file_info *fi)
extern fn xmp_fsync(path: string, isdatasync: c_int, fi: *c.fuse_file_info) c_int;

// static off_t xmp_lseek(const char *path, off_t off, int whence, struct fuse_file_info *fi)
extern fn xmp_lseek(path: string, off: off_t, whence: c_int, fi: *c.fuse_file_info) off_t;

//ifdef HAVE_UTIMENSAT
// static int xmp_utimens(const char *path, const struct timespec ts[2], struct fuse_file_info *fi)
extern fn xmp_utimens(path: string, ts: *const [2]timespec, fi: *c.fuse_file_info) c_int;

//ifdef HAVE_POSIX_FALLOCATE
// static int xmp_fallocate(const char *path, int mode, off_t offset, off_t length, struct fuse_file_info *fi)
extern fn xmp_fallocate(path: string) c_int;

//ifdef HAVE_SETXATTR
// static int xmp_setxattr(const char *path, const char *name, const char *value, size_t size, int flags)
// static int xmp_getxattr(const char *path, const char *name, char *value, size_t size)
// static int xmp_listxattr(const char *path, char *list, size_t size)
// static int xmp_removexattr(const char *path, const char *name)
extern fn xmp_setxattr(path: string, name: string, value: string, size: size_t, flags: c_int) c_int;
extern fn xmp_getxattr(path: string, name: string, value: mstring, size: size_t) c_int;
extern fn xmp_listxattr(path: string, list: mstring, size: size_t) c_int;
extern fn xmp_removexattr(path: string, name: string) c_int;

//ifdef HAVE_COPY_FILE_RANGE
// static ssize_t xmp_copy_file_range(const char *path_in, struct fuse_file_info *fi_in, off_t offset_in, const char *path_out, struct fuse_file_info *fi_out, off_t offset_out, size_t len, int flags)
extern fn xmp_copy_file_range(path_in: string, fi_in: *c.fuse_file_info, offset_in: off_t, path_out: string, fi_out: *c.fuse_file_info, offset_out: off_t, len: size_t, flags: c_int) ssize_t;

//
// missing from stdlib

const Statvfs = extern struct {
    f_bsize: c_ulong,
    f_frsize: c_ulong,
    f_blocks: fsblkcnt_t,
    f_bfree: fsblkcnt_t,
    f_bavail: fsblkcnt_t,
    f_files: fsfilcnt_t,
    f_ffree: fsfilcnt_t,
    f_favail: fsfilcnt_t,
    f_fsid: c_ulong,
    f_flag: c_ulong,
    f_namemax: c_ulong,
};
const fsblkcnt_t = c_ulonglong;
const fsfilcnt_t = c_ulonglong;
comptime {
    std.debug.assert(@sizeOf(usize) == @sizeOf(u64)); // only 64bit host is currently supported
    // on 32bit fsblkcnt_t/fsfilcnt_t are c_ulong
}
extern threadlocal var errno: c_int;

//
// wrong in stdlib
extern fn lstat(pathname: [*:0]const u8, statbuf: *linux.Stat) c_int;
