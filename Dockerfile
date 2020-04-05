FROM continuumio/anaconda3

RUN apt-get update \
      && apt-get install unzip

COPY ./ /ldsc
WORKDIR /ldsc

RUN conda env create --file environment.yml
