#!/bin/bash

kubectl exec -it -n svb-webstack svb-database-0 -- psql -U postgres -d webstack -c "UPDATE settings SET name = '$1';"