.DEFAULT = help

APP_DIR_NAME	?= $(notdir $(shell pwd))
SPLUNK_HOME ?= /Users/$($USER)/splunk
OUT_DIR		?= out
BUILD_DIR ?= out/app
PACKAGES_DIR               = $(OUT_DIR)/packages
PACKAGES_SPLUNK_BASE_DIR   = $(PACKAGES_DIR)/splunkbase
PACKAGES_SPLUNK_SEMVER_DIR = $(PACKAGES_DIR)/splunksemver
PACKAGES_SPLUNK_SLIM_DIR   = $(PACKAGES_DIR)/splunkslim
PACKAGES_DIR_SPLUNK_DEPS   = $(PACKAGES_DIR)/splunk_deps
PACKAGE_DIRS = $(PACKAGES_DIR) $(PACKAGES_SPLUNK_BASE_DIR) $(PACKAGES_SPLUNK_SEMVER_DIR) $(PACKAGES_SPLUNK_SLIM_DIR) $(PACKAGES_DIR_SPLUNK_DEPS)
ALL_DIRS = $(OUT_DIR) $(BUILD_DIR)  $(PACKAGE_DIRS)


RELEASE            = $(shell gitversion /showvariable FullSemVer)
BUILD_NUMBER      ?= 0000
COMMIT_ID         ?= $(shell git rev-parse --short HEAD)
BRANCH            ?= $(shell git branch | grep \* | cut -d ' ' -f2)
VERSION            = $(shell gitversion /showvariable FullSemVer)
PACKAGE_SLUG       =
PACKAGE_VERSION    = $(VERSION)
APP_VERSION        = $(VERSION)

VERSION=$(shell gitversion /showvariable MajorMinorPatch)

PACKAGE_SLUG=D$(COMMIT_ID)
ifneq (,$(findstring $(BRANCH),"master"))
	PACKAGE_SLUG=R$(COMMIT_ID)
endif

PACKAGE_VERSION=$(VERSION)-$(PACKAGE_SLUG)
APP_VERSION=$(VERSION)$(PACKAGE_SLUG)

help: ## Show this help message.
	@echo 'usage: make [target] ...'
	@echo
	@echo 'targets:'
	@egrep '^(.+)\:\ ##\ (.+)' $(MAKEFILE_LIST) | column -t -c 2 -s ':#' | sed 's/^/  /'

remote-test:
	@echo cleaning deployed app in GCP
	gcloud beta compute ssh --zone "us-west1-b" "splunk-es"  --tunnel-through-iap --project "rarsan-splunkconf20" --command="/home/wahmad/splunk_clean_app.sh"
	@echo copying app src to Splunk in GCP $(SPLUNK_HOME)
	gcloud beta compute scp --zone "us-west1-b" "../$(APP_DIR_NAME)"  wahmad@"splunk-es":/home/wahmad/  --tunnel-through-iap --project "rarsan-splunkconf20" --recurse
	gcloud beta compute ssh --zone "us-west1-b" "splunk-es"  --tunnel-through-iap --project "rarsan-splunkconf20" --command="sudo chown -R splunk:splunk /home/wahmad/$(APP_DIR_NAME)"
	gcloud beta compute ssh --zone "us-west1-b" "splunk-es"  --tunnel-through-iap --project "rarsan-splunkconf20" --command="sudo mv /home/wahmad/$(APP_DIR_NAME) /opt/splunk/etc/apps/"
	@echo don\'t forget to refresh Splunk

package: ## Package Splunk app
package: build
	@echo about to package $(PACKAGES_SPLUNK_BASE_DIR)/$(APP_DIR_NAME)-$(PACKAGE_VERSION).tar.gz
	slim package -o $(PACKAGES_SPLUNK_BASE_DIR) $(BUILD_DIR)/$(APP_DIR_NAME)
