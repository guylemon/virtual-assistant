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


# Escape text input to support prompts that include JSON text.
function process_user_input() {
	read_stdin \
		| jq --raw-input
}

# TODO accumulate chat messages while the token count is less than a configured limit.
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

# The user may invoke the script with an initial user prompt.
user_input="$*"

# If the user does not provide an initial prompt, ask the user.
if [ -z "$user_input" ]; then
	read -p "Please enter a single line prompt: " user_input
fi

echo $user_input \
	| process_user_input \
	| get_payload \
	| get_openai_chat_completion \
	| parse_response
