# Dockerfile for SVB Database
FROM postgres:15-alpine

# Copy initialization script to the docker-entrypoint-initdb.d directory
# This script will be executed when the container starts for the first time
COPY init.sql /docker-entrypoint-initdb.d/
