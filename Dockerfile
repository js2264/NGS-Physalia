ARG BIOC_VERSION
FROM bioconductor/bioconductor_docker:${BIOC_VERSION}
SHELL ["/bin/bash", "-c"]
COPY . /opt/BiocBook

## Install micromamba and required softwares in system-wide locations
ENV MAMBA_ROOT_PREFIX=/opt/micromamba
ENV MAMBA_EXE=/usr/local/bin/micromamba
RUN curl -L micro.mamba.pm/install.sh | bash && \
    mv /root/.local/bin/micromamba /usr/local/bin/micromamba && \
    echo -e "channels:\n  - bioconda\n  - conda-forge\n  - nodefaults\nchannel_priority: flexible" > ~/.condarc
RUN micromamba shell init --shell bash --root-prefix=${MAMBA_ROOT_PREFIX} && \
    micromamba create --file /opt/BiocBook/requirements.yml --yes && \
    micromamba create --yes -n yapc_env yapc -c conda-forge -c bioconda -c nodefaults yapc "numpy<1.24" && \
    micromamba clean --yes --quiet && \
    chmod -R a+rX ${MAMBA_ROOT_PREFIX}
ENV PATH="${MAMBA_ROOT_PREFIX}/envs/epigenomics/bin:${PATH}"

## Make micromamba + epigenomics env accessible to all users
RUN echo 'export MAMBA_ROOT_PREFIX=/opt/micromamba' >> /etc/bash.bashrc && \
    echo 'export MAMBA_EXE=/usr/local/bin/micromamba' >> /etc/bash.bashrc && \
    echo 'eval "$(micromamba shell hook -s bash)"' >> /etc/bash.bashrc && \
    echo 'micromamba activate epigenomics' >> /etc/bash.bashrc
RUN printf 'export MAMBA_ROOT_PREFIX=/opt/micromamba\nexport MAMBA_EXE=/usr/local/bin/micromamba\neval "$(micromamba shell hook -s bash)"\nmicromamba activate epigenomics\n' \
    > /etc/profile.d/micromamba.sh && chmod 644 /etc/profile.d/micromamba.sh
RUN mkdir -p /etc/rstudio && \
    printf 'export MAMBA_ROOT_PREFIX=/opt/micromamba\nexport MAMBA_EXE=/usr/local/bin/micromamba\neval "$(micromamba shell hook -s bash)"\nmicromamba activate epigenomics\n' \
    > /etc/rstudio/rsession-profile
RUN printf '\n## Micromamba epigenomics env (appended to PATH so system R takes precedence)\nMAMBA_ROOT_PREFIX=/opt/micromamba\nPATH=${PATH}:/opt/micromamba/envs/epigenomics/bin\n' \
    >> /usr/local/lib/R/etc/Renviron.site

## Install Quarto
RUN apt-get update && apt-get install gdebi-core -y && \
    curl -LO https://quarto.org/download/latest/quarto-linux-amd64.deb && \
    gdebi --non-interactive quarto-linux-amd64.deb && \
    rm quarto-linux-amd64.deb

## Install pak
RUN /usr/local/bin/Rscript -e 'install.packages("pak", repos = "https://r-lib.github.io/p/pak/devel/")'

## Install BiocBook repo
RUN /usr/local/bin/Rscript -e 'pak::pkg_install("/opt/BiocBook/", ask = FALSE, dependencies = c("Depends", "Imports", "Suggests"))'

