all: festamp feestamp fedate feedate decode
.PHONY: all

ZIG="../zig-linux-x86_64-0.5.0/zig"
ZIGARGS=-lc build-exe --release-small --single-threaded --strip

festamp: festamp.zig feetime.zig
	${ZIG} ${ZIGARGS} festamp.zig

feestamp: feestamp.zig feetime.zig
	${ZIG} ${ZIGARGS} feestamp.zig

fedate: fedate.zig feetime.zig
	${ZIG} ${ZIGARGS} fedate.zig

feedate: feedate.zig feetime.zig
	${ZIG} ${ZIGARGS} feedate.zig

decode: decode.zig feetime.zig
	${ZIG} ${ZIGARGS} decode.zig

festamp-static: festamp.zig feetime.zig
	${ZIG} ${ZIGARGS} festamp.zig -target x86_64-linux-musl --name festamp-static
