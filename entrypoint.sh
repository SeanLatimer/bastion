#!/bin/sh

#
# Environment Variables:
#   PERMITTED_GITHUB_USERNAMES - List of github usernames that can use this host
#   SSH_HOST_ED25519           - (Optional) Content of the ED25519 host private key
#   SSH_HOST_RSA               - (Optional) Content of the RSA host private key
#

# Function to initialize or generate SSH host keys.
initialize_host_keys() {
  # ED25519 host key
  if [ -n "$SSH_HOST_ED25519" ]; then
    echo "$SSH_HOST_ED25519" >/etc/ssh/ssh_host_ed25519_key
    chmod 600 /etc/ssh/ssh_host_ed25519_key
    echo "Using provided SSH_HOST_ED25519 key."
  else
    echo "Generating new SSH host ED25519 key..."
    ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N "" -q
  fi

  # RSA host key
  if [ -n "$SSH_HOST_RSA" ]; then
    echo "$SSH_HOST_RSA" >/etc/ssh/ssh_host_rsa_key
    chmod 600 /etc/ssh/ssh_host_rsa_key
    echo "Using provided SSH_HOST_RSA key."
  else
    echo "Generating new SSH host RSA key..."
    ssh-keygen -t rsa -b 4096 -f /etc/ssh/ssh_host_rsa_key -N "" -q
  fi
}

# Function to pull SSH keys from GitHub and write to authorized_keys
pull_ssh_keys_from_github_and_write_to_authorized_keys() {
  local AUTHORIZED_KEYS=""

  #
  # to test this in zsh, run `for usr in $=PERMITTED_GITHUB_USERNAMES`
  # note the extra `=` sign that enables splitting by whitespace
  # read https://zsh.sourceforge.io/Doc/Release/Expansion.html#Parameter-Expansion
  #
  for usr in $PERMITTED_GITHUB_USERNAMES; do
    local KEYS=$(curl -s https://github.com/$usr.keys)
    echo "Fetched $(echo $KEYS | wc -w | xargs) keys for user '$usr'"

    # Alpine/POSIX compliant way of adding new lines, since "\n" is treated as a literal character
    # also: must left-align here to avoid extra whitespace at the beginning of each line
    local comment="# github.com/$usr"
    local keys_block="$comment
$KEYS

"

    AUTHORIZED_KEYS="${AUTHORIZED_KEYS}${keys_block}"
  done

  echo "$AUTHORIZED_KEYS" >~/.ssh/authorized_keys
  echo "...initializing of SSH keys complete."
}

# Initialize SSH host keys (either using provided keys or generating new ones)
initialize_host_keys

echo "Initializing SSH keys from GitHub..."

pull_ssh_keys_from_github_and_write_to_authorized_keys

echo "Ready to serve incoming SSH connections."

# Run command as is passed in
exec "$@"
