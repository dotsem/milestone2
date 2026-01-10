# kleinere image voor python
FROM python:3.12-slim

WORKDIR /app

# we gebruiken hier een requirements.txt bestand om alles makkelijk te installeren.
# we cachen niks aangezien dit niet nodig is en de grote van de container klein houdt
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY main.py .

# default uvicorn poort
EXPOSE 8000

# start de app met uvicorn
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
