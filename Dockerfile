FROM dart:stable AS build
# Dart image is already trixie-based, so we can run apt directly
RUN apt update && apt install -y gcc make && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY pubspec.yaml .
RUN dart pub get
COPY . .
RUN dart compile exe bin/dart_sha2_test.dart -o dart_sha2_test
RUN cd ./clib && make

FROM openeuler/distroless-base:2.38-oe2403lts
WORKDIR /app
COPY --from=build /app/dart_sha2_test /app/
COPY --from=build /app/clib/libmysha2.so /app/clib/
COPY --from=build /app/test_vectors/ /app/test_vectors/
ENV LD_LIBRARY_PATH=/app
CMD ["./dart_sha2_test"]