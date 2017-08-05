#!/usr/bin/awk -f
BEGIN {
	REPO_URL = getRepoURL()
	VERSION_IDX = 1

	# Prefixes that determine whether a commit will be printed
	FEATURE_REGEX = "^(feat|feature): "
	FEATURE_IDX = 1
	FEATURE_LABEL = "New Features"

	DOCS_REGEX = "^(changelog|docs): "
	DOCS_IDX = 2
	DOCS_LABEL = "Documentation Changes"

	BUG_FIX_REGEX = "^(fix|hotfix): "
	BUG_FIX_IDX = 3
	BUG_FIX_LABEL = "Bug Fixes"

	UPDATE_REGEX = "^(chore|refactor|update): "
	UPDATE_IDX = 4
	UPDATE_LABEL = "Updates"

	DELIMITER = "---"

	FS="|"
	SINCE = ""
	if ( length(FROM) ) {
		SINCE = FROM "..HEAD"
	}

	# The output array is an n x 5 grid, where n is the number of versions and
	# the five columns correspond to the:
	# - Formatted version - 0
	# - Feature commits (concatenated) - 1
	# - Docs commits (concatenated) - 2
	# - Fix commits (concatenated) - 3
	# - Update commits (concatenated) - 4

	# Init version counter to zero, set first section for unreleased commits.
	TAGS = 1
	OUTPUT[TAGS, 0] = "Pending Changes"

	# Loop through each commit and make a new section if it's a git tag,
	# or else classify commit and add to appropriate index in OUTPUT array.

	# %D: tags
	# %s: commit message
	# %H: long hash
	# %h: short hash
	# %cd: commiter date
	# %an: author name
	while ("git log " SINCE " --date=short --pretty='%D|%s|%H|%h|%cd|%an'" | getline) {

		IS_GIT_TAG = isGitTag($1)

		if (IS_GIT_TAG) {
			TAGS++
			OUTPUT[TAGS, 0] = getTag($1, $5)
		} else {
			classifyCommit($2, $3, $4)
		}
	}

	# Loop over version tags in OUTPUT array...
	for (x = 1; x <= TAGS; x++) {
		
		# Print version tag
		tag = OUTPUT[x,0]
		printTag(tag)
		
		# Loop over category buckets in each version...
		for (bkt = 1; bkt <= 4; bkt++) {
			
			# Deserialize categories/commits for each category
			commits = OUTPUT[x, bkt]
			len = split(commits, separate, DELIMITER)
			
			# Categories are stored in 1st index,
			# so skip them in "old" mode.
			if (MODE == "old") {
				startval = 2
			} else {
				startval = 1
			}

			# Loop over categories/commits in deserialized output...
			for (val = startval; val <= len; val++) {
				
				commit = separate[val]
				if ( length(commit) ) {
					if (val == 1) {
						printCategory(commit)
					} else {
						printCommit(commit)
					}
				}
			}
		}
	}
}

function printTag(msg) {
	if (TYPE == "plain") {
		printf("%s\n", msg)
	} else {
		printf("\n## %s\n", msg)
	}
}

function printCategory(msg) {
	if (MODE == "old") {
	} else {
		if (TYPE == "plain") {
			printf("\t%s\n", msg)
		} else {
			printf("\n#### %s\n", msg)
		}
	}
}

function printCommit(msg) {
	if (TYPE == "plain") {
		if (MODE == "old") {
			printf("\t%s\n", msg)
		} else {
			printf("\t\t%s\n", msg)
		}
	} else {
		if (MODE == "old") {
			printf("%s\n", msg)
		} else {
			printf("%s\n", msg)
		}
	}
}

function isGitTag(input) {
	return length(input) && match(input, /tag:/)
}

function getTag(input, date) {
	# Cut out text up to tag
	sub(/.*tag: /, "", input)
	# Cut out text after tag
	sub(/,.*/, "", input)
	return sprintf("%s (%s)", input, date)
}

function classifyCommit(input, longHash, shortHash) {
	IDX = 0
	LABEL = ""

	if ( match(input, FEATURE_REGEX) ) {
		IDX = FEATURE_IDX
		LABEL = FEATURE_LABEL
		sub(FEATURE_REGEX, "", input)
	}
	if ( match(input, DOCS_REGEX) ) {
		IDX = DOCS_IDX
		LABEL = DOCS_LABEL
		sub(DOCS_REGEX, "", input)
	}
	if ( match(input, BUG_FIX_REGEX) ) {
		IDX = BUG_FIX_IDX
		LABEL = BUG_FIX_LABEL
		sub(BUG_FIX_REGEX, "", input)
	}
	if ( match(input, UPDATE_REGEX) ) {
		IDX = UPDATE_IDX
		LABEL = UPDATE_LABEL
		sub(UPDATE_REGEX, "", input)
	}

	if (TYPE == "plain") {
		commit = sprintf("- %s", input )
	}
	else {
		commit = sprintf("- %s (%s)", input, makeCommitLink(REPO_URL, shortHash, longHash) )
	}
	label = sprintf("%s: ", LABEL)

	if ( IDX > 0 ) {
		initializeCategoryLabel(IDX, label)
		storeCommitMaybe(commit, IDX)
	}

}

function initializeCategoryLabel(idx, msg) {
	bucket = OUTPUT[TAGS, idx]
	if ( length(bucket) < 1) {
		OUTPUT[TAGS, idx] = msg
	}

}

function storeCommitMaybe(commit, idx) {
	if ( length(commit) > 0 ) {
		OUTPUT[TAGS, idx] = OUTPUT[TAGS, idx] DELIMITER commit
	}
}

function makeCommitLink(repoUrl, shortHash, longHash) {
	return sprintf("[%s](%s/commit/%s)", shortHash, repoUrl, longHash)
}

# Get Git repo URL
function getRepoURL() {
	"git config --get remote.upstream.url || git config --get remote.origin.url || git config --get remote.dev.url" | getline REPO_URL
	sub(/:/, "/", REPO_URL)
	sub(/git@|https?:?\/+/, "https://", REPO_URL)
	sub(/\.git/, "", REPO_URL)
	return REPO_URL
}
