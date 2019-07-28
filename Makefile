
SHELL = /bin/sh
export SHELL

DIR_BUILD := build
FILE_OUTPUT := $(DIR_BUILD)/bootstrap

CMD_BREW := brew bundle exec --

all: $(FILE_OUTPUT)

$(FILE_OUTPUT): build/configure $(GNUPG_FILES_SCRIPTS) | build/
	-rm $(FILE_OUTPUT)

	cat \
		build/configure \
		>> $(FILE_OUTPUT)

	$(CMD_BREW) shfmt -w $(FILE_OUTPUT)

	chmod +x $(FILE_OUTPUT)

build/configure: files/Brewfile | build
	-rm build/configure
	echo "#! /bin/sh" >> build/configure
	echo "" >> build/configure
	echo '/usr/bin/ruby -e "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"' >> build/configure
	echo "cat << EOF | brew bundle install --file=-" >> build/configure
	cat files/Brewfile >> build/configure
	echo "EOF" >> build/configure
	chmod +x build/configure

build/:
	mkdir build/

.PHONY: lint
lint: $(FILE_OUTPUT)
	$(CMD_BREW) shellcheck $(FILE_OUTPUT)

.PHONY: clean
clean:
	-rm -r $(DIR_BUILD)

.PHONY: bump_version
bump_version:
	"$${EDITOR:-$${VISUAL:-vi}}" ./VERSION
	git add ./VERSION
	@git diff --exit-code -s ./VERSION || (echo "version wasn't changed" && exit 1)
	git commit -m "bumped version to $$(cat ./VERSION)"
	git push origin master

.PHONY: release
release: fail_if_stage_dirty $(FILE_OUTPUT) bump_version
	$(CMD_BREW) hub release create \
		-a $(FILE_OUTPUT) \
		-m "v$$(cat ./VERSION)" \
		"v$$(cat ./VERSION)"

.PHONY: fail_if_stage_dirty
fail_if_stage_dirty:
	@git diff --exit-code -s || (echo "unstaged changes, refusing to release" && exit 1)


