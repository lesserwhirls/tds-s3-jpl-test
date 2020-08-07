#!/bin/bash
# wait 60 seconds before forcefully killing the container
docker-compose stop --time=60 && docker-compose rm -f
