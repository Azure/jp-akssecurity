FROM openjdk:19-bullseye

RUN git clone https://github.com/Azure-Samples/quickstart-spring-data-jdbc-postgresql.git /app
WORKDIR /app

ENTRYPOINT ["./mvnw"]
CMD ["spring-boot:run"]