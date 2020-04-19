festamp: festamp.zig
	../zig-linux-x86_64-0.5.0/zig -lc build-exe --release-small --single-threaded --strip festamp.zig

festamp-static: festamp.zig
	../zig-linux-x86_64-0.5.0/zig -lc build-exe --release-small --single-threaded --strip festamp.zig -target x86_64-linux-musl --name festamp-static
