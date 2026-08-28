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
VMIMPORT_ROLE ?= vmimport
AMI_LICENSE_TYPE ?= BYOL
AMI_IMPORT_POLL_INTERVAL ?= 30
DELETE_AFTER_IMPORT ?= yes

VAULT_IMAGE ?= localhost/fedora-bootc-vault:latest
VAULT_DIR ?= $(CURDIR)/images/vault
VAULT_QCOW2 ?= $(OUTPUT_DIR)/vault.qcow2
VAULT_RAW ?= $(OUTPUT_DIR)/vault.raw
VAULT_S3_KEY ?= $(notdir $(VAULT_RAW))
VAULT_AMI_NAME ?= vault

NOMAD_SERVER_IMAGE ?= localhost/fedora-bootc-nomad-server:latest
NOMAD_SERVER_DIR ?= $(CURDIR)/images/nomad-server
NOMAD_SERVER_QCOW2 ?= $(OUTPUT_DIR)/nomad-server.qcow2
NOMAD_SERVER_RAW ?= $(OUTPUT_DIR)/nomad-server.raw
NOMAD_SERVER_S3_KEY ?= $(notdir $(NOMAD_SERVER_RAW))
NOMAD_SERVER_AMI_NAME ?= nomad-server

NOMAD_CLIENT_IMAGE ?= localhost/fedora-bootc-nomad-client:latest
NOMAD_CLIENT_DIR ?= $(CURDIR)/images/nomad-client
NOMAD_CLIENT_QCOW2 ?= $(OUTPUT_DIR)/nomad-client.qcow2
NOMAD_CLIENT_RAW ?= $(OUTPUT_DIR)/nomad-client.raw
NOMAD_CLIENT_S3_KEY ?= $(notdir $(NOMAD_CLIENT_RAW))
NOMAD_CLIENT_AMI_NAME ?= nomad-client

ifneq ($(wildcard $(CONFIG)),)
CONFIG_MOUNT := -v $(CONFIG):/config.toml:ro
endif

IMAGE_TARGETS := vault-image nomad-server-image nomad-client-image
QCOW2_TARGETS := vault-qcow2 nomad-server-qcow2 nomad-client-qcow2
RAW_TARGETS := vault-raw nomad-server-raw nomad-client-raw
UPLOAD_TARGETS := vault-upload nomad-server-upload nomad-client-upload
AMI_TARGETS := vault-ami nomad-server-ami nomad-client-ami
DISK_TARGETS := $(QCOW2_TARGETS) $(RAW_TARGETS)

.PHONY: vault nomad-server nomad-client $(IMAGE_TARGETS) $(DISK_TARGETS) $(UPLOAD_TARGETS) $(AMI_TARGETS) help

vault: vault-image vault-qcow2
nomad-server: nomad-server-image nomad-server-qcow2
nomad-client: nomad-client-image nomad-client-qcow2

# Map each component's public variables onto the shared recipes below.
define COMPONENT
$(1)-image $(1)-qcow2 $(1)-raw: BUILD_IMAGE := $($(2)_IMAGE)
$(1)-image: IMAGE_DIR := $($(2)_DIR)
$(1)-qcow2: DISK_TYPE := qcow2
$(1)-qcow2: ARTIFACT_SOURCE := $(OUTPUT_DIR)/qcow2/disk.qcow2
$(1)-qcow2: DISK_OUTPUT := $($(2)_QCOW2)
$(1)-raw: DISK_TYPE := raw
$(1)-raw: ARTIFACT_SOURCE := $(OUTPUT_DIR)/image/disk.raw
$(1)-raw: DISK_OUTPUT := $($(2)_RAW)
$(1)-upload: RAW_OUTPUT := $($(2)_RAW)
$(1)-upload $(1)-ami: S3_KEY := $($(2)_S3_KEY)
$(1)-ami: AMI_NAME := $($(2)_AMI_NAME)
$(1)-upload: $(1)-raw
$(1)-ami: $(1)-upload
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

$(UPLOAD_TARGETS):
	@test -n "$(S3_BUCKET)" || { \
		echo "Unable to read bootc_images_bucket_id from $(TF_BASE_DIR); set S3_BUCKET explicitly." >&2; \
		exit 1; \
	}
	$(AWS) s3 cp $(RAW_OUTPUT) s3://$(S3_BUCKET)/$(S3_KEY)
	@echo "RAW disk uploaded to s3://$(S3_BUCKET)/$(S3_KEY)"

