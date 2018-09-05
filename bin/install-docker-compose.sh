echo Installing docker-compose on target system...
docker run docker/compose:1.13.0 version && echo alias docker-compose="'"'docker run -v /var/run/docker.sock:/var/run/docker.sock -v "$PWD:/rootfs/$PWD" -w="/rootfs/$PWD" docker/compose:1.13.0'"'" >> ~/.bashrc && source ~/.bashrc
git clone https://github.com/OHDSI/Broadsea.git
cd ~/Broadsea/postgresql
touch docker-compose-aou.yml
cat - >> docker-compose-aou_postgres.yml
version: '2'
 
services:

  broadsea-methods-library:
    image: ohdsi/broadsea-methodslibrary
    ports:
      - "8787:8787"
      - "6311:6311"

  broadsea-webtools:
    image: ohdsi/broadsea-webtools
    ports:
      - "8080:8080"
    environment:
      - WEBAPI_URL=http://35.188.57.16:8080
      - env=webapi-postgresql
      - datasource.driverClassName=org.postgresql.Driver
      - datasource.url=jdbc:postgresql://35.190.145.59:5432/synpuf
      - datasource.cdm.schema=public
      - datasource.ohdsi.schema=ohdsi
      - datasource.username=ohdsi_app_user
      - datasource.password=app1
      - spring.jpa.properties.hibernate.default_schema=ohdsi
      - spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.PostgreSQLDialect
      - spring.batch.repository.tableprefix=ohdsi.BATCH_
      - flyway.datasource.driverClassName=org.postgresql.Driver
      - flyway.datasource.url=jdbc:postgresql://35.190.145.59:5432/synpuf
      - flyway.schemas=ohdsi
      - flyway.placeholders.ohdsiSchema=ohdsi
      - flyway.datasource.username=ohdsi_admin_user
      - flyway.datasource.password=admin1
      - flyway.locations=classpath:db/migration/postgresql	  