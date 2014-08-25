# fe_runtime

fe_runtime includes the set of runtime dependencies for Fire Engine,
allowing it to run with a consistent versions of ruby, rake, et al on
any platform on which the dependencies can be built.

To build the runtime, run "make". The individual builds that succeed
in parallel already invoke a submake using the jobserver "-jn"
argument, so passing -j4 or -j8 to the toplevel make will not yield as
much of an improvement as you might hope (but it's safe).

Parallel builds will occasionally fail (some of the packagers, most
notably openssl, are lax about confirming that parallel builds are
race free). If anything fails, usually running make against without
the -j flag will clear it up, although the build will take quite a lot longer.

# Notes on wxWidgets

Because we are using an ancient Erlang release, a correspondingly
ancient version of wxWidgets is required to get wx (used by Observer
and Debugger) to build. On OSX, this requires one to build or wxMAC or
wxGTK. The 2.8.12 versions of either one won't build out of the box on
OSX newer than 10.5 or so. Our options therefore are to manually
install old Xcode and SDK versions, or to use binart wxWidgets
packages (or to upgrade to a modern Erlang, but that's another story).

# Statically linking openssl

=======
# Usage

After performing `make -j4` or `make -j8` , run: 
```bash
source env.sh
```

to load runtime paths.

# Binary Relocatability

By default, the build artifacts are configured with the prefix
./install and then installed there, which means they are usable
immediately from where they're installed.

Ruby tolerates the relocation of it's installation tree; the location
of shared objects that are dynaloaded at runtime is calculated from
the location of the interpreter binary. Some of the binaries are not
reloctable (use ldd to find them). If you are building the runtime to
be deployed to another machine, adjust the value of pfx to the install
path you need, and set the DEST variable to point to the place where
you want the build artifacts to be placed so that you can tar them up. 

# Updating Components

To update the build when an upstream release occurs, change the
version number in submakes/<package.mak.in>.

The sha1sum for the component must then be changed, those are contained in:

shasums/<package>.sha1

You can either (preferably) grab a sha file from the distributor, or
fetch the file and calculate it yourself:

cd dists
sha1sum <package>.tar.gz > ../shasums/<package>.sha1


