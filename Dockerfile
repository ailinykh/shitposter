FROM swift:latest as builder
WORKDIR /root
COPY . .
RUN swift build -c release

FROM swift:slim
RUN apt-get -q update && \
    apt-get -q install -y ffmpeg && \
    rm -r /var/lib/apt/lists/*
WORKDIR /root
COPY --from=builder /root .
CMD [".build/release/Shitposter"]
