SUDO ?= sudo
PODMAN ?= podman

IMAGE ?= localhost/fedora-bootc-vault:latest
BUILDER_IMAGE ?= quay.io/centos-bootc/bootc-image-builder:latest
ROOTFS ?= ext4
VAULT_DIR ?= $(CURDIR)/images/vault
OUTPUT_DIR ?= $(CURDIR)/output
QCOW2_FILE ?= $(OUTPUT_DIR)/vault.qcow2
CONFIG ?= $(CURDIR)/config.toml

ifneq ($(wildcard $(CONFIG)),)
CONFIG_MOUNT := -v $(CONFIG):/config.toml:ro
else
CONFIG_MOUNT :=
endif

.PHONY: vault image qcow2 help

vault: image qcow2

image:
	$(SUDO) $(PODMAN) build \
		-t $(IMAGE) \
		-f $(VAULT_DIR)/Containerfile \
		$(VAULT_DIR)

qcow2:
	@mkdir -p $(OUTPUT_DIR)
	@if test ! -f "$(CONFIG)"; then \
		echo "Warning: $(CONFIG) not found; no login user will be injected."; \
	fi
	$(SUDO) $(PODMAN) run --rm -it \
		--privileged \
		--pull=newer \
		--security-opt label=type:unconfined_t \
		$(CONFIG_MOUNT) \
		-v $(OUTPUT_DIR):/output \
		-v /var/lib/containers/storage:/var/lib/containers/storage \
		$(BUILDER_IMAGE) \
		--type qcow2 \
		--rootfs $(ROOTFS) \
		$(IMAGE)
	$(SUDO) mv -f $(OUTPUT_DIR)/qcow2/disk.qcow2 $(QCOW2_FILE)
	$(SUDO) chown -R $$(id -u):$$(id -g) $(OUTPUT_DIR)
	@echo "QCOW2 created at $(QCOW2_FILE)"

help:
	@echo "make vault   Build the Vault bootc image and QCOW2 disk"
	@echo "make image   Build only the bootc container image"
	@echo "make qcow2   Convert the existing rootful image to QCOW2"
	@echo ""
	@echo "Optional: IMAGE, BUILDER_IMAGE, ROOTFS, VAULT_DIR, OUTPUT_DIR, QCOW2_FILE, CONFIG"
