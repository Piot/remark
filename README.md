remark
======

Markdown Converter

## Structure

```
	_pages/
		header.html
		footer.html
		index.md
	_raw/

```
The markdown documents should be put under the `_pages/` directory (extension `.md`). The documents are converted to `.html`.
Under `_raw/` you put the files that are not parsed and is only copied into the target.

### Markdown Document

You can put meta data in the header of each markdown file.

```
---
key: value
---

```
Those meta properties are used in the formatting of the html. Especially in the `header.html` and `footer.html`. You put the key name inside of `{{}}`. Read more about [Liquid Markup](http://liquidmarkup.org/).

```
<title>{{title}}</title>
```

