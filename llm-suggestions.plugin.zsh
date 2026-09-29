# Single source of truth for the default model.
typeset -g LLM_SUGGESTIONS_DEFAULT_MODEL="gpt-6-sol"

: "${LLM_SUGGESTIONS_MODEL:=$LLM_SUGGESTIONS_DEFAULT_MODEL}"
: "${LLM_SUGGESTIONS_BINDKEY:=^X^X}"  # Ctrl-X Ctrl-X as a default
typeset -ga LLM_SUGGESTIONS_LLM_ARGS
LLM_SUGGESTIONS_LLM_ARGS=("${LLM_SUGGESTIONS_LLM_ARGS[@]}")

# Precedence: zstyle > existing env/shell variable > default.
# `zstyle -s`/`-a` blank the target parameter when the style is undefined, so
# read into a temp and only overwrite the real variable on success.
typeset _llm_suggestions_style
if zstyle -s ':llm-suggestions:' model _llm_suggestions_style; then
    LLM_SUGGESTIONS_MODEL="$_llm_suggestions_style"
fi
if zstyle -s ':llm-suggestions:' bindkey _llm_suggestions_style; then
    LLM_SUGGESTIONS_BINDKEY="$_llm_suggestions_style"
fi
unset _llm_suggestions_style

typeset -a _llm_suggestions_style_args
if zstyle -a ':llm-suggestions:' llm-args _llm_suggestions_style_args; then
    LLM_SUGGESTIONS_LLM_ARGS=("${_llm_suggestions_style_args[@]}")
fi
unset _llm_suggestions_style_args

# Guard against empty style/env values so bindkey always receives a sequence.
[[ -n "${LLM_SUGGESTIONS_MODEL//[[:space:]]/}" ]] || LLM_SUGGESTIONS_MODEL="$LLM_SUGGESTIONS_DEFAULT_MODEL"
[[ -n "${LLM_SUGGESTIONS_BINDKEY//[[:space:]]/}" ]] || LLM_SUGGESTIONS_BINDKEY="^X^X"

_llm_suggestions_system_prompt() {
    emulate -L zsh

    local os
    os="$(uname -s)"
    if [[ "$os" == "Darwin" ]]; then
        os="macOS"
    fi

    print -r -- "Respond with several choices that can be ran directly on command line. Important: it will be executed via zsh on $os.
No formatting, no numbers, every line — separate command.
If user asks specific number of choices, do as they say. Otherwise, write reasonable amount, for example, 5.
Prefer simplest and most straightforwards solutions, use Python or other languages only if they fit better than standard shell tools."
}

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

    system_prompt="$(_llm_suggestions_system_prompt)"
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
                llm -R -m "$LLM_SUGGESTIONS_MODEL" -s "$system_prompt" \
                    "${LLM_SUGGESTIONS_LLM_ARGS[@]}" \
                    "$input" \
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

zsh-llm-suggestions-debug() {
    emulate -L zsh
    setopt localoptions pipefail
    zmodload zsh/datetime
    local start_time=$EPOCHREALTIME

    if (( ! $+commands[llm] )); then
        print -u2 -- "llm not found in PATH"
        return 1
    fi

    local model="$LLM_SUGGESTIONS_MODEL"
    local opt
    local OPTIND=1
    while getopts ":m:h" opt; do
        case "$opt" in
            m) model="$OPTARG" ;;
            h)
                print -- "Usage: zsh-llm-suggestions-debug [-m model] <prompt>"
                return 0
                ;;
            :)
                print -u2 -- "Option -$OPTARG requires an argument"
                return 2
                ;;
            \?)
                print -u2 -- "Unknown option: -$OPTARG"
                return 2
                ;;
        esac
    done
    shift $((OPTIND - 1))

    local input="$*"
    if [[ -z "${input//[[:space:]]/}" ]]; then
        print -u2 -- "Usage: zsh-llm-suggestions-debug [-m model] <prompt>"
        return 2
    fi

    [[ -n "${model//[[:space:]]/}" ]] || model="$LLM_SUGGESTIONS_DEFAULT_MODEL"
    # Same flags as the widget so debug output reflects what the widget runs.
    llm -R -m "$model" -s "$(_llm_suggestions_system_prompt)" \
        "${LLM_SUGGESTIONS_LLM_ARGS[@]}" \
        "$input"
    local llm_status=$?
    print -u2 -f "\nTotal time: %.2f seconds\n" "$(( EPOCHREALTIME - start_time ))"
    return $llm_status
}

zle -N llm-cmd-pick _llm_cmd_pick_widget
bindkey "$LLM_SUGGESTIONS_BINDKEY" llm-cmd-pick
