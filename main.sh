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

# Create a json user message to add to the payload
function create_user_message() {
  local user_message="$(read_stdin)"

cat <<EOF
{"role": "user", "content": ${user_message} }
EOF

}

# Append a json message to the messages array.
function append_message() {
  local json_message_array="$1"
  local json_message_to_append="$(read_stdin)"

  # Append the json message to the json messages array
  jq \
      --null-input \
      --argjson m "$json_message_to_append" \
      --argjson ms "$json_message_array" \
      '
      { messages: $ms }
        | .messages += [$m]
        | .messages
      '
}

function create_chat_payload() {
  local msg_array="$(read_stdin)"

  cat <<EOF
  {
    "model": "gpt-3.5-turbo",
    "messages": ${msg_array},
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

function extract_chat_response() {
  read_stdin \
    | jq '.choices[0].message'
}

function label_ai_response() {
  local dashes="$(print_grey "----")"

  echo
  echo "${dashes} AI ${dashes}"
}

function print_response() {
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

# TODO accumulate chat messages while the token count is less than a configured limit.
# TODO label user input

# Begin chat loop
messages="[]"

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

  # Generate user message as JSON
  user_msg="$(
    echo $user_input \
      | process_user_input \
      | create_user_message
  )"

  # Add user message to messages JSON array
  messages="$(
    echo "$user_msg" \
      | append_message "$messages"
  )"

  # Send messages to openai
  ai_response="$(
    echo "${messages}" \
      | create_chat_payload \
      | get_openai_chat_completion \
  )"

  # Add ai response to messages JSON array
  messages="$(
    echo "$ai_response" \
      | extract_chat_response \
      | append_message "$messages"
  )"

  # The open AI reponse comes back prefixed with \n\n
  # Print the response without the double new line prefix.
  label_ai_response
  echo -e "$ai_response" \
    | print_response

  # Clean up
  unset user_input
  unset user_msg
  unset ai_response
done
