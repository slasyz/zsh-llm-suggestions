# zsh-llm-suggestions

Tiny Zsh plugin that opens a prompt, asks an LLM for shell command suggestions, and lets you pick one and execute it.

![demo](demo.gif)

## Requirements

- **zsh**
- **llm**: https://llm.datasette.io/
- **gum**: https://github.com/charmbracelet/gum
- **fzf**: https://github.com/junegunn/fzf

Install [gum](https://github.com/charmbracelet/gum) and [fzf](https://github.com/junegunn/fzf), for example, on macOS you can do this:
```sh
brew install gum fzf
```

Also install [llm](https://llm.datasette.io/) using your preferred method as described in [docs](https://llm.datasette.io/en/stable/setup.html), for example:
```sh
uv tool install llm
homebrew install llm
```

Verify that they are available in your PATH:
```sh
gum -v
fzf --version
llm --version
```

### Configure LLM provider (cloud or local)

To use OpenAI, just set the API key for llm and verify it, for example, like this:
```sh
llm keys set openai
llm -m gpt-6-sol "write me a poem about cats"
```

For OpenRouter, use this:
```sh
llm install llm-openrouter
llm keys set openrouter
```

If you want to use a different provider, model, or even a local one, configure `llm` accordingly (for example, by adding a custom model in [`extra-openai-models.yaml`](https://llm.datasette.io/en/stable/other-models.html) or installing a plugin from the [plugin directory](https://llm.datasette.io/en/stable/plugins/directory.html)), then set the model name as described in the [Configuration](#configuration) section below.

In this case, make sure your model returns output in the correct format (one command per line, no formatting). To check this, run the debug command (the optional `-m` flag passes the model name to `llm` as-is) to see what it returns with the default system prompt:
```sh
zsh-llm-suggestions-debug -m openrouter/google/gemini-3.8-flash "show datetime with ms"
```

## Install

### oh-my-zsh

```sh
git clone https://github.com/slasyz/zsh-llm-suggestions \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/llm-suggestions
```

Then add it to your plugins list in `~/.zshrc`:

```sh
plugins=(... llm-suggestions)
```

### zimfw

Add this to your `~/.zimrc`:

```sh
zmodule slasyz/zsh-llm-suggestions --name llm-suggestions
```

Then rebuild:

```sh
zimfw install
```

### zinit

Add this to your `~/.zshrc`:

```sh
zinit light slasyz/zsh-llm-suggestions
```

### Antigen

Add this to your `~/.zshrc`:

```sh
antigen bundle slasyz/zsh-llm-suggestions
antigen apply
```

### Without a plugin manager

Clone the repo and source the plugin file from `~/.zshrc`:

```sh
git clone https://github.com/slasyz/zsh-llm-suggestions ~/.zsh-llm-suggestions
source ~/.zsh-llm-suggestions/llm-suggestions.plugin.zsh
```

## Usage

Default keybinding: `Ctrl-X Ctrl-X`

Press it in your shell, type what you want, pick a generated command, then run/edit it.

## Configuration

Add this **before** the plugin is loaded. The settings are read once, when the
plugin is sourced, so anything set later in your config is ignored.

With oh-my-zsh that means above the `source $ZSH/oh-my-zsh.sh` line in your
`~/.zshrc` — putting the settings further down the file, after that line, is a
silent no-op:

```sh
# ... your LLM_SUGGESTIONS_* settings or zstyle calls go here ...

plugins=(... llm-suggestions)
source $ZSH/oh-my-zsh.sh
```

### Shell variables

```sh
export LLM_SUGGESTIONS_MODEL="gpt-6-sol"
export LLM_SUGGESTIONS_BINDKEY="^X^X"

# Optional: If you want to pass custom options to the `llm` command, 
# for example, to select a preferred provider when calling OpenRouter:
typeset -ga LLM_SUGGESTIONS_LLM_ARGS=(
  -o provider '{"order":["fireworks"],"allow_fallbacks":true}'
  -o reasoning_enabled false
)
```

`LLM_SUGGESTIONS_LLM_ARGS` is a zsh array. Each item is passed to `llm` as a separate argument.

### zstyle

```sh
zstyle ':llm-suggestions:' model gpt-6-sol
zstyle ':llm-suggestions:' bindkey '^X^X'

# Optional
zstyle ':llm-suggestions:' llm-args -o provider '{"order":["fireworks"],"allow_fallbacks":true}' -o reasoning_enabled false
```

If a setting is configured both ways, the `zstyle` wins; otherwise the shell
variable is used, and failing that the built-in default.
