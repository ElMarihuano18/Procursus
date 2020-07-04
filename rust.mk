ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

#SUBPROJECTS += rust
RUST_VERSION := 1.45.0
DEB_RUST_V   ?= $(RUST_VERSION)-nightly

ifeq ($(MEMO_TARGET),iphoneos-arm64)
RUST_TARGET := aarch64-apple-ios
else ifeq ($(MEMO_TARGET),iphoneos-arm)
RUST_TARGET := armv7-apple-ios
endif

# This needs ccache extra to build.

rust-setup: setup
	if [ ! -d "$(BUILD_WORK)/rust" ]; then \
		git clone https://github.com/rust-lang/rust $(BUILD_WORK)/rust; \
		cd "$(BUILD_WORK)/rust"; \
		git fetch origin; \
		git reset --hard origin/master; \
		git checkout HEAD .; \
	fi
	# Change the above mess when the necessary iOS changes are added to upstream.
	
	mkdir -p "$(BUILD_WORK)/rust/build"
	mkdir -p "$(BUILD_STAGE)/rust"
	cp -f "$(BUILD_INFO)/rust_config.toml" "$(BUILD_WORK)/rust/config.toml"

	$(SED) -i -e 's|PROCURSUS_BUILD_DIR|$(BUILD_WORK)/rust/build|g' -e 's|PROCURSUS_TARGET|$(RUST_TARGET)|g' -e 's|PROCURSUS_INSTALL_PREFIX|$(BUILD_STAGE)/rust/usr|g' "$(BUILD_WORK)/rust/config.toml"
	#$(SED) -i -e 's/"LLVM_ENABLE_ZLIB", "OFF"/"LLVM_ENABLE_ZLIB", "ON"/' -e 's|"CMAKE_OSX_SYSROOT", "/"|"CMAKE_OSX_SYSROOT", "$(TARGET_SYSROOT)"|' "$(BUILD_WORK)/rust/src/bootstrap/native.rs"

	@echo "*********** This is one of the only targets that will stay blank for up to many hours while building. It's working, trust me! ***********"

ifneq ($(wildcard $(BUILD_WORK)/rust/.build_complete),)
rust:
	@echo "Using previously built rust."
else
rust: rust-setup openssl curl
	mv $(BUILD_BASE)/usr/include/stdlib.h $(BUILD_BASE)/usr/include/stdlib.h.old
	unset CFLAGS CXXFLAGS CPPFLAGS LDFLAGS; \
		cd "$(BUILD_WORK)/rust"; \
		export MACOSX_DEPLOYMENT_TARGET=10.13 \
		IPHONEOS_DEPLOYMENT_TARGET=10.0 \
		AARCH64_APPLE_IOS_OPENSSL_DIR="$(BUILD_BASE)/usr"; \
		ARMV7_APPLE_IOS_OPENSSL_DIR="$(BUILD_BASE)/usr"; \
		./x.py build; \
		./x.py install
	mv $(BUILD_BASE)/usr/include/stdlib.h.old $(BUILD_BASE)/usr/include/stdlib.h
	rm -rf $(BUILD_STAGE)/rust/usr/{share/doc,etc}
	rm -rf $(BUILD_STAGE)/rust/usr/lib/rustlib/{src,manifest-*,components,install.log,uninstall.sh,rust-installer-version}
	rm -rf $(BUILD_STAGE)/rust/usr/lib/rustlib/*/analysis
	touch $(BUILD_WORK)/rust/.build_complete
endif

rust-package:
