FROM yottadb/yottadb-base

LABEL org.opencontainers.image.source=https://github.com/SwanseaUniversityMedical/ASSIGN-container

USER root
SHELL ["/bin/bash", "-c"]

# Get git.
RUN apt-get update && apt-get install -y git

# Add in startup script.
ADD startup_scripts/assign-startup.sh /assign-startup.sh

ENTRYPOINT ["/assign-startup.sh"]