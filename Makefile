SUDO ?= sudo
PODMAN ?= podman
AWS ?= aws
TOFU ?= tofu

BUILDER_IMAGE ?= quay.io/centos-bootc/bootc-image-builder:latest
ROOTFS ?= ext4
OUTPUT_DIR ?= $(CURDIR)/output
CONFIG ?= $(CURDIR)/config.toml
TF_BASE_DIR ?= $(CURDIR)/terraform/bundles/base
S3_BUCKET ?= $(shell $(TOFU) -chdir=$(TF_BASE_DIR) output -raw bootc_images_bucket_id 2>/dev/null)
AWS_REGION ?= $(or $(AWS_DEFAULT_REGION),$(shell $(AWS) configure get region 2>/dev/null))
AMI_DATE ?= $(shell date +%Y%m%d)

VAULT_IMAGE ?= localhost/fedora-bootc-vault:latest
VAULT_DIR ?= $(CURDIR)/images/vault
VAULT_QCOW2 ?= $(OUTPUT_DIR)/vault.qcow2
VAULT_RAW ?= $(OUTPUT_DIR)/vault.raw
VAULT_AMI_NAME ?= vault

NOMAD_SERVER_IMAGE ?= localhost/fedora-bootc-nomad-server:latest
NOMAD_SERVER_DIR ?= $(CURDIR)/images/nomad-server
NOMAD_SERVER_QCOW2 ?= $(OUTPUT_DIR)/nomad-server.qcow2
NOMAD_SERVER_RAW ?= $(OUTPUT_DIR)/nomad-server.raw
NOMAD_SERVER_AMI_NAME ?= nomad-server

NOMAD_CLIENT_IMAGE ?= localhost/fedora-bootc-nomad-client:latest
NOMAD_CLIENT_DIR ?= $(CURDIR)/images/nomad-client
NOMAD_CLIENT_QCOW2 ?= $(OUTPUT_DIR)/nomad-client.qcow2
NOMAD_CLIENT_RAW ?= $(OUTPUT_DIR)/nomad-client.raw
NOMAD_CLIENT_AMI_NAME ?= nomad-client

ifneq ($(wildcard $(CONFIG)),)
CONFIG_MOUNT := -v $(CONFIG):/config.toml:ro
endif

IMAGE_TARGETS := vault-image nomad-server-image nomad-client-image
QCOW2_TARGETS := vault-qcow2 nomad-server-qcow2 nomad-client-qcow2
RAW_TARGETS := vault-raw nomad-server-raw nomad-client-raw
AMI_TARGETS := vault-ami nomad-server-ami nomad-client-ami
DISK_TARGETS := $(QCOW2_TARGETS) $(RAW_TARGETS)

.PHONY: vault nomad-server nomad-client $(IMAGE_TARGETS) $(DISK_TARGETS) $(AMI_TARGETS) help

vault: vault-image vault-qcow2
nomad-server: nomad-server-image nomad-server-qcow2
nomad-client: nomad-client-image nomad-client-qcow2

# Map each component's public variables onto the shared recipes below.
define COMPONENT
$(1)-image $(1)-qcow2 $(1)-raw $(1)-ami: BUILD_IMAGE := $($(2)_IMAGE)
$(1)-image: IMAGE_DIR := $($(2)_DIR)
$(1)-qcow2: DISK_TYPE := qcow2
$(1)-qcow2: ARTIFACT_SOURCE := $(OUTPUT_DIR)/qcow2/disk.qcow2
$(1)-qcow2: DISK_OUTPUT := $($(2)_QCOW2)
$(1)-raw: DISK_TYPE := raw
$(1)-raw: ARTIFACT_SOURCE := $(OUTPUT_DIR)/image/disk.raw
$(1)-raw: DISK_OUTPUT := $($(2)_RAW)
$(1)-ami: AMI_NAME := $($(2)_AMI_NAME)$(if $(AMI_DATE),-$(AMI_DATE))
$(1)-ami: $(1)-image
endef

$(eval $(call COMPONENT,vault,VAULT))
$(eval $(call COMPONENT,nomad-server,NOMAD_SERVER))
$(eval $(call COMPONENT,nomad-client,NOMAD_CLIENT))

$(IMAGE_TARGETS):
	$(SUDO) $(PODMAN) build \
		-t $(BUILD_IMAGE) \
		-f $(IMAGE_DIR)/Containerfile \
		$(IMAGE_DIR)

