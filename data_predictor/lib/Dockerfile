FROM python:3.11-slim

WORKDIR /app


# Install build essentials and path
RUN apt-get update && apt-get install -y \ 
	build-essential \
	libcurl4-openssl-dev \
	libssl-dev \
	qt5-qmake \
	qtbase5-dev \
	python3-dev \
	pkg-config \
	libhdf5-dev \
	libgmp-dev \
	build-essential

COPY requirements.txt .
RUN pip install --upgrade pip
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD exec gunicorn --bind :$PORT --workers 1 --threads 8 --timeout 0 app:app