$(AMI_TARGETS):
	@set -eu; \
	test -n "$(S3_BUCKET)" || { \
		echo "Unable to read bootc_images_bucket_id from $(TF_BASE_DIR); set S3_BUCKET explicitly." >&2; \
	exit 1; \
	}; \
	task_id="$$($(AWS) ec2 import-image \
		--description "$(AMI_NAME)" \
		--platform Linux \
		--license-type $(AMI_LICENSE_TYPE) \
		--role-name $(VMIMPORT_ROLE) \
		--disk-containers "Format=RAW,UserBucket={S3Bucket=$(S3_BUCKET),S3Key=$(S3_KEY)}" \
		--tag-specifications "ResourceType=import-image-task,Tags=[{Key=Name,Value=$(AMI_NAME)}]" \
		--query ImportTaskId \
		--output text)"; \
	echo "AMI import started: $$task_id"; \
	while :; do \
		status="$$($(AWS) ec2 describe-import-image-tasks \
			--import-task-ids "$$task_id" \
			--query 'ImportImageTasks[0].Status' \
			--output text)"; \
		case "$$status" in \
			completed) break ;; \
			error|cancelled|canceled|deleted) \
				echo "AMI import $$task_id failed with status: $$status" >&2; \
				exit 1 ;; \
			*) \
				echo "AMI import $$task_id status: $$status; checking again in $(AMI_IMPORT_POLL_INTERVAL)s"; \
				sleep $(AMI_IMPORT_POLL_INTERVAL) ;; \
		esac; \
	done; \
	image_id="$$($(AWS) ec2 describe-import-image-tasks \
		--import-task-ids "$$task_id" \
		--query 'ImportImageTasks[0].ImageId' \
		--output text)"; \
	echo "AMI import completed: $$image_id"; \
	if test "$(DELETE_AFTER_IMPORT)" = yes; then \
		$(AWS) s3 rm s3://$(S3_BUCKET)/$(S3_KEY); \
		echo "Deleted s3://$(S3_BUCKET)/$(S3_KEY)"; \
	fi

help:
	@printf '%-25s %s\n' \
		'make vault-image' 'Build only the Vault bootc container image' \
		'make vault-qcow2' 'Convert the existing Vault image to QCOW2' \
		'make vault-raw' 'Convert the existing Vault image to RAW' \
		'make vault-upload' 'Build and upload the Vault RAW disk to S3' \
		'make vault-ami' 'Build, upload, and start importing the Vault AMI' \
		'make vault' 'Build the Vault bootc image and QCOW2 disk' \
		'make nomad-server' 'Build the Nomad server image and QCOW2 disk' \
		'make nomad-server-raw' 'Convert the existing Nomad server image to RAW' \
		'make nomad-server-upload' 'Build and upload the Nomad server RAW disk to S3' \
		'make nomad-server-ami' 'Build, upload, and start importing the Nomad server AMI' \
		'make nomad-client' 'Build the Docker-enabled Nomad client image and QCOW2 disk' \
		'make nomad-client-raw' 'Convert the existing Nomad client image to RAW' \
		'make nomad-client-upload' 'Build and upload the Nomad client RAW disk to S3' \
		'make nomad-client-ami' 'Build, upload, and start importing the Nomad client AMI'
	@echo
	@echo "All settings can be overridden on the command line (for example, make vault-image SUDO=)."
	@echo "Common: SUDO, PODMAN, AWS, TOFU, BUILDER_IMAGE, ROOTFS, OUTPUT_DIR, CONFIG"
	@echo "AWS: TF_BASE_DIR, S3_BUCKET, VMIMPORT_ROLE, AMI_LICENSE_TYPE, AMI_IMPORT_POLL_INTERVAL, DELETE_AFTER_IMPORT"
	@echo "AMI targets wait for completion and delete the uploaded RAW by default; use DELETE_AFTER_IMPORT=no to retain it."
	@echo "Vault: VAULT_IMAGE, VAULT_DIR, VAULT_QCOW2, VAULT_RAW, VAULT_S3_KEY, VAULT_AMI_NAME"
	@echo "Nomad server: NOMAD_SERVER_IMAGE, NOMAD_SERVER_DIR, NOMAD_SERVER_QCOW2, NOMAD_SERVER_RAW, NOMAD_SERVER_S3_KEY, NOMAD_SERVER_AMI_NAME"
	@echo "Nomad client: NOMAD_CLIENT_IMAGE, NOMAD_CLIENT_DIR, NOMAD_CLIENT_QCOW2, NOMAD_CLIENT_RAW, NOMAD_CLIENT_S3_KEY, NOMAD_CLIENT_AMI_NAME"
