#!/bin/bash

# --- Configuration ---
# Default database to assign to the user.
DEFAULT_DATABASE="dankflows"

# --- Script Logic ---
echo "--- ClickHouse User Setup Script ---"

# Prompt for ClickHouse Username
read -p "Enter the desired ClickHouse username: " CLICKHOUSE_USERNAME
if [ -z "$CLICKHOUSE_USERNAME" ]; then
    echo "Error: Username cannot be empty. Exiting."
    exit 1
fi

# Prompt for ClickHouse Password
echo "Enter the password for the new ClickHouse user (40+ characters recommended):"
read -s -p "Password: " CLICKHOUSE_PASSWORD
echo # Add a newline after the silent password input

if [ -z "$CLICKHOUSE_PASSWORD" ]; then
    echo "Error: Password cannot be empty. Exiting."
    exit 1
fi

echo "" # Add a newline for better readability
echo "Username to be created: $CLICKHOUSE_USERNAME"

# 1. Generate SHA256 hash of the password
echo "Generating SHA256 hash for the password..."
PASSWORD_HASH=$(echo -n "$CLICKHOUSE_PASSWORD" | sha256sum | awk '{print $1}')

if [ -z "$PASSWORD_HASH" ]; then
    echo "Error: Failed to generate password hash. Exiting."
    exit 1
fi

echo "Password SHA256 Hash: $PASSWORD_HASH"

# 2. Connect to ClickHouse and create user
echo "Connecting to ClickHouse to create user '$CLICKHOUSE_USERNAME'..."

# Create the SQL commands
SQL_COMMANDS="CREATE USER IF NOT EXISTS ${CLICKHOUSE_USERNAME} IDENTIFIED WITH SHA256_HASH BY '${PASSWORD_HASH}' DEFAULT DATABASE ${DEFAULT_DATABASE};
GRANT ALL ON ${DEFAULT_DATABASE}.* TO ${CLICKHOUSE_USERNAME};"

# Execute the SQL commands
echo "$SQL_COMMANDS" | docker compose exec -T clickhouse clickhouse-client --multiquery

if [ $? -eq 0 ]; then
    echo "User '$CLICKHOUSE_USERNAME' created and granted permissions successfully."
else
    echo "Error: Failed to create or configure ClickHouse user. Please check the logs above."
    exit 1
fi

echo "--- Setup Complete ---"
echo "Remember to store your chosen password securely."
