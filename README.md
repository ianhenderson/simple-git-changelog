# simple-git-changelog

A simple AWK script to generate changelogs from your Git history.

## Motivation

There are many fancy tools for generating changelogs based on ones git commit history, but I wanted one that was dead-simple to use and not dependent on runtimes like Nodejs, Python, etc.

Since AWK can be found on almost any Unix-based system, this script can be used regardless of whether you're building a project in Java, Golang, Javascript, etc.

## Installation

Depending on the type of project you're working on, `simple-git-changelog` can be installed in different ways.

#### Nodejs projects: As an NPM dependency

Install this package as a devDependency for your project and call it via NPM scripts:
```sh
npm i -D simple-git-changelog
```


#### Anything else

Clone or download the script to your machine and simply call it from the command line like any other script.

## Usage

Call the script within a Git repository, and it will print a summary of changes to STDOUT in reverse-chronological order.

It will default to printing in Markdown ([example](CHANGELOG.md)), but will print plain text as well ([example](CHANGELOG)) if you pass an argument:
```sh
./changelog.awk               		# outputs Markdown
./changelog.awk -v TYPE=plain 		# outputs plain text

./changelog.awk -v FROM=v1.1.0 		# only parses from git tag, "v1.1.0"
./changelog.awk -v FROM=2d2cce8 	# only parses from git commit "2d2cce8"

./changelog.awk -v MODE=old 		# outputs "classic" style, without categories

./changelog.awk -v TYPE=plain -v MODE=old -v FROM=2d2cce8 	# use multiple options
```

#### For NPM users
There is also an executable added to your local `node_modules/.bin/` path for convenience:
- `changelog` : Non-destructive command that simply prints to STDOUT based on your Git commit history. Same as simply calling `./changelog.awk`.

So for example, you could add to your project's NPM scripts:

```json
/* In your package.json: */
...
"scripts": {
    "changelog": "changelog > CHANGELOG.md"
},
...
```
## Notes

#### Tags
The script will order commits under their respective [Git tags](https://git-scm.com/docs/git-tag), assuming that they begin with "v" (ex. `v1`, `v43`, `v2.3.4`, etc.) All other tags will be ignored.

#### Commit prefixes
Only commits that are prefixed with one of the following prefixes will be output:
- `changelog`
- `fix`
- `docs`
- `chore`
- `feat`
- `feature`
- `refactor`
- `update`

For example:
- `fix: Fixed bug #123`
- `docs: Updated README`
- `refactor: Moved foobar into baz module`

#### Commit links (Markdown output only)
In order to build the little links to each commit, the script will essentially run:
```sh
git config --get remote.upstream.url || git config --get remote.origin.url || git config --get remote.dev.url
```
So make sure that you have a remote labeled either `upstream`, `origin` or `dev`.


## Todo
- Publish to `brew`, `apt-get`...?
