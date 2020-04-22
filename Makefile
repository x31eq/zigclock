all: festamp feestamp fedate feedate
.PHONY: all

ZIG="../zig-linux-x86_64-0.5.0/zig"

festamp: festamp.zig feetime.zig
	${ZIG} -lc build-exe --release-small --single-threaded --strip festamp.zig

feestamp: feestamp.zig feetime.zig
	${ZIG} -lc build-exe --release-small --single-threaded --strip feestamp.zig

fedate: fedate.zig feetime.zig
	${ZIG} -lc build-exe --release-small --single-threaded --strip fedate.zig

feedate: feedate.zig feetime.zig
	${ZIG} -lc build-exe --release-small --single-threaded --strip feedate.zig

festamp-static: festamp.zig feetime.zig
	${ZIG} -lc build-exe --release-small --single-threaded --strip festamp.zig -target x86_64-linux-musl --name festamp-static
