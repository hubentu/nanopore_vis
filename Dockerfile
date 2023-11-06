FROM rocker/shiny

RUN apt-get update && apt-get install -y \
    --no-install-recommends \
    minimap2 \
    samtools \
    git-core \
    libssl-dev \
    libcurl4-gnutls-dev \
    curl \
    libsodium-dev \
    libxml2-dev \
    libicu-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN Rscript -e "install.packages('remotes')"
RUN Rscript -e "remotes::install_github('gladkia/igvShiny')"

RUN addgroup --system app \
    && adduser --system --ingroup app app
WORKDIR /home/app
COPY nanopore_vis.R .
RUN chown app:app -R /home/app
USER app

EXPOSE 3838
CMD ["R", "-e", "shiny::runApp('/home/app/nanopore_vis.R')"]
