#!/usr/bin/awk -f
BEGIN {
	REPO_URL = getRepoURL()
	# Prefixes that determine whether a commit will be printed

	CHANGELOG_REGEX = "^(changelog|fix|hotfix|docs|chore|feat|feature|refactor|update): "
	FS="|"

	# Prefixes used to classify commits

	FEATURE_REGEX = "^(feat|feature): "
	DOCS_REGEX = "^(changelog|docs): "
	BUG_FIX_REGEX = "^(fix|hotfix): "
	UPDATE_REGEX = "^(chore|refactor|update): "


	FEATURE_COUNT = 0
	BUG_FIX_COUNT = 0
	DOCS_COUNT = 0
	UPDATE_COUNT = 0
	OUTPUT_COUNT = 0

	# Get git log and store in array

	# %D: tags
	# %s: commit message
	# %H: long hash
	# %h: short hash

	i = 1
	while ("git log --date=short --pretty='%D|%s|%H|%h|%cd|%an'" | getline) {
		LINES[i] = $0
		i++
	}

	# Reverse array

	i--
	j = 1
	while (j < i) {
		temp = LINES[j]
		LINES[j] = LINES[i]
		LINES[i] = temp

		i--
		j++
	}

	# Iterate over array and store output in chronogical order

	i = 1
	while (LINES[i]) {

		# Split line into pieces defined above

		split( LINES[i], pieces, "|" )

		tag = pieces[1]
		message = pieces[2]
		longHash = pieces[3]
		shortHash = pieces[4]
		date = pieces[5]
		name = pieces[6]

		IS_GIT_TAG = length(tag) && match(tag, /tag:/)

		if (IS_GIT_TAG){

			# This represents a new version
			# Commits before this point should be printed before the tag

			printUpdates()
			printDocumentation()
			printBugFixes()
			printFeatures()

			# Add version

			printTag(tag, date)

		} else {

			# Determine if this commit is something to show in CHANGELOG

			classifyCommit(message, longHash, shortHash, date, name)

		}

		i++
	}

	# Print remaining commits
	# Anything here is pending release on next version

	printUpdates()
	printDocumentation()
	printBugFixes()
	printFeatures()

	if (TYPE == "plain") {
		storeOutput("Pending Release\n")
	} else {
		storeOutput("### Pending Release\n")
	}


	printOutput()
}

function printOutput () {

	# Print stored output in reverse order

	while (OUTPUT_COUNT) {
		printf(OUTPUT[--OUTPUT_COUNT])
	}
}
function printFeatures () {
	if (FEATURE_COUNT > 0){
		while (FEATURE_COUNT){
			storeOutput(FEATURES[--FEATURE_COUNT])
		}

		storeHeader(sprintf("##### New Features\n"))
		FEATURE_COUNT = 0
	}
}
function storeFeature (string) {
	FEATURES[FEATURE_COUNT++] = string
}

function printBugFixes () {
	if (BUG_FIX_COUNT > 0){
		while (BUG_FIX_COUNT){
			storeOutput(BUG_FIXES[--BUG_FIX_COUNT])
		}

		storeHeader(sprintf("##### Bug Fixes\n"))
		BUG_FIX_COUNT = 0
	}
}
function storeBugFix (string) {
	BUG_FIXES[BUG_FIX_COUNT++] = string
}

function printDocumentation () {
	if (DOCS_COUNT > 0){
		while (DOCS_COUNT){
			storeOutput(DOCS[--DOCS_COUNT])
		}

		storeHeader(sprintf("##### Documentation Changes\n"))
		DOCS_COUNT = 0
	}
}
function storeDocumentation (string) {
	DOCS[DOCS_COUNT++] = string
}

function printUpdates () {
	if (UPDATE_COUNT > 0){
		while (UPDATE_COUNT){
			storeOutput(UPDATES[--UPDATE_COUNT])
		}

		storeHeader(sprintf("##### Updates\n"))
		UPDATE_COUNT = 0
	}
}
function storeUpdate (string) {
	UPDATES[UPDATE_COUNT++] = string
}

function classifyCommit (message, longHash, shortHash, date, name) {
	if ( match(message, FEATURE_REGEX) ) {
		storeFeature(getCommitLine(message, longHash, shortHash, date, name))
	}
	if ( match(message, BUG_FIX_REGEX) ) {
		storeBugFix( getCommitLine(message, longHash, shortHash, date, name) )
	}
	if ( match(message, DOCS_REGEX) ) {
		storeDocumentation( getCommitLine(message, longHash, shortHash, date, name) )
	}
	if ( match(message, UPDATE_REGEX) ) {
		UPDATES[UPDATE_COUNT] = getCommitLine(message, longHash, shortHash, date, name)
	}
}

function getCommitLine (message, longHash, shortHash, date, name) {
	sub(CHANGELOG_REGEX, "", message)
	if (TYPE == "plain")
		return sprintf("\t- %s\n", message, makeCommitLink(REPO_URL, shortHash, longHash) )
	else
		return sprintf("- %s (%s) (%s)\n", message, makeCommitLink(REPO_URL, shortHash, longHash), name )
}

function printTag (input, date) {
	# Cut out text up to tag
	sub(/.*tag: v/, "", input)
	# Cut out text after tag
	sub(/,.*/, "", input)

	format = "####"
	split(input, parts, ".")

	if (parts[2] != MINOR_VERSION){
		format = "###"
	}

	if (parts[1] != MAJOR_VERSION){
		format = "##"
	}

	MAJOR_VERSION = parts[1]
	MINOR_VERSION = parts[2]
	PATCH_VERSION = parts[3]

	if (TYPE == "plain")
		storeOutput(sprintf("\n%s (%s)\n", input, date))
	else
		storeOutput(sprintf("\n%s %s (%s)\n", format, input, date))
}
function printCommit(input, longHash, shortHash) {
	if ( match(input, CHANGELOG_REGEX) ) {
		sub(CHANGELOG_REGEX, "", input)
		if (TYPE == "plain")
			sprintf("\t- %s\n", input, makeCommitLink(REPO_URL, shortHash, longHash) )
		else
			sprintf("- %s (%s)\n", input, makeCommitLink(REPO_URL, shortHash, longHash) )
	}
}
function makeCommitLink(repoUrl, shortHash, longHash) {
	return ("[" shortHash "](" repoUrl "/commit/" longHash ")")
}
# Get Git repo URL
function getRepoURL() {
	"git config --get remote.upstream.url || git config --get remote.origin.url || git config --get remote.dev.url" | getline REPO_URL
	sub(/:/, "/", REPO_URL)
	sub(/git@|https?:?\/+/, "https://", REPO_URL)
	sub(/\.git/, "", REPO_URL)
	return REPO_URL
}
function storeOutput (string) {
	OUTPUT[OUTPUT_COUNT++] = string
}
function storeHeader (string) {
	if (TYPE == "plain"){
		sub(/\#+ /, "\t", string)
	}
	# sub(/\s/, "\t", string)
	OUTPUT[OUTPUT_COUNT++] = string
}
