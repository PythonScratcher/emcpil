VERSION:=0.13.0
SRCS:=$(patsubst %,./src/%.vala,profile config gui play features servers)
VFLAGS:=--pkg json-glib-1.0 --pkg gio-2.0 --pkg gtk+-3.0
VFLAGS+=--vapidir=./src/ --pkg gmcpil -b ./src/ -d build
VFLAGS+=-X -DGMCPIL_VERSION="\"v$(VERSION)\""

STRIP:=strip
PKG_CONFIG:=pkg-config

ifdef CROSS_COMPILE
CC:=$(CROSS_COMPILE)-gcc
PKG_CONFIG:=$(CROSS_COMPILE)-pkg-config
STRIP:=$(CROSS_COMPILE)-strip
VFLAGS+=--cc=$(CC) --pkg-config=$(PKG_CONFIG)
endif

ARCH:=$(shell $(CC) -dumpmachine | grep -Eo "arm|aarch|86|x86_64")
ifeq ($(ARCH),86)
	DEB_ARCH:=i386
else ifeq ($(ARCH),x86_64)
	DEB_ARCH:=amd64
else ifeq ($(ARCH),aarch)
	DEB_ARCH:=arm64
else
	DEB_ARCH:=armhf
endif

ifdef DEBUG
VFLAGS+=-X -g --save-temps --fatal-warnings
else
VFLAGS+=-X -O3
endif

ifndef NO_BUSTER_COMPAT
VFLAGS+=-D BUSTER_COMPAT
endif

./build/gmcpil: ./build/ $(SRCS)
	valac $(VFLAGS) $(SRCS) -o ./gmcpil
ifndef DEBUG
	$(STRIP) ./build/gmcpil
endif

./build/:
	mkdir -p ./build/

pack: ./build/gmcpil
	mkdir -p ./deb/DEBIAN/
	mkdir -p ./deb/usr/bin/
	cp ./build/gmcpil ./deb/usr/bin/
	cp -r ./res/usr/share/ ./deb/usr/
	chmod a+x ./deb/usr/bin/gmcpil
	sed "s/{{ARCH}}/$(DEB_ARCH)/g; s/{{VERSION}}/$(VERSION)/g" ./res/control > ./deb/DEBIAN/control
	fakeroot dpkg-deb -b ./deb/ ./gmcpil_$(VERSION)_$(DEB_ARCH).deb

clean:
	rm -rf ./deb/
	rm -rf ./build/

purge: clean
	rm -f ./gmcpil_*.deb
