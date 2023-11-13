#!/bin/bash
GITLAB_HOST=gitlab.siomporas.com
GITLAB_GROUP_ID=3
mkdir -p /opt/dev && cd /opt/dev
for repo in $(curl -s https://$GITLAB_HOST/api/v4/groups/$GITLAB_GROUP_ID | jq -r ".projects[].ssh_url_to_repo"); do git clone $repo; done;
