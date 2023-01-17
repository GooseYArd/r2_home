define(`R2_DISTS', `dists')dnl
define(`R2_BUILD', `builddir')dnl
define(`R2_SHA1DIR', `shasums')dnl
define(`R2_DECLS',
R2_PKG.version := R2_VERSION
R2_PKG.dir := R2_DIR
R2_PKG.tgz := R2_DIST
R2_PKG.url := R2_URL
R2_PKG.giturl := R2_GITURL
R2_PKG.gitref := R2_GITREF
SHELL := /bin/bash
)dnl
dnl
define(`R2_CONFIG_ENV',CC=$(CC) CXX=$(CXX) CFLAGS="$(CFLAGS) $(R2_PKG.extra_cflags)" CPPFLAGS="$(CPPFLAGS) $(R2_PKG.extra_cppflags)" LDFLAGS="$(LDFLAGS) $(R2_PKG.extra_ldflags)" CXXFLAGS="$(CFLAGS)" $(R2_PKG.extra_config_env) PATH=$(DESTDIR)$(pfx)/bin:$(PATH) PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) LD_LIBRARY_PATH=$(LD_LIBRARY_PATH):$(DESTDIR)$(pfx)/lib CMAKE_PREFIX_PATH=$(CMAKE_PREFIX_PATH))dnl
dnl
define(`R2_MAKE_ENV',CC=$(CC) CXX=$(CXX) PATH=$(DESTDIR)$(pfx)/bin:$(PATH) LD_LIBRARY_PATH=$(LD_LIBRARY_PATH):$(DESTDIR)$(pfx)/lib)dnl
dnl
define(`R2_RULE_FETCH',
.R2_PKG.fetch:
	mkdir -p $(CWD)/R2_DISTS && cd $(CWD)/R2_DISTS && \
		if [ ! -f $(R2_PKG.tgz) ]; then $(CURL) $(R2_PKG.url); fi && \
	touch -a $(CWD)/.R2_PKG.fetch
)dnl
dnl
define(`R2_RULE_GIT',
.R2_PKG.fetch:
	touch $(CWD)/.R2_PKG.fetch

.R2_PKG.unpack: .R2_PKG.fetch
	rm -rf $(CWD)/R2_BUILD/$(R2_PKG.dir) && \
	$(GIT) clone $(R2_PKG.giturl) $(CWD)/R2_BUILD/$(R2_PKG.dir) && \
        cd R2_BUILD/$(R2_PKG.dir) && \
	$(GIT) checkout $(R2_PKG.gitref)
	touch $(CWD)/.R2_PKG.unpack
	touch $(CWD)/.R2_PKG.patch
)dnl
dnl
define(`R2_CFG_ARGS',
R2_PKG.args ?= --prefix=$(pfx)
R2_PKG.destdir ?= DESTDIR=$(DESTDIR)
)dnl
dnl
define(`R2_RULE_UNPACK',
.R2_PKG.unpack: .R2_PKG.fetch R2_SHA1DIR/R2_PKG.sha256
	$(SHASUM) $(CWD)/R2_DISTS/$(R2_PKG.tgz)
	cd $(CWD)/R2_DISTS && $(SHASUM) -c $(CWD)/R2_SHA1DIR/R2_PKG.sha256
	mkdir -p R2_BUILD && cd $(CWD)/R2_BUILD && tar xf $(CWD)/R2_DISTS/$(R2_PKG.tgz) && touch $(CWD)/.R2_PKG.unpack
)dnl
dnl
define(`R2_RULE_PATCH',
.R2_PKG.patch: .R2_PKG.unpack
	if [ -d $(CWD)/patches/R2_PKG ]; then unset P4CONFIG P4EDITOR P4PORT P4USER; cd R2_BUILD/$(R2_PKG.dir) && PATCHROOT=$(CWD)/patches/R2_PKG; grep -v "^$$" $$PATCHROOT/series | while read patch; do patch -p1 < $$PATCHROOT/$$patch; done; fi && \
	touch $(CWD)/.R2_PKG.patch
)dnl
define(`R2_RULE_CONFIG',
.R2_PKG.config: .R2_PKG.patch $(R2_PKG.config_deps)
	cd R2_BUILD/$(R2_PKG.dir) && \
	R2_CONFIG_ENV ./configure $(R2_PKG.args) &> $(CWD)/logs/R2_PKG.config.log  && \
	touch $(CWD)/.R2_PKG.config
)dnl
dnl
define(`R2_RULE_NULLCONFIG',
.R2_PKG.config: .R2_PKG.patch $(R2_PKG.config_deps)
	cd R2_BUILD/$(R2_PKG.dir) && \
	touch $(CWD)/.R2_PKG.config
)dnl
dnl
define(`R2_RULE_MAKE',
.R2_PKG.make: .R2_PKG.config
	cd R2_BUILD/$(R2_PKG.dir) && \
	LD_LIBRARY_PATH=$(LD_LIBRARY_PATH):$(DESTDIR)$(pfx)/lib \
        R2_MAKE_ENV $(MAKE) $(R2_PKG.make_flags) &> $(CWD)/logs/R2_PKG.make.log && \
	touch $(CWD)/.R2_PKG.make
)dnl
dnl
define(`R2_RULE_CMAKE_CONFIG',
.R2_PKG.config: .R2_PKG.unpack $(R2_PKG.config_deps)
	mkdir -p R2_BUILD/$(R2_PKG.dir)/build && \
	cd R2_BUILD/$(R2_PKG.dir)/build && \
	R2_CONFIG_ENV cmake .. -DCMAKE_PREFIX_PATH=$(DESTDIR)$(pfx)/lib/cmake -DCMAKE_INSTALL_PREFIX=$(pfx) $(R2_PKG.args) &> $(CWD)/logs/R2_PKG.config.log && \
	touch $(CWD)/.R2_PKG.config
)dnl
dnl
define(`R2_RULE_CMAKE_MAKE',
.R2_PKG.make: .R2_PKG.config $(R2_PKG.make_deps)
	cd R2_BUILD/$(R2_PKG.dir)/build && \
	R2_MAKE_ENV $(MAKE) VERBOSE=1 &> $(CWD)/logs/R2_PKG.make.log && \
	touch $(CWD)/.R2_PKG.make
)dnl
dnl
define(`R2_RULE_CMAKE_INSTALL',
.R2_PKG.install: .R2_PKG.make $(R2_PKG.install_deps)
	cd R2_BUILD/$(R2_PKG.dir)/build && \
	DYLD_LIBRARY_PATH=$(DYLD_LIBRARY_PATH) make install $(DEST) &> $(CWD)/logs/R2_PKG.install.log && \
	touch $(CWD)/.R2_PKG.install
)dnl
dnl
define(`R2_RULE_MESON_CONFIG',
.R2_PKG.config: .R2_PKG.unpack .meson.install $(R2_PKG.config_deps)
	mkdir -p R2_BUILD/$(R2_PKG.dir) && \
	cd R2_BUILD/$(R2_PKG.dir) && \
	R2_CONFIG_ENV $(MESON) setup build --prefix=$(pfx) $(R2_PKG.args) &> $(CWD)/logs/R2_PKG.config.log && \
	touch $(CWD)/.R2_PKG.config
)dnl
dnl
define(`R2_RULE_MESON_MAKE',
.R2_PKG.make: .R2_PKG.config
	cd R2_BUILD/$(R2_PKG.dir) && \
	R2_MAKE_ENV $(MESON) compile -C build &> $(CWD)/logs/R2_PKG.make.log && \
	touch $(CWD)/.R2_PKG.make
)dnl
dnl
define(`R2_RULE_MESON_INSTALL',
.R2_PKG.install: .R2_PKG.make
	cd R2_BUILD/$(R2_PKG.dir)/build && \
	DYLD_LIBRARY_PATH=$(DYLD_LIBRARY_PATH) \
	$(R2_PKG.destdir) $(MESON) install $(R2_PKG.install_tags) &> $(CWD)/logs/R2_PKG.install.log
	$(R2_PKG.post_install)
	touch $(CWD)/.R2_PKG.install
)dnl
dnl
define(`R2_RULE_INSTALL',
.R2_PKG.install: .R2_PKG.make
	cd R2_BUILD/$(R2_PKG.dir) && \
	DYLD_LIBRARY_PATH=$(DESTDIR)$(pfx)/lib \
	LD_LIBRARY_PATH=$(LD_LIBRARY_PATH):$(DESTDIR)$(pfx)/lib \
        $(MAKE) install $(R2_PKG.destdir) &> $(CWD)/logs/R2_PKG.install.log
	$(R2_PKG.post_install)
	touch $(CWD)/.R2_PKG.install
)dnl
dnl
define(`R2_RULE_CLEAN',
.R2_PKG.clean:
	rm -rf R2_BUILD/$(R2_PKG.dir) .R2_PKG.* submakes/R2_PKG.mak
GLOBAL_CLEAN += .R2_PKG.clean

.R2_PKG.distclean:
	#rm -f R2_DISTS/$(R2_PKG.tgz)

GLOBAL_DISTCLEAN += .R2_PKG.distclean
)dnl
dnl
define(R2_DEFAULT_RULES_NOINSTALL,
R2_DECLS
R2_RULE_FETCH
R2_RULE_UNPACK
R2_RULE_PATCH
R2_RULE_CLEAN
)dnl
define(R2_DEFAULT_RULES_NOCONFIG,
R2_DECLS
R2_RULE_FETCH
R2_RULE_UNPACK
R2_RULE_PATCH
R2_RULE_MAKE
R2_RULE_INSTALL
R2_RULE_CLEAN
)dnl
define(R2_DEFAULT_RULES,
R2_CFG_ARGS
R2_RULE_CONFIG
R2_DEFAULT_RULES_NOCONFIG
)dnl
define(R2_DEFAULT_RULES_CMAKE,
R2_DECLS
R2_RULE_FETCH
R2_RULE_UNPACK
R2_RULE_PATCH
R2_RULE_CMAKE_CONFIG
R2_RULE_CMAKE_MAKE
R2_RULE_CMAKE_INSTALL
R2_RULE_CLEAN
)dnl
define(R2_DEFAULT_RULES_MESON,
R2_DECLS
R2_RULE_FETCH
R2_RULE_UNPACK
R2_RULE_PATCH
R2_RULE_MESON_CONFIG
R2_RULE_MESON_MAKE
R2_RULE_MESON_INSTALL
R2_RULE_CLEAN
)dnl
define(R2_DEFAULT_RULES_MAKEFILE,
R2_DECLS
R2_RULE_FETCH
R2_RULE_UNPACK
R2_RULE_PATCH
R2_RULE_NULLCONFIG
R2_RULE_MAKE
R2_RULE_INSTALL
R2_RULE_CLEAN
)dnl
