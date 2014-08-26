
CWD = $(CURDIR)
pfx := $(CWD)/install
DEST :=
SUBMAKES := $(wildcard submakes/*.mak.in)

include $(SUBMAKES:mak.in=mak)

LD_LIBRARY_PATH := $(pfx)/lib
PKG_CONFIG_PATH := $(pfx)/lib/pkgconfig
PATH := $(pfx)/bin:$(PATH)
OS := $(shell uname)

# --target=i386-apple-darwin13.2.0
ifeq "$(OS)" "Darwin"
DYLD_LIBRARY_PATH := $(pfx)/lib
#CXX := g++-4.7
#CC := gcc-4.7
SHASUM := shasum
#OSDEPS := /usr/local/bin/gcc-4.7
PATH := $(pfx)/bin:/usr/local/opt:$(PATH)
LDSHARED='$(CC) $(ARCHFLAGS) -dynamiclib -undefined suppress -flat_namespace'
endif

CFLAGS := -I$(pfx)/include $(ARCHFLAGS)
CPPFLAGS := -I$(pfx)/include $(ARCHFLAGS)
CXXFLAGS := -I$(pfx)/include $(ARCHFLAGS)
LDFLAGS := -L$(pfx)/lib $(ARCHFLAGS)

%.mak: %.mak.in r2.m4
	m4 $< > $@

%/.exist:
	mkdir -p $(@D)
	touch $@

all: \
	dists/.exist \
	build/.exist \
	$(OSDEPS) \
	.emacs.install \
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
