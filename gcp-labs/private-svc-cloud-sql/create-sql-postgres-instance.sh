#!/bin/bash
gcloud sql instances create cloudsql-postgres --project=ace-practice-442822 --region=us-central1 --enable-private-service-connect --allowed-psc-projects=ace-practice-442822 --availability-type=ZONAL --no-assign-ip --cpu=2 --memory=7680MB --edition=ENTERPRISE --database-version=POSTGRES_16
