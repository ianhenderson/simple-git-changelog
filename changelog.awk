#!/usr/bin/awk -f
BEGIN {
	REPO_URL = getRepoURL()
	VERSION_IDX = 1
	
	# Prefixes that determine whether a commit will be printed
	CHANGELOG_REGEX = "^(changelog|fix|hotfix|docs|chore|feat|feature|refactor|update): "
	
	FEATURE_REGEX = "^(feat|feature): "
	FEATURE_IDX = 1
	
	DOCS_REGEX = "^(changelog|docs): "
	DOCS_IDX = 2
	
	BUG_FIX_REGEX = "^(fix|hotfix): "
	BUG_FIX_IDX = 3
	
	UPDATE_REGEX = "^(chore|refactor|update): "
	UPDATE_IDX = 4

	DELIMITER = "---"

	FS="|"
	
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
	while ("git log --pretty='%D|%s|%H|%h'" | getline) {
		
		IS_GIT_TAG = isGitTag($1)
		
		if (IS_GIT_TAG) {
			CURRENT_HEADER = getTag($1)
			storeNewHeader(CURRENT_HEADER)
		} else {
			commit = printCommit($2, $3, $4)
			storeCommitMaybe(commit)
		}
	}
	
	# Loop through OUTPUT array and print changelog.
	for (x = 1; x <= TAGS; x++) {
		tag = OUTPUT[x,0]
		commits = OUTPUT[x,1]
		len = split(commits, separate, DELIMITER)
		print(tag)
		for (val = 1; val <= len; val++) {
			commit = separate[val]
			if ( length(commit) ) {
				print(commit)
			}
		}
	}
}

function storeNewHeader(headerString) {
	TAGS++
	OUTPUT[TAGS, 0] = CURRENT_HEADER
}

function storeFirstHeader(headerString) {
	OUTPUT[TAGS, 0] = "Pending Changes"
}

function storeCommitMaybe(commit) {
	if ( length(commit) > 0 ) {
		OUTPUT[TAGS, 1] = OUTPUT[TAGS, 1] DELIMITER commit
	}
}

function isGitTag(input) {
	return length(input) && match(input, /tag:/)
}

function getTag(input) {
	# Cut out text up to tag
	sub(/.*tag: /, "", input)
	# Cut out text after tag
	sub(/,.*/, "", input)
	if (TYPE == "plain")
		return sprintf("\n%s\n", input)
	else
		return sprintf("\n## %s\n", input)
}

function printCommit(input, longHash, shortHash) {
	if ( match(input, CHANGELOG_REGEX) ) {
		sub(CHANGELOG_REGEX, "", input)
		if (TYPE == "plain")
			return sprintf("\t- %s\n", input, makeCommitLink(REPO_URL, shortHash, longHash) )
		else
			return sprintf("- %s (%s)\n", input, makeCommitLink(REPO_URL, shortHash, longHash) )
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
