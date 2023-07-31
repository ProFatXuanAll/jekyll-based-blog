# jekyll-based-blog

This is my deprecated blog based on jekyll.
Here is a summary of reasons that makes writing blog in jekyll really frustrated and makes me end up deciding to change to another blog engine:

- Unstable versions:
  - Outdated `sass` for all versions of `ruby`.
  - Update `ruby` break dependencies (I don't know why or how it break, it just break).
- Irreproducible bugs:
  - Some themes behave differently for my local setup (I do check for dependency versions, and I still cannot figure it out what happens to my setup)
  - I need to understand `gem`, `bundle`, `github-action` so that I can find out where the bugs might come from.
  - I wrote a lot of math, and I use `mathjax@v3` to render math. But the only markdown parser `kramdown` paired with `jekyll` that can parse `mathjax` syntax somehow break (`*` got translated to `<em></em>`, `_` got translated to `<i></i>`, etc).

## Installation

Only work in Ubuntu.

```sh
# Install rbenv.
sudo apt install rbenv

# Put the output to .bashrc.
rbenv init

# Install ruby 2.7.0
rbenv install 2.7.0
rbenv global 2.7.0

# Install bundler and jekyll.
gem install bundler jekyll

# Clone project.
git clone https://github.com/ProFatXuanAll/ProFatXuanAll.github.io.git
cd ProFatXuanAll.github.io

# Use bundler to install project dependency.
bundle update
```

## Run Dev Server

```sh
bundle exec jekyll serve --livereload --drafts
```

### Production build

```sh
bundle exec jekyll build
```
