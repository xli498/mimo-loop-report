# Security Policy

## Reporting a sensitive issue

Please do not include API keys, access tokens, private prompts, user data, private endpoints, or sensitive payloads in issues or pull requests.

For a sensitive report, contact the repository owner privately through GitHub. Public issue reports should contain only the minimum sanitized reproduction details needed to verify the behavior.

## Reproduction safety

The reproduction script uses environment variables for credentials. Never commit a real `MIMO_API_KEY` or any other secret. Before publishing logs, remove authorization headers, tokens, private prompts, user data, and sensitive endpoint details.
