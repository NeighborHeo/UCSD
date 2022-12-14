<!--
%\VignetteIndexEntry{Drat Step-by-Step}
%\VignetteEngine{simplermarkdown::mdweave_to_html}
%\VignetteEncoding{UTF-8}
-->
---
title: Drat Step-By-Step
author: Roman Hornung and Dirk Eddelbuettel
date: "Written 2021-Apr-04, updated 2021-Jul-09"
css: "water.css"
---


## Overview, Scope and Background

This step-by-step tutorial shows how to use [`drat`](https://github.com/eddelbuettel/drat) to let an [R](https://www.r-project.org) package utilise an [R](https://www.r-project.org) package available on some other place that is not [CRAN](https://cran.r-project.org).
We will assume [GitHub](https://github.com) here as the (source) location of the 'other' package, but any other source repository applies equally for the _source_ part of the other package.

The situation assumes your package (which you would like to publish on CRAN) has a _weak dependency_ on this other package (which is something CRAN allows via an `Additional_repositories` entry).
We will use this feature here, and have [`drat`](https://github.com/eddelbuettel/drat) be the helper to create one such additional repository.
The other package may be written by you, or maybe someone else. 
Here we assume for simplicity that it is written by someone else, under a suitable license but for whichever reason _not_ on CRAN.
So the plan is to get the _other_ package into a `drat` repo we set up so that _your package_ can refer to it via `Additional_repositories` in its `DESCRIPTION` file.

We assume the following tools to be available, as well as reasonable familiarity with them: 

- a [GitHub](https://github.com) account (as we use GitHub to host the [`drat`](https://github.com/eddelbuettel/drat) package repo), 
- [R](https://www.r-project.org) (as all this work is in the context of caring for [R](https://www.r-project.org) packages),
- `git` (and some familiarity with `git` on the command-line). 


## Steps

#### Prepare the dependent package

We first prepare the other depended-upon [R](https://www.r-project.org) package so it is ready for upload to the to-be-created (not yet existing) new repository.

We start by downloading this [R](https://www.r-project.org) package from its GitHub repository.

- Go to the GitHub page of the package, e.g. `https://github.com/donaldduck/quacking`, and click the green "Code" button.
- The "Clone" option should have choices for http, ssh, the newer CLI. 
- If you have an ssh key registered at GitHub, choose ssh.
- Else http is fine (though the frequent password checks get tiring).
- Hit the little folder icon to copy the URL and paste it into your command-line to form the `git clone` command:

```sh
git clone git@github.com:donalduck/quacking
```

This will _clone_ the repository to your local machine which creates a local copy typically used for read-only access.

Now that you have the source, create a package from them via `R CMD build .` inside the `quacking` repository.
This will generate a source file, say `quacking_1.2.3.tar.gz`, for this repository.

(You can also create a binary package if you want, and/or do so from, say, within RStudio.  
We focus on command-line use here.)



#### Create the `drat` repository

Go to https://github.com/drat-base/drat and fork the repository by clicking the button "Fork".
You now have a _remote_ copy of that repository named `https://github.com/YourName/drat` that can serve as your `drat` repository, and to which we will add your own content below.
(There are other ways using _e.g._ `dratInit()` but we ignore this here to focus on the start via forking.)

Next, we have to ensure your `drat` repository can server over https. 
Go to "Settings" on `https://github.com/YourName/drat` and scroll down to "GitHub Pages".
Specify "master" below "Branch" and "docs" right of it and click "Save". 
GitHub should now state that _Your site is ready to be published_ and list `https://YourName.github.io/drat/` as its address.
Note that the forked `drat` repository still contains a copy of the `drat` sources (in order to be a viable repository.)
Once you added your content, you can remove it, or just keep it.

#### Create a local copy of your fork

This follows the steps above for creating a local copy of the depended-upon package. 
Now we bring the freshly-forked `drat` repository 'home' to your computer.
So in the directory in which you keep your git repositories, say

```sh
git clone https://github.com/YourName/drat
```

or 

```sh
git clone git@github.com:YourName/drat.git
```

depending upon whether you prefer authentication via http or ssh.


#### Ensure you have the `drat` package

This usually entails just a simple `install.packages("drat")` as [`drat`](https://github.com/eddelbuettel/drat) is on [CRAN](https://cran.r-project.org).
However, currently (spring 2021), we also want to ensure you have the most current version of [`drat`](https://github.com/eddelbuettel/drat) that can use `docs/`.
To ensure this, install [`drat`](https://github.com/eddelbuettel/drat) from its source repo from within [R](https://www.r-project.org) via

```r
remotes::install_github("eddelbuettel/drat")
```

(as we are using the `drat` repo serving from `docs/` whereas the CRAN version still defaults to the older scheme of a `gh-pages` branch.)

Now continue in [R](https://www.r-project.org) (and we assume we are in your `git` working directory with both the cloned dependent `quacking` repository as well as a `drat` repo right below the
working directory).

```r
library(drat)
options(dratBranch="docs")   # to default to using docs/ as we set up
insertPackage(file=c("quacking/quacking_1.2.3.tar.gz", "quacking/quacking_1.2.3.zip"), 
              repodir="drat/")
```

In the above "1.2.3" is a possible placeholder for the actual version number of the quacking package, just as quacking is a placeholder for your actual package of interest.
This will add the quacking source and binary package to the folders `drat/docs/src/contrib` and `drat/docs/bin/windows/contrib/4.0`.
If you only have a source package, just omit the binary package ending in `.zip`.

Optionally, change the content of the file `drat/README.md` to fit your purpose. 
The file can be also be deleted altogether.

#### Finalising 

In the terminal, execute `cd drat` to get into the [`drat`](https://github.com/eddelbuettel/drat) repository.

If you use `git` for the first time, execute:
```sh
git config --global user.email "youremail@yourdomainhere"
git config --global user.name "YourName"
```

This will tell git your identity.
If you want to use `ssh`, you may want to upload an ssh key; see the relevant GitHub tutorials.

Then type:
```sh
git add .
git commit -m "Added quacking"
git push origin master
```

This will upload the quacking package to the repository on GitHub.
(You could add the `quacking` package version and/or `git` sha1 to the commit message but that is entirely optional.)

#### Test it

To test whether the package can be installed from your new repository, type in R

```r
install.packages("quacking", repos="https://yourname.github.io/drat")
```

and verify that the package is installed successfully.
(Note that you may have to say `type="source"` if your operating system prefers source installation and you only added a source version to your [`drat`](https://github.com/eddelbuettel/drat) repository.)

#### Use the [`drat`](https://github.com/eddelbuettel/drat) repo

Prepare the `DESCRIPTION` file of your [R](https://www.r-project.org) package:

- List the quacking package under `Suggests:` 
- Add the line `Additional_repositories: https://yourname.github.io/drat`

Test the package via `R CMD check --as-cran packageName_0.1.2.tar.gz`.
If everything passes, you are now ready for submission to CRAN.


#### Additional step

If a directory has no content, browsing `https://yourname.github.io/drat` will show "404 File not found". 
This can upset checks as for example the ones done by CRAN. 
As of release 0.2.1, [`drat`](https://github.com/eddelbuettel/drat) inserts a minimal placeholder file to avoid this error.


## Summary

This step by step demonstrated how to set up a `drat` repository to serve an optional package referenced by `Additional_repositories` and `Suggests` in a CRAN-compliant way.
