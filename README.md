# vendor_parasite-signatures

```bash
croot && git clone https://github.com/TheParasiteProject/vendor_parasite-signatures vendor/parasite-signatures
```

```bash
cd vendor/parasite-signatures
```

```bash
./generate.sh
```

* Keys will be generated under `../private-signatures`
* To signing avb, in your device tree's BoardConfig.mk

```makefile
TARGET_BUILD_FULLY_SIGN := true
include vendor/parasite-signatures/BoardConfigSign.mk

TARGET_AVB_KEY_PATH := $(PARASITE_AVB_KEY_PATH)
TARGET_AVB_ALGORITHM := $(PARASITE_AVB_ALGORITHM)

BOARD_AVB_KEY_PATH := $(TARGET_AVB_KEY_PATH)
BOARD_AVB_ALGORITHM :=  $(TARGET_AVB_ALGORITHM)

(...)

BOARD_AVB_VENDOR_BOOT_KEY_PATH := $(TARGET_AVB_KEY_PATH)
BOARD_AVB_VENDOR_BOOT_ALGORITHM := $(TARGET_AVB_ALGORITHM)
```

## References

* [Sign builds for release](https://source.android.com/docs/core/ota/sign_builds) - from source.android.com
* [Generating Keys](https://github.com/chenxiaolong/avbroot?tab=readme-ov-file#generating-keys) - from avbroot readme
* make_key script is taken from development/tools/make_key and modified

## Credits

* [vendor_evolution-priv_keys-template](https://github.com/Evolution-XYZ/vendor_evolution-priv_keys-template) - from Evolution-XYZ
