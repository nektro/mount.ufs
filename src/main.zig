pub export fn main(argc: c_int, argv: [*:null]const ?[*:0]const u8) c_int {
    return c_main(argc, argv);
}

extern fn c_main(argc: c_int, argv: [*:null]const ?[*:0]const u8) c_int;
