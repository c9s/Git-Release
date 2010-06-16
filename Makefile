
FILES= \
	bin/git-new-repo \
	bin/git-release-ready \
	bin/git-release-tag \
	bin/git-released

install:
		cp -v $(FILES) /usr/bin/
