#!/bin/bash
gcloud compute instances create cloudsql-client --zone=us-central1-a \
    --create-disk=auto-delete=yes,boot=yes,image=projects/debian-cloud/global/images/debian-12-bookworm-v20241112 \
    --scopes=https://www.googleapis.com/auth/cloud-platform \
    --network-interface=network=ace-study-network
