#!/bin/bash
gcloud dns managed-zones create cloudsql-dns --project=ace-practice-442822 --description="DNS zone for the cloud sql instances" --dns-name=us-central1.sql.goog. --networks=ace-study-network --visibility=private
