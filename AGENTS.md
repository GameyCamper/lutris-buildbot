# Lutris Buildbot - Agent Guide

This repository contains build scripts for runners and games used by Lutris, the open-source gaming platform for Linux.

## Project Overview

**Purpose**: Build and package various game runners and games for distribution via Lutris.

**Target System**: Debian 11 Bullseye (same system used by the Lutris runtime).

**Primary Use Cases**:
- Building Wine runners with custom patches (e.g., GloriousEggroll Proton Wine)
- Building game engine ports (ioquake3, OpenRA, etc.)
- Building emulator runners (MAME, DOSBox, ScummVM, etc.)
- Building the Lutris runtime environment

## Project Structure

```
lutris-buildbot/
├── games/              # Build scripts for game engine ports (59 games)
├── runners/            # Build scripts for emulator/runner software (36 runners)
├── runtime/            # Lutris runtime build scripts
├── tools/              # Helper tools and packaging scripts
├── lib/                # Shared utility functions
├── builds/             # Output directory for build artifacts (gitignored)
├── Makefile            # Docker container management
├── docker-winebuild.sh # Docker-based wine build wrapper
├── vagrant-winebuild.sh # Vagrant-based wine build wrapper
└── setup-buildbot.sh   # Container/VM setup script
```

## Build Environment

### Recommended Setup

The project is designed to run in isolated environments:

1. **Docker/Podman** (Recommended)
   - Image: `docker.io/gloriouseggroll/lutris_buildbot:bullseye`
   - Use `./docker-winebuild.sh` for Wine builds
   - Use `make setup` to create container

2. **Vagrant VM**
   - Use `./vagrant-winebuild.sh` for Wine builds
   - Vagrantfile in `tools/vagrant/`

### Makefile Commands

```bash
make setup      # Create and start Docker container
make shell      # Access container as vagrant user
make rootshell  # Access container as root
make teardown   # Stop and remove container
```

## Build Script Patterns

### Standard Build Script Structure

Most build scripts follow this pattern:

```bash
#!/bin/bash
set -e
lib_path="../../lib/"
source ${lib_path}path.sh
source ${lib_path}util.sh

# Variable setup
runner_name=$(get_runner)  # For runners
# or
game_name="gamename"       # For games
root_dir=$(pwd)
source_dir="${root_dir}/${name}-src"
build_dir="${root_dir}/${name}-build"
bin_dir="${root_dir}/${name}"
arch=$(uname -m)
version="x.y.z"
publish_dir="/builds/runners/${name}"  # or "/builds/games/${name}"

# Functions
InstallDeps() { ... }
Fetch() { ... }
Build() { ... }
Install() { ... }
Package() { ... }
Clean() { ... }

# Execution
if [ $1 ]; then
    $1  # Allow running specific functions
else
    InstallDeps
    Fetch
    Build
    Install
    Package
    Clean
fi
```

### Key Library Functions

**lib/path.sh**:
- `get_runner()` - Returns directory name (for runner scripts)
- `get_script_dir()` - Returns script directory path

**lib/util.sh**:
- `clone <repo_url> <source_dir> [recurse] [tag]` - Git clone with update logic
- `install_deps <packages>` - Install apt packages non-interactively

### Common Patterns

1. **Function-based execution**: Scripts use functions for each stage (InstallDeps, Fetch, Build, etc.) and can be called individually via command-line argument

2. **Version handling**: 
   - Hardcoded versions for stable releases
   - Dynamic version detection via web scraping (e.g., MAME)
   - Git tag/branch based versions

3. **Source management**:
   - Git repositories: Use `clone()` function
   - SVN repositories: Direct `svn checkout`/`svn up`
   - Release tarballs: `wget` + `tar` extraction

4. **Build systems**:
   - Autoconf: `./configure && make`
   - CMake: `cmake && make`
   - Make: Direct `make`
   - Meson: `meson && ninja`

5. **Packaging**:
   - Output: `.tar.xz` or `.tar.gz` archives
   - Destination: `/builds/runners/{name}/` or `/builds/games/{name}/`
   - Architecture suffix: `-{version}-{arch}.tar.xz`

