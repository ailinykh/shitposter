FROM python:3.8.1-slim-buster

RUN apt-get update && apt-get -y install ffmpeg && rm -rf /var/lib/apt/lists/*

WORKDIR /home/app
COPY . .
RUN pip install --no-cache-dir -r requirements.txt

CMD [ "python", "." ]
