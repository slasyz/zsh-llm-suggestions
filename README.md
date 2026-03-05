# zsh-llm-suggestions

Tiny Zsh plugin that opens a prompt, asks an LLM for shell command suggestions, and lets you pick one and execute it.

![demo](demo.gif)

## Requirements

- **zsh**
- **llm**: https://llm.datasette.io/
- **gum**: https://github.com/charmbracelet/gum
- **fzf**: https://github.com/junegunn/fzf

Install [gum](https://github.com/charmbracelet/gum) and [fzf](https://github.com/junegunn/fzf), for example, on macOS you can do this:
```shell
brew install gum fzf
```

Also install [llm](https://llm.datasette.io/) using your preferred method as described in [docs](https://llm.datasette.io/en/stable/setup.html).

Verify that they are available in your PATH:
```shell
gum -v
fzf --version
llm --version
```

### Configure LLM provider (cloud or local)

To use OpenAI, just set the API key for llm and verify it, for example, like this:
```shell
llm keys set openai
llm -m gpt-5.2 "write me a poem about cats"
```

If you want to use a different provider, different model, or even a local one, you can configure llm accordingly (probably, by adding a custom model to [`extra-openai-models.yaml`](https://llm.datasette.io/en/stable/other-models.html) file or installing a plugin from the [plugin directory](https://llm.datasette.io/en/stable/plugins/directory.html)) and setting model name as described in [Configuration](#configuration) block below.

In this case, be sure that your model returns output in correct format (one command per line, no formatting). To check this, you can run the debug command (with optional `-m` flag to specify model, it will be passed to llm as is) to see what does it return with the default system prompt:
```shell
zsh-llm-suggestions-debug -m openrouter/google/gemini-3-flash-preview "show datetime with ms"
```

## Install

### oh-my-zsh

```shell
git clone https://github.com/slasyz/zsh-llm-suggestions \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/llm-suggestions
```

Then add it to your plugins list in `~/.zshrc`:

```shell
plugins=(... llm-suggestions)
```

### zimfw

Add this to your `~/.zimrc`:

```shell
zmodule slasyz/zsh-llm-suggestions --name llm-suggestions
```

Then rebuild:

```shell
zimfw install
```

### zinit

Add this to your `~/.zshrc`:

```shell
zinit light slasyz/zsh-llm-suggestions
```

### Antigen

Add this to your `~/.zshrc`:

```shell
antigen bundle slasyz/zsh-llm-suggestions
antigen apply
```

### Without a plugin manager

Clone the repo and source the plugin file from `~/.zshrc`:

```shell
git clone https://github.com/slasyz/zsh-llm-suggestions ~/.zsh-llm-suggestions
source ~/.zsh-llm-suggestions/llm-suggestions.plugin.zsh
```

## Usage

Default keybinding: `Ctrl-X Ctrl-X`

Press it in your shell, type what you want, pick a generated command, then run/edit it.

## Configuration

Add this before loading the plugin.

### Environment variables

```shell
export LLM_SUGGESTIONS_MODEL="gpt-5.2"
export LLM_SUGGESTIONS_BINDKEY="^X^X"
```

### zstyle

```shell
zstyle ':llm-suggestions:' model gpt-5.2
zstyle ':llm-suggestions:' bindkey '^X^X'
```
