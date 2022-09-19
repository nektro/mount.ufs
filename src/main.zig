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
const ino_t = std.os.linux.ino_t;

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
    return fuse_main_real(argc, argv, op, @sizeOf(c.fuse_operations), private_data);
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
};

const fuse_operations = extern struct {
    init: *const fn (*c.fuse_conn_info, *c.fuse_config) callconv(.C) ?*anyopaque,
    getattr: *const fn (string, *std.os.linux.Stat, *c.fuse_file_info) callconv(.C) c_int,
    access: *const fn (string, c_int) callconv(.C) c_int,
    readlink: *const fn (string, mstring, size_t) callconv(.C) c_int,
    readdir: *const fn (string, *anyopaque, c.fuse_fill_dir_t, off_t, *c.fuse_file_info, c.fuse_readdir_flags) callconv(.C) c_int,
    mknod: *const fn (string, mode_t, dev_t) callconv(.C) c_int,
    mkdir: *const fn (string, mode_t) callconv(.C) c_int,
    unlink: *const fn (string) callconv(.C) c_int,
    rmdir: *const fn (string) callconv(.C) c_int,
    symlink: *const fn (string, string) callconv(.C) c_int,
    rename: *const fn (string, string, c_uint) callconv(.C) c_int,
    link: *const fn (string, string) callconv(.C) c_int,
    chmod: *const fn (string, mode_t, *c.fuse_file_info) callconv(.C) c_int,
    chown: *const fn (string, uid_t, gid_t, *c.fuse_file_info) callconv(.C) c_int,
    truncate: *const fn (string, off_t, *fuse_file_info) callconv(.C) c_int,
    create: *const fn (string, mode_t, *fuse_file_info) callconv(.C) c_int,
    open: *const fn (string, *fuse_file_info) callconv(.C) c_int,
    read: *const fn (string, mstring, size_t, off_t, ?*fuse_file_info) callconv(.C) c_int,
    write: *const fn (string, string, size_t, off_t, ?*fuse_file_info) callconv(.C) c_int,
    statfs: *const fn (string, *extrn.Statvfs) callconv(.C) c_int,
    release: *const fn (string, *fuse_file_info) callconv(.C) c_int,
    fsync: *const fn (string, c_int, *c.fuse_file_info) callconv(.C) c_int,
    lseek: *const fn (string, off_t, c_int, *c.fuse_file_info) callconv(.C) off_t,
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

    if (extrn.lstat(path, stbuf) == -1) {
        return -errno;
    }
    return 0;
}

// static int xmp_access(const char *path, int mask)
export fn xmp_access(path: string, mask: c_int) c_int {
    if (extrn.access(path, mask) == -1) {
        return -errno;
    }
    return 0;
}

// static int xmp_readlink(const char *path, char *buf, size_t size)
export fn xmp_readlink(path: string, buf: mstring, size: size_t) c_int {
    switch (extrn.readlink(path, buf, size - 1)) {
        -1 => return -errno,
        else => |res| buf[@intCast(usize, res)] = 0,
    }
    return 0;
}

// static int xmp_readdir(const char *path, void *buf, fuse_fill_dir_t filler, off_t offset, struct fuse_file_info *fi, enum fuse_readdir_flags flags)
export fn xmp_readdir(path: string, buf: *anyopaque, filler: c.fuse_fill_dir_t, offset: off_t, fi: *c.fuse_file_info, flags: c.fuse_readdir_flags) c_int {
    _ = offset;
    _ = fi;
    _ = flags;

    const dp = extrn.opendir(path) orelse return -errno;
    defer _ = extrn.closedir(dp);

    while (extrn.readdir(dp)) |de| {
        var st = std.mem.zeroes(c.struct_stat);
        st.st_ino = de.d_ino;
        st.st_mode = @as(c_uint, de.d_type) << 12;
        if (filler.?(buf, de.d_name, &st, 0, 0) > 0) break;
    }
    return 0;
}

