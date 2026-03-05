: "${LLM_SUGGESTIONS_MODEL:=gpt-5.2}"
: "${LLM_SUGGESTIONS_BINDKEY:=^X^X}"  # Ctrl-X Ctrl-X as a default

zstyle -s ':llm-suggestions:' model LLM_SUGGESTIONS_MODEL
zstyle -s ':llm-suggestions:' bindkey LLM_SUGGESTIONS_BINDKEY

_llm_cmd_pick_widget() {
    emulate -L zsh
    setopt localoptions pipefail nomonitor

    if (( ! $+commands[llm] )); then
        zle -M "llm not found in PATH"
        return 1
    fi

    if (( ! $+commands[gum] )); then
        zle -M "gum not found in PATH"
        return 1
    fi

    if (( ! $+commands[fzf] )); then
        zle -M "fzf not found in PATH"
        return 1
    fi

    local input chosen prompt_status choice_status system_prompt
    local llm_stderr llm_error_line

    # Ask for the LLM prompt in a TUI writer.
    input="$(
        gum write \
            --header "LLM Prompt" \
            --placeholder "Describe the command you want to run:"
    )"
    prompt_status=$?
    if (( prompt_status != 0 )); then
        if (( prompt_status != 130 )); then
            zle -M "gum write failed (exit $prompt_status)"
        fi
        zle redisplay
        return 0
    fi
    [[ -z "${input//[[:space:]]/}" ]] && {
        zle -M "Prompt cannot be empty"
        zle redisplay
        return 0
    }

    OS=$(uname -s)
    if [[ "$OS" == "Darwin" ]]; then
        OS="macOS"
    fi

    system_prompt="Respond with several choices that can be ran directly on command line. Important: it will be executed via zsh on $OS.
        No formatting, no numbers, every line — separate command.
        If user asks specific number of choices, do as they say. Otherwise, write reasonable amount, for example, 5.
        Prefer simplest and most straightforwards solutions, use Python or other languages only if they fit better than standard shell tools."
    llm_stderr="$(mktemp "${TMPDIR:-/tmp}/llm-suggestions.XXXXXX")" || {
        zle -M "failed to create temporary file"
        zle redisplay
        return 1
    }

    chosen="$(
        fzf \
            --header "Pick Command" \
            --wrap \
            --layout=reverse \
            --border \
            < <(
                llm -m "$LLM_SUGGESTIONS_MODEL" -s "$system_prompt" "$input" \
                    2>"$llm_stderr"
            )
    )"
    choice_status=$?
    if [[ -s "$llm_stderr" ]]; then
        llm_error_line="${${(@f)$(<"$llm_stderr")}[1]}"
    fi
    rm -f "$llm_stderr"
    if (( choice_status != 0 )); then
        if (( choice_status != 130 )); then
            if [[ -n "$llm_error_line" && "$llm_error_line" != *"Broken pipe"* && "$llm_error_line" != *"[Errno 32]"* ]]; then
                zle -M "llm failed: $llm_error_line"
            else
                zle -M "fzf failed (exit $choice_status)"
            fi
            zle redisplay
            return 1
        fi
        zle redisplay
        return 0
    fi

    [[ -z "$chosen" ]] && { zle redisplay; return 0; }

    # Replace prompt text with the selected shell command.
    BUFFER="$chosen"
    CURSOR=${#BUFFER}
    zle redisplay
}

zle -N llm-cmd-pick _llm_cmd_pick_widget
bindkey "$LLM_SUGGESTIONS_BINDKEY" llm-cmd-pick
