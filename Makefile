
CWD = $(CURDIR)
pfx := $(CWD)/install
DEST :=
SUBMAKES := $(wildcard submakes/*.mak.in)

CAFILE := $(CWD)/ca-certificates.crt
# WGET := $(CWD)/builddir/tools/bin/curl -O -L --cacert $(CAFILE)
CURL := curl -O -L --cacert $(CAFILE)

include $(SUBMAKES:mak.in=mak)

LD_LIBRARY_PATH := $(pfx)/lib
PKG_CONFIG_PATH := $(pfx)/lib/pkgconfig
PATH := $(pfx)/bin:$(PATH)
OS := $(shell uname)

ifeq "$(OS)" "Darwin"
OSX_MINVER := 12.3
SHASUM := shasum -a256
SED_TARGET := .sed.install
INSTALL_TARGET := .coreutils.install
DYLD_FALLBACK_LIBRARY_PATH := $(DESTDIR)$(pfx)/lib
ARCHFLAGS := "-mmacosx-version-min=$(OSX_MINVER)"
MACOSX_DEPLOYMENT_TARGET=$(OSX_MINVER)
LDFLAGS := "-Wl,-headerpad_max_install_names"
LDCXXSHARED := "/usr/bin/clang++ -bundle -undefined dynamic_lookup"
SHLIBS := -ldl -framework CoreFoundation -framework Foundation
INSTALL = \
      LD_LIBRARY_PATH=$(CWD)/builddir/tools/lib \
      PATH=$(CWD)/builddir/tools/bin:$(PATH) \
      $(CWD)/builddir/tools/bin/install
SED = \
      LD_LIBRARY_PATH=$(CWD)/builddir/tools/lib \
      PATH=$(CWD)/builddir/tools/bin:$(PATH) \
      $(CWD)/builddir/tools/bin/sed
SEDI = $(SED) -i
VERSION = $(shell head -1 $(CWD)/../portable-bart-rest-api/debian/changelog | awk '{ print $$2 }' | $(SED) 's/[()]//g')
LIBINTL := -lintl -liconv
MACHTYPE := arm64-apple-darwin18
APP := $(CWD)
OSXDEST := $(APP)/install/usr/local
OSXPY := $(OSXDEST)/lib/akamai-portable-python/bin/python3
PIP :=  $(OSXDEST)/lib/akamai-portable-python/bin/pip --cert $(CWD)/ca-certificates.crt
PDM :=  $(OSXDEST)/lib/akamai-portable-python/bin/pdm
else  # LINUX

# LD_LIBRARY_PATH := $(DESTDIR)$(pfx)/lib
INSTALL := install
LIBINTL := -liconv
PIP :=  $(DESTDIR)$(pfx)/bin/pip3
#PIP :=  $(DESTDIR)$(pfx)/bin/pip --cert $(CWD)/ca-certificates.crt
PDM :=  $(DESTDIR)$(pfx)/bin/pdm
SED := sed
SEDI := sed -i
endif



CFLAGS := -I$(pfx)/include $(ARCHFLAGS) -fPIC
CPPFLAGS := -I$(pfx)/include $(ARCHFLAGS)
CXXFLAGS := -I$(pfx)/include $(ARCHFLAGS)
LDFLAGS := -L$(pfx)/lib -Wl,-rpath,$(pfx)/libs $(ARCHFLAGS)

# GIT = \
#       LD_LIBRARY_PATH=$(CWD)/builddir/tools/lib \
#       PATH=$(CWD)/builddir/tools/bin:$(PATH) \
#       $(CWD)/builddir/tools/bin/git \
# 	-c http.sslCAInfo=$(CWD)/ca-certificates.crt \
# 	-c http.sslVerify=false
GIT = git
%.mak: %.mak.in r2.m4
	m4 $< > $@

%/.exist:
	mkdir -p $(@D)
	touch $@

all: \
	dists/.exist \
	build/.exist \
	$(OSDEPS) \
	.neovim.install \
	env.sh

# Misc small targets
.bundler.install: .ruby.install
	DYLD_LIBRARY_PATH=$(DYLD_LIBRARY_PATH) \
	$(pfx)/bin/gem install bundler
#	$(pfx)/bin/bundle config build.pg --with-pg-config=$(pfx)/bin/pg_config
	touch $@

#.netssh.install: 
#	$(pfx)/bin/gem install net-ssh -v 2.6.6

config.m4:
	echo "define(\`ROOT', \`$(PWD)')" > $@
	echo "define(\`DYLD_VALUE', \`$(DYLD_LIBRARY_PATH)')" >> $@

#$(CXX):
#	sudo aptitude install g++
#bootstrap: $(CXX) $(NCURSESH) $(READLINEH) $(PAM_APPLH) $(EVENTH)

m4deps :=
ifeq "$(OS)" "Darwin"
	SHASUM := shasum
	m4deps := 
else
	SHASUM := sha1sum
endif

test:
	echo $(OS)
	echo $(SHASUM)

%.sh: config.m4 %.sh.in
	m4 $^ > $@
	chmod +x $@

foo:
	echo $(GLOBAL_CLEAN)

clean: $(GLOBAL_CLEAN)
	rm -rf install
	rm -f env.sh
	rm -f submakes/*.mak

distclean: clean $(GLOBAL_DISTCLEAN)
