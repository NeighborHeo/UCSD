<!--
%\VignetteIndexEntry{Why Drat?}
%\VignetteEngine{simplermarkdown::mdweave_to_html}
%\VignetteEncoding{UTF-8}
-->
---
title: "Why Drat?"
author: "Steven Pav and Dirk Eddelbuettel"
date: "2015-03-27"
css: "water.css"
---

> Note: This was originally a 
> [guest post](https://dirk.eddelbuettel.com/blog/2015/03/13/)
> by Steven on Dirk's blog.

### Why Drat?

After playing around with [drat](https://dirk.eddelbuettel.com/code/drat.html) for a few
days now, my impressions of it are best captured by Dirk's quote:

> It just works.

#### Demo

To get some idea of what I mean by this, suppose you are a happy consumer of
R packages, but want access to, say, the latest, greatest releases of my distribution 
package, [sadist](https://github.com/shabbychef/sadists). 
You can simply add the following to your `.Rprofile` file:

```r
drat:::add("shabbychef")
```

After this, you instantly have access to new releases in the [github/shabbychef drat store](https://github.com/shabbychef/drat/tree/gh-pages) via the
package tools you already know and tolerate. You can use

```r
install.packages('sadists')
```

to install the sadists package from the drat store, for example. 
Similarly, if you issue

```r
update.packages(ask=FALSE)
```

all the drat stores you have added will be checked for package updates, along 
with their dependencies which may well come from other repositories including CRAN.

#### Use cases

The most obvious use cases are:

1. Micro releases. For package authors, this provides a means to get feedback 
from the early adopters, but also allows one to
push small changes and bug fixes without burning through your CRAN karma (if you have any left).
My personal drat store tends to be a few minor releases ahead of my CRAN releases.

2. Local repositories. In my professional life, I write and maintain proprietary packages.
Pushing package updates used to involve saving the package .tar.gz to a NAS, then calling
something like `R CMD INSTALL package_name_0.3.1.9001.tar.gz`. This is not something I wanted
to ask of my colleagues. With drat, they can instead add the following stanza to .Rprofile:
`drat:::addRepo('localRepo','file:///mnt/NAS/r/local/drat')`, and then rely on `update.packages`
to do the rest.

I suspect that in the future, [drat](https://dirk.eddelbuettel.com/code/drat.html) might be (ab)used in the following ways:

3. Rolling your own vanilla CRAN mirror, though I suspect there are better existing
ways to accomplish this.

4. Patching CRAN. Suppose you found a bug in a package on CRAN (inconceivable!). As it stands
now, you email the maintainer, and wait for a fix. Maybe the patch is trivial, but suppose it is 
never delivered. Now, you can simply make the patch yourself, pick a higher revision number, and stash
it in your drat store. The only downside is that eventually the package maintainer might 
bump their revision number without pushing a fix, and you are stuck in an arms race of version
numbers.

5. Forgoing CRAN altogether. While some package maintainers might find this attractive, I think I would
prefer a single huge repository, warts and all, to a landscape of a million microrepos. Perhaps some 
enterprising group will set up a CRAN-like drat store on github, and accept packages by pull request 
(whether github CDN can or will support the traffic that CRAN does is another matter), but this seems
a bit too futuristic for me now.

#### My wish list

In exchange for writing this blog post, I get to lobby Dirk for some features in drat:

6. I shudder at the thought of hundreds of tiny drat stores. Perhaps there should be a way to aggregate ```addRepo```
commands in some way. This would allow curators to publish their suggested lists of repos.

7. Drat stores are served in the `gh-pages` branch of a github repo. I wish there were some way to keep the 
index.html file in that directory reflect the packages present in the sources. Maybe this could be achieved with 
some canonical RMarkdown code that most people use.


