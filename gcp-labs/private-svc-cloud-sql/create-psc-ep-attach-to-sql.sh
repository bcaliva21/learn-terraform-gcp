#!/bin/bash
gcloud compute forwarding-rules create cloudsql-psc-ep --address=cloudsql-psc --project=ace-practice-442822 --region=us-central1 --network=ace-study-network --allow-psc-global-access --target-service-attachment=projects/q7d9e63c53f85af7dp-tp/regions/us-central1/serviceAttachments/a-ffe730e010c3-psc-service-attachment-53a17dddd1fa92a5
