# virtual-assistant

## Overview

This script enables the user to chat with OpenAI's chat completion model from the command line.

## Usage

```bash
bash main.sh [prompt]
```
### Prerequisites

- Internet connection
- OpenAI API key
- Bash shell

### Configuration

Use a `.env` file to configure the program as follows:

```bash
# The openai api key
API_KEY=<api key>
```

### Invocation

```bash
bash main.sh [prompt]
```

If the program does not receive user input, it will prompt the user for a single line of input.

### Commands

The chat interface supports the following user commands:

- `/q` quits the chat.

## Notes

### Chat context

The program constrains the conversation context up to the model's token limit less approximately 256 tokens. As the context window grows beyond the limit, the program removes the oldest messages to maintain the constraint.

### Chat completion

Sample request:

- `top_p` is a percentage expressed as a decimal number. Select tokens with the top `n` probability mass. 

```bash
prompt='Hello!'
message=$(cat <<EOF
{
  "model": "gpt-3.5-turbo",
  "messages": [{"role": "user", "content": "${prompt}"}],
  "top_p": 0.01
}
EOF
)

curl \
  --silent \
  https://api.openai.com/v1/chat/completions \
    -H 'Content-Type: application/json' \
    -H "Authorization: Bearer ${API_KEY}" \
    -d "${message}"
```

Sample response:

```json
{
  "id": "chatcmpl-6u1ixmUCZCPmidyOcypzxN4qSSNmy",
  "object": "chat.completion",
  "created": 1678811015,
  "model": "gpt-3.5-turbo-0301",
  "usage": {
    "prompt_tokens": 9,
    "completion_tokens": 12,
    "total_tokens": 21
  },
  "choices": [
    {
      "message": {
        "role": "assistant",
        "content": "\n\nHello there! How can I assist you today?"
      },
      "finish_reason": "stop",
      "index": 0
    }
  ]
}
```
#### Resources

- [Chat endpoint documentation](https://platform.openai.com/docs/api-reference/chat/create)


