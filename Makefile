SUDO ?= sudo
PODMAN ?= podman
AWS ?= aws
TOFU ?= tofu

.DEFAULT_GOAL := help

BUILDER_IMAGE ?= quay.io/centos-bootc/bootc-image-builder:latest
ROOTFS ?= ext4
OUTPUT_DIR ?= $(CURDIR)/output
CONFIG ?= $(CURDIR)/config.toml
TF_BASE_DIR ?= $(CURDIR)/terraform/bundles/base
S3_BUCKET ?=
AWS_REGION ?= $(AWS_DEFAULT_REGION)
AMI_TIMESTAMP ?= $(shell date -u +%Y%m%dT%H%M%SZ)

COMPONENTS := vault nomad-server nomad-client consul-server
IMAGE_TARGETS := $(addsuffix -image,$(COMPONENTS))
QCOW2_TARGETS := $(addsuffix -qcow2,$(COMPONENTS))
AMI_TARGETS := $(addsuffix -ami,$(COMPONENTS))

ifneq ($(wildcard $(CONFIG)),)
CONFIG_MOUNT := -v $(CONFIG):/config.toml:ro
endif

.PHONY: $(IMAGE_TARGETS) $(QCOW2_TARGETS) $(AMI_TARGETS) help

$(IMAGE_TARGETS): %-image:
	$(SUDO) $(PODMAN) build \
		--network=host \
		-t localhost/fedora-bootc-$*:latest \
		-f $(CURDIR)/images/$*/Containerfile \
		$(CURDIR)/images/$*

$(QCOW2_TARGETS): %-qcow2: %-image
	@set -eu; \
	mkdir -p "$(OUTPUT_DIR)"; \
	build_output="$$(mktemp -d "$(OUTPUT_DIR)/.$*.qcow2.XXXXXX")"; \
	trap '$(SUDO) rm -rf -- "$$build_output"' EXIT; \
	if test ! -f "$(CONFIG)"; then \
		echo "Warning: $(CONFIG) not found; no login user will be injected."; \
	fi; \
	$(SUDO) $(PODMAN) run --rm \
		--privileged \
		--pull=newer \
		--security-opt label=type:unconfined_t \
		$(CONFIG_MOUNT) \
		-v "$$build_output:/output" \
		-v /var/lib/containers/storage:/var/lib/containers/storage \
		$(BUILDER_IMAGE) \
		--type qcow2 \
		--rootfs $(ROOTFS) \
		--chown "$$(id -u):$$(id -g)" \
		localhost/fedora-bootc-$*:latest; \
	mv -f "$$build_output/qcow2/disk.qcow2" "$(OUTPUT_DIR)/$*.qcow2"; \
	echo "QCOW2 disk created at $(OUTPUT_DIR)/$*.qcow2"

$(AMI_TARGETS): %-ami: %-image
	@set -eu; \
	s3_bucket="$(S3_BUCKET)"; \
	if test -z "$$s3_bucket"; then \
		if ! $(TOFU) -chdir="$(TF_BASE_DIR)" output -json bootc_images_bucket_id >/dev/null 2>&1; then \
			echo "Unable to read bootc_images_bucket_id from $(TF_BASE_DIR); set S3_BUCKET explicitly." >&2; \
			exit 1; \
		fi; \
		s3_bucket="$$( $(TOFU) -chdir="$(TF_BASE_DIR)" output -raw bootc_images_bucket_id 2>/dev/null)"; \
	fi; \
	aws_region="$(AWS_REGION)"; \
	if test -z "$$aws_region"; then \
		aws_region="$$( $(AWS) configure get region 2>/dev/null || true)"; \
	fi; \
	test -n "$$aws_region" || { \
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
	ami_name="$*$(if $(AMI_TIMESTAMP),-$(AMI_TIMESTAMP))"; \
	echo "Building and uploading $$ami_name AMI with bootc-image-builder..."; \
	$(SUDO) $(PODMAN) run --rm --tty \
		--privileged \
		--network=host \
		--pull=newer \
		--security-opt label=type:unconfined_t \
		$(CONFIG_MOUNT) \
		--env-file "$$credentials_file" \
		-v /var/lib/containers/storage:/var/lib/containers/storage \
		$(BUILDER_IMAGE) \
		--type ami \
		--rootfs $(ROOTFS) \
		--aws-ami-name "$$ami_name" \
		--aws-bucket "$$s3_bucket" \
		--aws-region "$$aws_region" \
		localhost/fedora-bootc-$*:latest

help:
	@printf '%-27s %s\n' \
		'make <component>-image' 'Build only the bootc container image' \
		'make <component>-qcow2' 'Build the container image and a QCOW2 disk' \
		'make <component>-ami' 'Build the container image and upload an AMI' \
		'' '' \
		'Components:' 'vault, nomad-server, nomad-client, consul-server'
	@echo
	@echo "Settings can be overridden on the command line (for example, make vault-image SUDO=)."
	@echo "Common: SUDO, PODMAN, AWS, TOFU, BUILDER_IMAGE, ROOTFS, OUTPUT_DIR, CONFIG"
	@echo "AWS: TF_BASE_DIR, S3_BUCKET, AWS_REGION, AMI_TIMESTAMP"
	@echo "AMI targets use bootc-image-builder's native AWS uploader; the bucket is used for intermediate storage."
