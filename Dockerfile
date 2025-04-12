ARG BIOC_VERSION
FROM bioconductor/bioconductor_docker:${BIOC_VERSION}
SHELL ["/bin/bash", "-c"]
COPY . /opt/BiocBook

## Install micromamba and required softwares
RUN curl -L micro.mamba.pm/install.sh | bash && \
    echo -e "channels:\n  - bioconda\n  - conda-forge\n  - nodefaults\nchannel_priority: flexible" > ~/.condarc && \
    source ~/.bashrc && \
RUN micromamba shell init --shell bash --root-prefix=~/micromamba && \
    micromamba create --file /opt/BiocBook/requirements.yml --yes && \
    micromamba clean --yes --quiet && \
    micromamba shell init --shell bash --root-prefix=~/micromamba

## Install Quarto
RUN apt-get update && apt-get install gdebi-core -y && \
    curl -LO https://quarto.org/download/latest/quarto-linux-amd64.deb && \
    gdebi --non-interactive quarto-linux-amd64.deb && \
    rm quarto-linux-amd64.deb

## Install pak
RUN Rscript -e 'install.packages("pak", repos = "https://r-lib.github.io/p/pak/devel/")'

## Install BiocBook repo
RUN Rscript -e 'pak::pkg_install("/opt/BiocBook/", ask = FALSE, dependencies = c("Depends", "Imports", "Suggests"))'

