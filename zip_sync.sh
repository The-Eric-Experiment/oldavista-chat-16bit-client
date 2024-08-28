#!/bin/bash

# Paths
FOLDER_PATH="/home/ericmackrodt/Development/oldavista-chat-16bit-client"
IMG_PATH="/home/ericmackrodt/Documents/src.img"
MOUNT_POINT="/mnt/zip"
TEMP_MOUNT_POINT="${MOUNT_POINT}_temp"

# Ensure the mount points exist
mkdir -p "$MOUNT_POINT"
mkdir -p "$TEMP_MOUNT_POINT"

# Function to clear and sync the folder contents to the image
sync_folder_to_image() {
    echo "Syncing..."

    # Calculate the offset for the partition
    OFFSET=$((32 * 512))

    # Mount the image to the temporary mount point using the offset
    sudo mount -o loop,offset=$OFFSET -t vfat "$IMG_PATH" "$TEMP_MOUNT_POINT"

    if [ $? -ne 0 ]; then
        echo "Failed to mount image. Exiting."
        exit 1
    fi

    # Clear the image's contents
    sudo rm -rf "$TEMP_MOUNT_POINT/*"

    # Sync the folder contents to the mounted image without changing ownership or permissions
    sudo rsync -a --delete --no-o --no-g --no-perms "$FOLDER_PATH/" "$TEMP_MOUNT_POINT/"

    # Unmount the image
    sudo umount "$TEMP_MOUNT_POINT"

    echo "Sync completed."
}

# Function to monitor folder and sync on changes
monitor_and_sync() {
    while true; do
        inotifywait -r -e create,delete,modify,move "$FOLDER_PATH"
        # Temporarily stop watching and sync
        sync_folder_to_image
        sleep 1  # Pause briefly before resuming monitoring to avoid rapid retriggering
    done
}

# Initial synchronization
sync_folder_to_image

# Start monitoring the folder for changes and sync when detected
monitor_and_sync
