#!/bin/bash

# File containing employee data
EMPLOYEE_FILE="/home/roeisha/Downloads/EmployeeNames.csv"

#Creating Counters for new users and groups 
NEW_USERS=0
NEW_GROUPS=0

# Check if the employee file already exists
if [[ ! -f "$EMPLOYEE_FILE" ]]; then
    echo "Error: Employee file '$EMPLOYEE_FILE' not found!"
    exit 1
fi

# Reads the employee file line by line
while IFS=, read -r FIRST_NAME LAST_NAME DEPARTMENT; do
    # Skip the header row if it exists
    if [[ "$FIRST_NAME" == "FirstName" ]]; then
        continue
    fi

    # Generate username: first character of first name + first 7 characters of last name (lowercase)
    USERNAME="$(echo ${FIRST_NAME:0:1}${LAST_NAME:0:7} | tr '[:upper:]' '[:lower:]')"

    # Check if the user already exists
    if id "$USERNAME" &>/dev/null; then
        echo "Error: User '$USERNAME' already exists. Skipping..."
        continue
    fi

    # Creating user with a default shell of /bin/bash
    sudo useradd -m -s /bin/bash "$USERNAME"
    if [[ $? -eq 0 ]]; then
        echo "Created user: $USERNAME"
        ((NEW_USERS++))
    else
        echo "Error: Failed to create user '$USERNAME'. Skipping..."
        continue
    fi

    # Check if the department group exists
    if ! getent group "$DEPARTMENT" &>/dev/null; then
        # Create the group if it doesn't exist
        sudo groupadd "$DEPARTMENT"
        if [[ $? -eq 0 ]]; then
            echo "Created group: $DEPARTMENT"
            ((NEW_GROUPS++))
        else
            echo "Error: Failed to create group '$DEPARTMENT'. Skipping..."
            continue
        fi
    else
        echo "Group '$DEPARTMENT' already exists."
    fi

    # Check if the user is already a member of the group
    if id -nG "$USERNAME" | grep -qw "$DEPARTMENT"; then
        echo "Error: User '$USERNAME' is already a member of group '$DEPARTMENT'. Skipping..."
    else
        # Assign the user to the department group as their primary group
        sudo usermod -g "$DEPARTMENT" "$USERNAME"
        if [[ $? -eq 0 ]]; then
            echo "Added user '$USERNAME' to group '$DEPARTMENT'"
        else
            echo "Error: Failed to add user '$USERNAME' to group '$DEPARTMENT'. Skipping..."
        fi
    fi

done < "$EMPLOYEE_FILE"

# Display summary of new users and groups created
echo "---"
echo "Summary:"
echo "New users created: $NEW_USERS"
echo "New groups created: $NEW_GROUPS"
echo "---"
