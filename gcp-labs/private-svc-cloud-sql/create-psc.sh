#!/bin/bash
gcloud compute addresses create cloudsql-psc --project=ace-practice-442822 --region=us-central1 --subnet=default --addresses=10.0.0.8
