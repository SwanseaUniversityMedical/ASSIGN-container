FROM yottadb/yottadb-base

LABEL org.opencontainers.image.source=https://github.com/SwanseaUniversityMedical/ASSIGN-container

USER root
SHELL ["/bin/bash", "-c"]

# Get git.
RUN apt-get update && apt-get install -y git

ENV assign_url="https://github.com/endeavourhealth-discovery/ASSIGN.git"
ENV assign_dest="./ASSIGN"
ENV assign_sha=""
ENV abp_dir="/data/ABP"
ENV ydb_chset=M

# Add in startup script.
COPY startup_scripts/assign-startup.sh /assign-startup.sh

# Expose port for YottaDB GUI
EXPOSE 9080:tcp

ENTRYPOINT ["/assign-startup.sh"]