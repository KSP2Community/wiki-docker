#!/bin/bash

# Variables
REPO_PATH="/home/ubuntu/wiki/wiki-dumps"
CONTAINER_NAME="mediawiki"  # Name of the mediawiki container
DATE=$(date +'%Y-%m-%d')  # Current date in YYYY-MM-DD format
MONTH=$(date +'%Y-%m')  # Current month in YYYY-MM format
DUMP_FILENAME="dump_$DATE.xml"  # Dated dump filename
DUMP_PATH="/var/www/html/$DUMP_FILENAME"  # Path to the dump file inside the container

# Step 1: Generate the XML dump within the mediawiki container
docker exec $CONTAINER_NAME bash -c "php /var/www/html/maintenance/dumpBackup.php --full --quiet > $DUMP_PATH"

# Step 2: Change to the local repository directory
cd $REPO_PATH

# Step 3: Check if it's the 1st day of the month
if [ $(date +'%d') == "01" ]; then
    # If it's the 1st day of the month, create a new tag for the previous month's backups
    PREVIOUS_MONTH_TAG="backup-$(date --date='-1 month' +'%Y-%m')"
    git tag $PREVIOUS_MONTH_TAG

    # Push the new tag to GitHub
    git push origin $PREVIOUS_MONTH_TAG

    # Remove all files from the main branch except README.md
    find . -type f ! -name 'README.md' -delete
    git add -u

    # Commit the removal of files
    git commit -m "Clean main branch for the new month of backups"
fi

# Step 4: Copy the XML dump from the mediawiki container to the host
docker cp $CONTAINER_NAME:$DUMP_PATH $DUMP_FILENAME

# Step 5: Delete the XML dump from the mediawiki container to save disk space
docker exec $CONTAINER_NAME rm $DUMP_PATH

# Step 6: Add the new dump to the git index
git add $DUMP_FILENAME

# Step 7: Commit the new dump
git commit -m "Automated backup $DATE"

# Step 8: Push the new commit to GitHub
git push origin main