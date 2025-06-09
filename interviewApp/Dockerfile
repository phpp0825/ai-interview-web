FROM python:3.10-slim-bullseye
WORKDIR /app

# 1) 미러 교체 + IPv4 강제 + 설치
RUN sed -i \
      -e '/bullseye-security/ s|deb.debian.org/debian-security|security.debian.org/debian-security|' \
      -e '/bullseye-updates/ s|deb.debian.org/debian|ftp.debian.org/debian|' \
      -e '/ bullseye / s|deb.debian.org/debian|ftp.debian.org/debian|' \
    /etc/apt/sources.list \
 && apt-get update -o Acquire::ForceIPv4=true \
 && apt-get install -y --no-install-recommends ffmpeg curl build-essential python3-dev portaudio19-dev libasound2-dev\
 && rm -rf /var/lib/apt/lists/*

COPY interview/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY interview/ .

EXPOSE 8000
CMD ["uvicorn", "unified_api:app", "--host", "0.0.0.0", "--port", "8000"]


