# Data Engineering Zoomcamp 2025

This repo contains files and notes for the [Data Engineering Zoomcamp](https://github.com/DataTalksClub/data-engineering-zoomcamp) by [Datatalks.Club](https://datatalks.club/)

### Environment setup 

You can set it up on your local machine or you can set up a virtual machine in Google Cloud Platform.

In this repo we will use windows + WSL2 locally

For the course you'll need:

* Python 3 
* Docker
* PgAdmin (optional since we work with docker images)
* Terraform
* Google Cloud Platform account

## Syllabus

### [Module 1: Containerization and Infrastructure as Code](/01-docker-sql/)

* Docker and docker-compose
* Running Postgres in a container
* Ingesting data to Postgres with Python
* Running Postgres and pgAdmin with Docker-compose
* Google Cloud Platform (GCP)
* Terraform
* Setting up infrastructure on GCP with Terraform

### [Module 2: Workflow Orchestration (Kestra)](/02-workflow-orchestration/)

* Introduction to Workflow Orchestration
* Introduction to Kestra
* Launch Kestra using Docker Compose
* ETL Pipelines: Load Data to Local Postgres
* ETL Pipelines: Load Data to Google Cloud Platform (GCP)