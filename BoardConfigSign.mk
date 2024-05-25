ifeq ($(TARGET_BUILD_FULLY_SIGN),true)
TARGET_AVB_SIGN := true
TARGET_OTA_SIGN := true
endif

ifeq ($(TARGET_AVB_SIGN),true)
PARASITE_AVB_KEY_PATH := vendor/parasite-signatures/common/data/releasekey.pk8
PARASITE_AVB_ALGORITHM := SHA256_RSA2048
endif

ifeq ($(TARGET_OTA_SIGN),true)
PARASITE_OTA_KEY_PATH := vendor/parasite-signatures/common/data/releasekey
endif
