#!/usr/bin/awk -f
BEGIN {
	# Determines whether to print 'Unreleased' banner at top
	UNRELEASED_COMMITS = 1
	# Prefixes that determine whether a commit will be printed
	CHANGELOG_REGEX = "^(changelog|fix|docs|chore|feat): "
	FS="|"
	while ("git log --pretty='%D|%s|%H'" | getline) {
		IS_GIT_TAG = length($1) && match($1, /tag:/)
		if (IS_GIT_TAG) {
			UNRELEASED_COMMITS = 0
			# Cut out text up to tag
			sub(/.*tag: /, "", $1)
			# Cut out text after tag
			sub(/,.*/, "", $1)
			print $1 
		} else {
			if ( UNRELEASED_COMMITS ) {
				print "Unreleased"
				UNRELEASED_COMMITS = 0
			}
			if ( match($2, CHANGELOG_REGEX) ) {
				sub(CHANGELOG_REGEX, "", $2)
				printf("\t- %s\n", $2)
			}
		}

	}
}
