#!/bin/bash
set -e
source .env

# Use this function when receiving input from a pipe.
function read_stdin() {
  # -r treats backslash as part of the line to preserve newlines.
  while read -r line; do
    input="${input}${line}"
  done

  # don't add a trailing new line to the output
  echo -n ${input}
}

# `\033[33m` sets the text color to yellow.
# `\033[0m` resets the text color to the default.
function print_yellow() {
  echo -e "\033[33m${*}\033[0m"
}

# `\033[90m` sets the text color to grey.
# `\033[0m` resets the text color to the default.
function print_grey() {
  echo -e "\033[90m${*}\033[0m"
}

# `\033[32m` sets the color to green
# `\033[0m` resets the color to default
function print_green() {
  echo -e "\033[32m${*}\033[0m"
}

# Print a divider that is 50% the width of the terminal.
function print_divider() {
  # Get the width of the terminal
  local term_width=$(tput cols)
  local divider_width=$((term_width / 2))

  # Print the `-` character for half the terminal width.
  local divider="$(printf "%0.s-" $(seq 1 $divider_width))"
  echo -n "$divider"
}

# Escape text input to support prompts that include JSON text.
function process_user_input() {
  read_stdin \
    | jq --raw-input
}

function get_payload() {
  local user_message="$(read_stdin)"

  cat <<EOF
  {
    "model": "gpt-3.5-turbo",
    "messages": [{"role": "user", "content": ${user_message} }],
    "top_p": 0.01
  }
EOF
}


function get_openai_chat_completion() {
  curl \
    --silent \
    https://api.openai.com/v1/chat/completions \
      -H 'Content-Type: application/json' \
      -H "Authorization: Bearer ${API_KEY}" \
      -d "$(read_stdin)"
}

function parse_response() {
  read_stdin \
    | jq \
      --raw-output \
      '.choices[0].message.content'
}

function print_welcome_message() {
print_grey "$(print_divider)"

cat << EOF
Welcome!
Enter '/q' to quit.

EOF

# If the user does not provide an initial prompt, ask the user.
if [ -z "$user_input" ]; then
  echo "Type a message to get started."
fi

print_grey "$(print_divider)"
}

# The user may invoke the script with an initial user prompt.
user_input="$*"

print_welcome_message "$user_input"

# Begin chat loop
# TODO accumulate chat messages to retain context
# TODO accumulate chat messages while the token count is less than a configured limit.
# TODO label user input
# TODO label ai responses
while true; do
  # Prompt for input
  if [ -z "$user_input" ]; then
    read -p "> " user_input
    continue
  fi

  # Detect user commands
  if [ "$user_input" = "/q" ]; then
    echo "Exiting chat."
    exit 0
  fi

  # Get chat response
  echo $user_input \
    | process_user_input \
    | get_payload \
    | get_openai_chat_completion \
    | parse_response

  # Clear user input for next round.
  unset user_input
done