$(DISK_TARGETS):
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
		--type $(DISK_TYPE) \
		--rootfs $(ROOTFS) \
		$(BUILD_IMAGE)
	$(SUDO) mv -f $(ARTIFACT_SOURCE) $(DISK_OUTPUT)
	$(SUDO) chown -R $$(id -u):$$(id -g) $(OUTPUT_DIR)
	@echo "$(DISK_TYPE) disk created at $(DISK_OUTPUT)"

$(AMI_TARGETS):
	@set -eu; \
	test -n "$(S3_BUCKET)" || { \
		echo "Unable to read bootc_images_bucket_id from $(TF_BASE_DIR); set S3_BUCKET explicitly." >&2; \
		exit 1; \
	}; \
	test -n "$(AWS_REGION)" || { \
		echo "Unable to determine the AWS Region; set AWS_REGION explicitly." >&2; \
		exit 1; \
	}; \
	if test ! -f "$(CONFIG)"; then \
		echo "Warning: $(CONFIG) not found; no login user will be injected."; \
	fi; \
	credentials_file="$$(mktemp)"; \
	trap 'rm -f "$$credentials_file"' EXIT; \
	if ! $(AWS) configure export-credentials --format env-no-export > "$$credentials_file"; then \
		echo "Unable to obtain AWS credentials; configure AWS credentials or run 'aws login'." >&2; \
		exit 1; \
	fi; \
	echo "Building and uploading $(AMI_NAME) AMI with bootc-image-builder..."; \
	$(SUDO) $(PODMAN) run --rm -it \
		--privileged \
		--network=host \
		--pull=newer \
		--security-opt label=type:unconfined_t \
		$(CONFIG_MOUNT) \
		--env-file "$$credentials_file" \
		-v $(OUTPUT_DIR):/output \
		-v /var/lib/containers/storage:/var/lib/containers/storage \
		$(BUILDER_IMAGE) \
		--type ami \
		--rootfs $(ROOTFS) \
		--aws-ami-name "$(AMI_NAME)" \
		--aws-bucket "$(S3_BUCKET)" \
		--aws-region "$(AWS_REGION)" \
		$(BUILD_IMAGE)

help:
	@printf '%-25s %s\n' \
		'make vault-image' 'Build only the Vault bootc container image' \
		'make vault-qcow2' 'Convert the existing Vault image to QCOW2' \
		'make vault-raw' 'Convert the existing Vault image to RAW' \
		'make vault-ami' 'Build and upload the Vault AMI with bootc-image-builder' \
		'make vault' 'Build the Vault bootc image and QCOW2 disk' \
		'make nomad-server' 'Build the Nomad server image and QCOW2 disk' \
		'make nomad-server-raw' 'Convert the existing Nomad server image to RAW' \
		'make nomad-server-ami' 'Build and upload the Nomad server AMI with bootc-image-builder' \
		'make nomad-client' 'Build the Docker-enabled Nomad client image and QCOW2 disk' \
		'make nomad-client-raw' 'Convert the existing Nomad client image to RAW' \
		'make nomad-client-ami' 'Build and upload the Nomad client AMI with bootc-image-builder'
	@echo
	@echo "All settings can be overridden on the command line (for example, make vault-image SUDO=)."
	@echo "Common: SUDO, PODMAN, AWS, TOFU, BUILDER_IMAGE, ROOTFS, OUTPUT_DIR, CONFIG"
	@echo "AWS: TF_BASE_DIR, S3_BUCKET, AWS_REGION, AMI_DATE"
	@echo "AMI targets use bootc-image-builder's native AWS uploader; the bucket is used for intermediate storage."
	@echo "Vault: VAULT_IMAGE, VAULT_DIR, VAULT_QCOW2, VAULT_RAW, VAULT_AMI_NAME"
	@echo "Nomad server: NOMAD_SERVER_IMAGE, NOMAD_SERVER_DIR, NOMAD_SERVER_QCOW2, NOMAD_SERVER_RAW, NOMAD_SERVER_AMI_NAME"
	@echo "Nomad client: NOMAD_CLIENT_IMAGE, NOMAD_CLIENT_DIR, NOMAD_CLIENT_QCOW2, NOMAD_CLIENT_RAW, NOMAD_CLIENT_AMI_NAME"
