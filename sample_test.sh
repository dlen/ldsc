#!/bin/bash

set -euo pipefail

use_pgc_data='yes'
data_base='/ldsc/data'
bip_name='pgc.cross.bip.zip'
scz_name='pgc.cross.scz.zip'
eur_ref_data='https://data.broadinstitute.org/alkesgroup/LDSCORE/eur_w_ld_chr.tar.bz2'
gen_vars='https://data.broadinstitute.org/alkesgroup/LDSCORE/w_hm3.snplist.bz2'

echo "###########################################"
echo "Downloading data"
echo "###########################################"
# Download Data

pgc_data(){

  if [[ ! -f "$data_base/$bip_name" && ! -f "$data_base/$scz_name" ]]; then
cat <<-'EOF'
Looks like PGC data is not available on the container.
Please fill the agreement form and download PGC data:

https://www.med.unc.edu/pgc/results-and-downloads/cd/

Datasets to select:
- Bipolar disorder subset
- Schizophrenia subset

Once the data is downloaded restart the container:

docker run -v ./data:/ldsc/data -ti ldsc bash
EOF

    exit 1
  fi
}


data_download() {
  if [ "$use_pgc_data" == 'yes' ]; then
    pgc_data
  fi
  wget -c -P $data_base $eur_ref_data $gen_vars
}


untar_data() {
  tar -jxvf $data_base/eur_w_ld_chr.tar.bz2 -C $data_base
  bunzip2 $data_base/w_hm3.snplist.bz2
  unzip -o $data_base/$bip_name
  unzip -o $data_base/$scz_name
}

munge_data() {
  local stats="$1"
  local samples="$2"
  local name="$3"
  local alleles="$4"
  echo "###########################################"
  echo "Munge data"
  echo "###########################################"
  # Munge Data
  ./munge_sumstats.py \
    --sumstats "$stats" \
    --N "$samples" \
    --out "$name" \
    --merge-alleles "$alleles"
}

ldsc() {
  echo "###########################################"
  echo "Starting LDSCORE regression"
  echo "###########################################"
  # LD Score Regression
  ./ldsc.py \
    --rg scz.sumstats.gz,bip.sumstats.gz \
    --ref-ld-chr $data_base/eur_w_ld_chr/ \
    --w-ld-chr $data_base/eur_w_ld_chr/ \
    --out scz_bip
  less scz_bip.log
}

data_download
untar_data
munge_data pgc.cross.SC* 17115 scz $data_base/w_hm3.snplist
munge_data pgc.cross.BIP* 11810 bip $data_base/w_hm3.snplist
ldsc
