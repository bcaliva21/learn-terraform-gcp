#!/bin/bash
gcloud dns record-sets create ffe730e010c3.hnhrlrdt66ow.us-central1.sql.goog. --project=ace-practice-442822 --type=A --rrdatas=10.0.0.8 --zone=cloudsql-dns
