# build frontend
FROM node:23 AS fe
WORKDIR /src
RUN npm i -g pnpm
COPY frontend ./frontend

# coolify can't build without this
RUN git config --global user.email "pompydev@proton.me"
RUN git config --global user.name "pompydev"
RUN git init
RUN git add .
RUN git commit -m "a"

COPY scripts.sh .
RUN ./scripts.sh build-frontend

# build backend
FROM golang:1.24 AS be
# Add Arguments for target OS and architecture (provided by buildx)
ARG TARGETOS
ARG TARGETARCH
WORKDIR /src
COPY . ./
COPY --from=fe /src/frontend/build ./frontend/build/
RUN ./scripts.sh build-backend ${TARGETOS} ${TARGETARCH}

# deploy
FROM alpine:3.21.0
LABEL org.opencontainers.image.source="https://github.com/0x2E/fusion"
WORKDIR /fusion
COPY --from=be /src/build/fusion ./
EXPOSE 8080
RUN mkdir /data
ENV DB="/data/fusion.db"
CMD [ "./fusion" ]
