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
)dnl
dnl
define(`R2_RULE_FETCH',
.R2_PKG.fetch: .curl.install
	mkdir -p $(CWD)/R2_DISTS && cd $(CWD)/R2_DISTS && \
		if [ ! -f $(R2_PKG.tgz) ]; then $(WGET) $(R2_PKG.url); fi && \
	touch -a $(CWD)/.R2_PKG.fetch
)dnl
dnl
define(`R2_RULE_GIT',
.R2_PKG.fetch:
	touch $(CWD)/.R2_PKG.fetch

.R2_PKG.unpack: .R2_PKG.fetch .git.install
	rm -rf $(CWD)/R2_BUILD/$(R2_PKG.dir) && \
	$(GIT) clone $(R2_PKG.giturl) $(CWD)/R2_BUILD/$(R2_PKG.dir) && \
        cd R2_BUILD/$(R2_PKG.dir) && \
	$(GIT) checkout $(R2_PKG.gitref)
	touch $(CWD)/.R2_PKG.unpack
	touch $(CWD)/.R2_PKG.patch
)dnl
dnl
define(`R2_CFG_ARGS',
R2_PKG.args += --prefix=$(pfx)
)dnl
dnl
define(`R2_RULE_UNPACK',
.R2_PKG.unpack: .R2_PKG.fetch R2_SHA1DIR/R2_PKG.sha1
	ls -l $(CWD)/R2_DISTS/$(R2_PKG.tgz)
	$(SHASUM) $(CWD)/R2_DISTS/$(R2_PKG.tgz)
	cd $(CWD)/R2_DISTS && $(SHASUM) -c $(CWD)/R2_SHA1DIR/R2_PKG.sha1
	mkdir -p R2_BUILD && cd $(CWD)/R2_BUILD && tar xvf $(CWD)/R2_DISTS/$(R2_PKG.tgz) && touch $(CWD)/.R2_PKG.unpack
)dnl
dnl
define(`R2_RULE_PATCH',
.R2_PKG.patch: .R2_PKG.unpack
	if [ -d $(CWD)/patches/R2_PKG ]; then unset P4CONFIG P4EDITOR P4PORT P4USER; QUILT_PATCHES=$(CWD)/patches/R2_PKG quilt --quiltrc - push -a; fi && \
	touch $(CWD)/.R2_PKG.patch
)dnl
define(`R2_RULE_CONFIG',
.R2_PKG.config: .R2_PKG.patch $(R2_PKG.config_deps)
	cd R2_BUILD/$(R2_PKG.dir) && \
	CC=$(CC) CXX=$(CXX) CFLAGS="$(CFLAGS)" CXXFLAGS="$(CFLAGS)" PATH=$(DESTDIR)$(pfx)/bin:$(PATH) ./configure $(R2_PKG.args)  && \
	touch $(CWD)/.R2_PKG.config
)dnl
dnl
define(`R2_RULE_MAKE',
.R2_PKG.make: .R2_PKG.config
	cd R2_BUILD/$(R2_PKG.dir) && \
	DYLD_LIBRARY_PATH=$(DESTDIR)$(pfx)/lib\
	LD_LIBRARY_PATH=$(LD_LIBRARY_PATH):$(DESTDIR)$(pfx)/lib \
        $(MAKE) -j && \
	touch $(CWD)/.R2_PKG.make
)dnl
dnl
define(`R2_RULE_CMAKE_CONFIG',
.R2_PKG.config: .R2_PKG.unpack $(R2_PKG.config_deps)
	mkdir -p R2_BUILD/$(R2_PKG.dir)/build && \
	cd R2_BUILD/$(R2_PKG.dir)/build && \
	CC=$(CC) CXX=$(CXX) CFLAGS="$(CFLAGS)" CXXFLAGS="$(CFLAGS)" cmake .. -DCMAKE_INSTALL_PREFIX=$(pfx) $(R2_PKG.args) && \
	touch $(CWD)/.R2_PKG.config
)dnl
dnl
define(`R2_RULE_CMAKE_MAKE',
.R2_PKG.make: .R2_PKG.config
	cd R2_BUILD/$(R2_PKG.dir)/build && \
	DYLD_LIBRARY_PATH=$(DYLD_LIBRARY_PATH) $(MAKE) -j $(shell nproc) && \
	touch $(CWD)/.R2_PKG.make
)dnl
dnl
define(`R2_RULE_CMAKE_INSTALL',
.R2_PKG.install: .R2_PKG.make
	cd R2_BUILD/$(R2_PKG.dir)/build && \
	DYLD_LIBRARY_PATH=$(DYLD_LIBRARY_PATH) make install $(DEST) && \
	touch $(CWD)/.R2_PKG.install
)dnl
dnl
define(`R2_RULE_INSTALL',
.R2_PKG.install: .R2_PKG.make
	cd R2_BUILD/$(R2_PKG.dir) && \
	DYLD_LIBRARY_PATH=$(DESTDIR)$(pfx)/lib \
	LD_LIBRARY_PATH=$(LD_LIBRARY_PATH):$(DESTDIR)$(pfx)/lib \
        $(MAKE) install $(DEST) && \
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
R2_RULE_CMAKE_CONFIG
R2_RULE_CMAKE_MAKE
R2_RULE_CMAKE_INSTALL
R2_RULE_CLEAN
)dnl