// static int xmp_mknod(const char *path, mode_t mode, dev_t rdev)
export fn xmp_mknod(path: string, mode: mode_t, rdev: dev_t) c_int {
    if (mknod_wrapper(linux.AT.FDCWD, path, null, mode, rdev) == -1) return -errno;
    return 0;
}
// static int mknod_wrapper(int dirfd, const char *path, const char *link, int mode, dev_t rdev)
export fn mknod_wrapper(dirfd: c_int, path: string, link: ?string, mode: mode_t, rdev: dev_t) c_int {
    if (linux.S.ISREG(mode)) {
        const O = linux.O;
        const res = extrn.openat(dirfd, path, O.CREAT | O.EXCL | O.WRONLY, mode);
        if (res > 0) return extrn.close(res);
        return res;
    }
    if (linux.S.ISDIR(mode)) {
        return extrn.mkdirat(dirfd, path, mode);
    }
    if (linux.S.ISLNK(mode)) {
        return extrn.symlinkat(link, dirfd, path);
    }
    if (linux.S.ISFIFO(mode)) {
        return extrn.mkfifoat(dirfd, path, mode);
    }
    return extrn.mknodat(dirfd, path, mode, rdev);
}

// static int xmp_mkdir(const char *path, mode_t mode)
export fn xmp_mkdir(path: string, mode: mode_t) c_int {
    if (extrn.mkdir(path, mode) == -1) return -errno;
    return 0;
}

// static int xmp_unlink(const char *path)
export fn xmp_unlink(path: string) c_int {
    if (linux.unlink(path) == -1) return -errno;
    return 0;
}

// static int xmp_rmdir(const char *path)
export fn xmp_rmdir(path: string) c_int {
    if (linux.rmdir(path) == -1) return -errno;
    return 0;
}

// static int xmp_symlink(const char *from, const char *to)
export fn xmp_symlink(from: string, to: string) c_int {
    if (linux.symlink(from, to) == -1) return -errno;
    return 0;
}

// static int xmp_rename(const char *from, const char *to, unsigned int flags)
export fn xmp_rename(from: string, to: string, flags: c_uint) c_int {
    if (flags > 0) return -@as(c_int, @enumToInt(linux.E.INVAL));
    if (linux.rename(from, to) == -1) return -errno;
    return 0;
}

// static int xmp_link(const char *from, const char *to)
export fn xmp_link(from: string, to: string) c_int {
    if (extrn.link(from, to) == -1) return -errno;
    return 0;
}

// static int xmp_chmod(const char *path, mode_t mode, struct fuse_file_info *fi)
export fn xmp_chmod(path: string, mode: mode_t, fi: *c.fuse_file_info) c_int {
    _ = fi;
    if (extrn.chmod(path, mode) == -1) return -errno;
    return 0;
}

// static int xmp_chown(const char *path, uid_t uid, gid_t gid, struct fuse_file_info *fi)
export fn xmp_chown(path: string, uid: uid_t, gid: gid_t, fi: *c.fuse_file_info) c_int {
    _ = fi;
    if (extrn.lchown(path, uid, gid) == -1) return -errno;
    return 0;
}

// static int xmp_truncate(const char *path, off_t size, struct fuse_file_info *fi)
export fn xmp_truncate(path: string, size: off_t, fi: ?*fuse_file_info) c_int {
    if (fi != null) {
        if (extrn.ftruncate(@intCast(c_int, fi.?.fh), size) == -1) return -errno;
    } else {
        if (extrn.truncate(path, size) == -1) return -errno;
    }
    return 0;
}

// static int xmp_create(const char *path, mode_t mode, struct fuse_file_info *fi)
export fn xmp_create(path: string, mode: mode_t, fi: *fuse_file_info) c_int {
    const res = extrn.open(path, fi.flags, mode);
    if (res == -1) return -errno;
    fi.fh = @intCast(u64, res);
    return 0;
}

// static int xmp_open(const char *path, struct fuse_file_info *fi)
export fn xmp_open(path: string, fi: *fuse_file_info) c_int {
    const res = extrn.open(path, fi.flags);
    if (res == -1) return -errno;
    fi.fh = @intCast(u64, res);
    return 0;
}

// static int xmp_read(const char *path, char *buf, size_t size, off_t offset, struct fuse_file_info *fi)
export fn xmp_read(path: string, buf: mstring, size: size_t, offset: off_t, fi: ?*fuse_file_info) c_int {
    const fd: c_int = if (fi == null) extrn.open(path, linux.O.RDONLY) else @intCast(c_int, fi.?.fh);
    if (fd == -1) return -errno;

    const res = extrn.pread(fd, buf, size, offset);
    if (res == -1) return errno;

    _ = if (fi == null) extrn.close(fd);
    return @intCast(c_int, res);
}

