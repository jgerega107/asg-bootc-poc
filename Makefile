SUDO ?= sudo
PODMAN ?= podman

IMAGE ?= localhost/fedora-bootc-vault:latest
BUILDER_IMAGE ?= quay.io/centos-bootc/bootc-image-builder:latest
ROOTFS ?= ext4
VAULT_DIR ?= $(CURDIR)/images/vault
OUTPUT_DIR ?= $(CURDIR)/output
QCOW2_FILE ?= $(OUTPUT_DIR)/vault.qcow2
NOMAD_SERVER_IMAGE ?= localhost/fedora-bootc-nomad-server:latest
NOMAD_CLIENT_IMAGE ?= localhost/fedora-bootc-nomad-client:latest
NOMAD_SERVER_DIR ?= $(CURDIR)/images/nomad-server
NOMAD_CLIENT_DIR ?= $(CURDIR)/images/nomad-client
NOMAD_SERVER_QCOW2 ?= $(OUTPUT_DIR)/nomad-server.qcow2
NOMAD_CLIENT_QCOW2 ?= $(OUTPUT_DIR)/nomad-client.qcow2
CONFIG ?= $(CURDIR)/config.toml

ifneq ($(wildcard $(CONFIG)),)
CONFIG_MOUNT := -v $(CONFIG):/config.toml:ro
else
CONFIG_MOUNT :=
endif

.PHONY: vault image qcow2 nomad-server nomad-server-image nomad-server-qcow2 nomad-client nomad-client-image nomad-client-qcow2 help

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

nomad-server: nomad-server-image nomad-server-qcow2

nomad-server-image:
	$(SUDO) $(PODMAN) build \
		-t $(NOMAD_SERVER_IMAGE) \
		-f $(NOMAD_SERVER_DIR)/Containerfile \
		$(NOMAD_SERVER_DIR)

nomad-server-qcow2:
	@mkdir -p $(OUTPUT_DIR)
	$(SUDO) $(PODMAN) run --rm -it \
		--privileged \
		--pull=newer \
		--security-opt label=type:unconfined_t \
		$(CONFIG_MOUNT) \
		-v $(OUTPUT_DIR):/output \
		-v /var/lib/containers/storage:/var/lib/containers/storage \
		$(BUILDER_IMAGE) \
		--type qcow2 --rootfs $(ROOTFS) \
		$(NOMAD_SERVER_IMAGE)
	$(SUDO) mv -f $(OUTPUT_DIR)/qcow2/disk.qcow2 $(NOMAD_SERVER_QCOW2)
	$(SUDO) chown -R $$(id -u):$$(id -g) $(OUTPUT_DIR)
	@echo "QCOW2 created at $(NOMAD_SERVER_QCOW2)"

nomad-client: nomad-client-image nomad-client-qcow2

nomad-client-image:
	$(SUDO) $(PODMAN) build \
		-t $(NOMAD_CLIENT_IMAGE) \
		-f $(NOMAD_CLIENT_DIR)/Containerfile \
		$(NOMAD_CLIENT_DIR)

nomad-client-qcow2:
	@mkdir -p $(OUTPUT_DIR)
	$(SUDO) $(PODMAN) run --rm -it \
		--privileged \
		--pull=newer \
		--security-opt label=type:unconfined_t \
		$(CONFIG_MOUNT) \
		-v $(OUTPUT_DIR):/output \
		-v /var/lib/containers/storage:/var/lib/containers/storage \
		$(BUILDER_IMAGE) \
		--type qcow2 --rootfs $(ROOTFS) \
		$(NOMAD_CLIENT_IMAGE)
	$(SUDO) mv -f $(OUTPUT_DIR)/qcow2/disk.qcow2 $(NOMAD_CLIENT_QCOW2)
	$(SUDO) chown -R $$(id -u):$$(id -g) $(OUTPUT_DIR)
	@echo "QCOW2 created at $(NOMAD_CLIENT_QCOW2)"

help:
	@echo "make vault   Build the Vault bootc image and QCOW2 disk"
	@echo "make image   Build only the bootc container image"
	@echo "make qcow2   Convert the existing rootful image to QCOW2"
	@echo "make nomad-server  Build the Nomad server image and QCOW2"
	@echo "make nomad-client  Build the Docker-enabled Nomad client image and QCOW2"
	@echo ""
	@echo "Optional: IMAGE, BUILDER_IMAGE, ROOTFS, VAULT_DIR, OUTPUT_DIR, QCOW2_FILE, CONFIG"
