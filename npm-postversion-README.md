## Experimental: NPM postversion script

#### For NPM users
There is another executable added to your local `node_modules/.bin/` path:
- `changelog-postversion` : Destructive command that will rebuild your `CHANGELOG` and `CHANGELOG.md` files, and amend the last commit to include them. This is meant for the common use-case of updating a changelog *right after* running `npm version`, but before publishing. 

So for example, you could add to your project's NPM scripts:

```json
/* In your package.json: */
...
"scripts": {
    "postversion": "changelog-postversion"
},
...
```
