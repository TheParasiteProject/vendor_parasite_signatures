CERTIFICATE_DIRECTORY_ROOT ?= vendor/parasite/signatures
CERTIFICATE_COMMON := $(CERTIFICATE_DIRECTORY_ROOT)/common

ifeq ($(TARGET_BUILD_FULLY_SIGN),true)
$(call inherit-product, $(CERTIFICATE_COMMON)/certificates.mk)
endif