## Wine Build Specifics

The Wine build script (`runners/wine/build.sh`) is the most complex:

**Usage**:
```bash
./build.sh --as <build_name> --version <version> --with <repo_url> --branch <branch>
```

**Example**:
```bash
./build.sh --as lutris-GE --version 8.0 --with https://github.com/GloriousEggroll/proton-wine --branch Proton8-15
```

**Special Features**:
- Dual-architecture build (32-bit and 64-bit)
- Mingw cross-compilation
- Runtime library integration
- Wine Gecko and Mono inclusion
- Extensive dependency configuration

## Runtime Build

The runtime (`runtime/`) builds the Steam Runtime base with Lutris-specific additions:

**Key Files**:
- `runtime/build.sh` - Main build script
- `runtime/lutrisrt.py` - Python runtime builder
- `runtime/extra/` - Additional libraries not in Steam Runtime

**Output**: `{distro}-{version}-{arch}.tar.xz`

## Tools

Packaging scripts for third-party tools:
- `tools/gogdl/package.sh` - Package GOG downloader from Heroic releases
- `tools/vkd3d/package.sh` - Package vkd3d-proton
- `tools/innoextract/` - InnoSetup extractor
- `tools/p7zip/` - 7zip archiver
- `tools/winetricks/` - Winetricks utility

## Code Conventions

1. **Shebang**: Always `#!/bin/bash`
2. **Error handling**: `set -e` at script start
3. **Paths**: Use absolute paths via `readlink -f` or `$(pwd)`
4. **Libraries**: Source from `../../lib/` relative to script location
5. **Architecture**: Use `$(uname -m)` for architecture detection
6. **Parallel builds**: Use `-j$(nproc)` for make commands
7. **Stripping**: Strip binaries with `strip --strip-unneeded` for release builds
8. **Cleanup**: Most scripts include cleanup functions to remove build artifacts

## Dependencies

**System-level** (installed via setup-buildbot.sh):
- Build tools: gcc, make, cmake, autoconf, etc.
- Wine build dependencies: Extensive list of dev libraries
- Multimedia: GStreamer, SDL2, PulseAudio
- Graphics: Vulkan, OpenGL, Mesa

**Build-time dependencies**:
- ccache for compilation caching
- Python 3 for runtime building
- Various VCS tools: git, svn

## Build Artifacts

Builds follow this structure:
```
builds/
├── games/
│   └── {game_name}/{game_name}-{version}-{arch}.tar.xz
├── runners/
│   └── {runner_name}/{runner_name}-{version}-{arch}.tar.xz
└── runtime/
    └── {distro}-{version}-{arch}/{distro}-{version}-{arch}.tar.xz
```

## Testing and Verification

This project does not have automated test suites. Verification is manual:
- Build scripts should complete without errors
- Generated archives should be valid tar.xz/tar.gz files
- Manual testing of built binaries is expected

## Adding New Builds

When adding a new runner or game:

1. Create directory in `runners/{name}/` or `games/{name}/`
2. Create `build.sh` following the standard pattern
3. Source the library functions from `../../lib/`
4. Implement functions: InstallDeps, Fetch, Build, Install, Package, Clean
5. Test in Docker container or Vagrant VM
6. Ensure output goes to correct `publish_dir`

## Important Notes

- The buildbot no longer auto-uploads to Lutris servers
- Manual upload of build artifacts is required
- Use proper architecture detection for cross-platform compatibility
- Wine builds require special dual-architecture handling
- Some builds require specific SDL compatibility layers (e.g., sdl12-compat)
- Runtime libraries are integrated into Wine builds automatically

## Common Issues

- **Wine build failures**: Often due to missing dependencies or inotify warnings (can be ignored)
- **SDL compatibility**: Older games may need sdl12-compat
- **Library bundling**: Some games require bundling shared libraries (see freesynd example)
- **SVN sources**: Some projects still use SVN instead of Git
