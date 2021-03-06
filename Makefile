#
# Makefile for deb builds of baas
#
NODE_VERSION="4.3.1"
DEFAULT_INIT_CONFIG=baas_defaults

build_deb: check-fpm-installed check-version-variable check-deb-variables
	#
	# Accepted variables to be passed
	# WORKSPACE , GIT_URL , VERSION_NUMBER , GIT_BRANCH , GIT_COMMIT
	#
	#trick npm to avoid a commit in git
	mv .git .git-back
	npm version $(VERSION_NUMBER)
	mv .git-back .git

	find . -name ".npmignore" -o -name ".gitignore" -delete

	sed -e 's/{{NODE_VERSION}}/$(NODE_VERSION)/g' debian/$(DEFAULT_INIT_CONFIG).template > debian/$(DEFAULT_INIT_CONFIG)

	fpm -C $(WORKSPACE) --deb-user baas --deb-group baas \
	--before-install debian/pre_install.sh --after-install debian/post_install.sh \
	--before-remove debian/pre_rm.sh \
	--prefix /opt/auth0/baas --deb-upstart debian/baas --deb-default debian/baas_defaults \
	--url ' $(GIT_URL)' --version $(VERSION_NUMBER) -n baas \
	-d auth0-node-v$(NODE_VERSION)-linux-x64 \
	-x '**/.git*' -x '*.tgz' -x '**/test/*' -x 'debian/*.template' \
	--description 'Jenkins build $(VERSION_NUMBER) - git commit $(GIT_BRANCH)-$(GIT_COMMIT)' \
	-t deb -s dir .

	git checkout .

check-version-variable:
ifndef VERSION_NUMBER
		$(error VERSION_NUMBER is undefined)
endif

check-deb-variables:
ifndef WORKSPACE
		$(error WORKSPACE is undefined)
endif


check-fpm-installed:
	@command -v fpm >/dev/null 2>&1 || { echo >&2 "fpm required to build DEBs but not installed"; \
	echo >&2 "Install with: \n $ sudo apt-get install ruby-dev gcc && sudo gem install fpm"; \
	echo >&2 "Aborting"; exit 1; }
