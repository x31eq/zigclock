all: festamp feestamp
.PHONY: all

festamp: festamp.zig feetime.zig
	../zig-linux-x86_64-0.5.0/zig -lc build-exe --release-small --single-threaded --strip festamp.zig

feestamp: feestamp.zig feetime.zig
	../zig-linux-x86_64-0.5.0/zig -lc build-exe --release-small --single-threaded --strip feestamp.zig

festamp-static: festamp.zig feetime.zig
	../zig-linux-x86_64-0.5.0/zig -lc build-exe --release-small --single-threaded --strip festamp.zig -target x86_64-linux-musl --name festamp-static