// static int xmp_write(const char *path, const char *buf, size_t size, off_t offset, struct fuse_file_info *fi)
export fn xmp_write(path: string, buf: string, size: size_t, offset: off_t, fi: ?*fuse_file_info) c_int {
    const fd: c_int = if (fi == null) extrn.open(path, linux.O.RDONLY) else @intCast(c_int, fi.?.fh);
    if (fd == -1) return -errno;

    const res = extrn.pwrite(fd, buf, size, offset);
    if (res == -1) return errno;

    _ = if (fi == null) extrn.close(fd);
    return @intCast(c_int, res);
}

// static int xmp_statfs(const char *path, struct statvfs *stbuf)
export fn xmp_statfs(path: string, stbuf: *extrn.Statvfs) c_int {
    if (extrn.statvfs(path, stbuf) == -1) return -errno;
    return 0;
}

// static int xmp_release(const char *path, struct fuse_file_info *fi)
export fn xmp_release(path: string, fi: *fuse_file_info) c_int {
    _ = path;
    _ = extrn.close(@intCast(c_int, fi.fh));
    return 0;
}

// static int xmp_fsync(const char *path, int isdatasync, struct fuse_file_info *fi)
extern fn xmp_fsync(path: string, isdatasync: c_int, fi: *c.fuse_file_info) c_int;

// static off_t xmp_lseek(const char *path, off_t off, int whence, struct fuse_file_info *fi)
extern fn xmp_lseek(path: string, off: off_t, whence: c_int, fi: *c.fuse_file_info) off_t;

//
//

extern threadlocal var errno: c_int;
const extrn = struct {
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
    const DIR = opaque {};
    extern fn opendir(name: string) ?*DIR;
    extern fn readdir(dirp: *DIR) ?*dirent;
    extern fn closedir(dirp: *DIR) c_int;
    extern fn mkfifoat(dirfd: c_int, pathname: string, mode: mode_t) c_int;
    extern fn lstat(pathname: string, statbuf: *linux.Stat) c_int;
    extern fn access(pathname: string, mode: c_int) c_int;
    extern fn readlink(path: string, buf: mstring, bufsiz: size_t) ssize_t;
    extern fn openat(dirfd: c_int, pathname: string, flags: c_int, mode: mode_t) c_int;
    extern fn close(fd: c_int) c_int;
    extern fn mkdirat(dirfd: c_int, pathname: string, mode: mode_t) c_int;
    extern fn symlinkat(oldpath: ?string, newdirfd: c_int, newpath: string) c_int;
    extern fn mknodat(dirfd: c_int, pathname: string, mode: mode_t, dev: dev_t) c_int;
    extern fn mkdir(path: string, mode: mode_t) c_int;
    extern fn link(oldpath: string, newpath: string) c_int;
    extern fn chmod(pathname: string, mode: mode_t) c_int;
    extern fn lchown(pathname: string, owner: uid_t, group: gid_t) c_int;
    extern fn ftruncate(fd: c_int, length: off_t) c_int;
    extern fn truncate(path: string, length: off_t) c_int;
    extern fn open(pathname: string, flags: c_int, ...) c_int;
    extern fn pread(fd: c_int, buf: mstring, count: size_t, offset: off_t) ssize_t;
    extern fn pwrite(fd: c_int, buf: string, count: size_t, offset: off_t) ssize_t;
    extern fn statvfs(path: string, buf: *Statvfs) c_int;

    const dirent = extern struct {
        d_ino: ino_t,
        d_off: off_t,
        d_reclen: c_ushort,
        d_type: u8,
        d_name: *const [256]u8,
    };
};

const fuse_file_info = extern struct {
    flags: c_int,
    bitfield0: packed struct(c_uint) {
        writepage: u1,
        direct_io: u1,
        keep_cache: u1,
        flush: u1,
        nonseekable: u1,
        flock_release: u1,
        cache_readdir: u1,
        noflush: u1,
        padding: u24,
    },
    bitfield1: packed struct(c_uint) {
        padding2: u32,
    },
    fh: u64,
    lock_owner: u64,
    poll_events: u32,
};
