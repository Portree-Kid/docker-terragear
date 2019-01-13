TGROOT=/home/flightgear/tg
TERRAIN_DIR=$(TGROOT)/output/Terrain
NUDGE=20
THREADS=2

-include $(TGROOT)/config/config.mk

DAT_FILES != grep -e '^1  ' $(TGROOT)/airports/apt.dat | cut -c14-17 | sed 's/\([A-Z0-9]*\)/\$$\(TGROOT\)\/airports\/dat\/\1.dat/g' | tr '\n' ' '
STA_FILES != grep -e '^1  ' $(TGROOT)/airports/apt.dat | cut -c14-17 | sed 's/\([A-Z0-9]*\)/\$$\(TGROOT\)\/airports\/state\/\1.sta/g' | tr '\n' ' '

GENAPTS_FLAGS=--work=$(TGROOT)/work --threads=$(THREADS) --nudge=$(NUDGE)

TGCONSTRUCT_FLAGS=\
    --output-dir=$(TERRAIN_DIR) \
    --work-dir=$(TGROOT)/work \
    --share-dir=$(TGROOT)/share \
    --usgs-map=$(TGROOT)/config/usgsmap.txt \
    --priorities=$(TGROOT)/config/default_priorities.txt \
    --nudge=$(NUDGE) --ignore-landmass \
    --debug-dir=$(TGROOT)/debug \
    --threads=$(THREADS) \
    --min-lat=$(MINLAT) \
    --max-lat=$(MAXLAT) \
    --min-lon=$(MINLON) \
    --max-lon=$(MAXLON) \
    $(shell ls $(TGROOT)/work/)

airports: $(STA_FILES)
	@echo "Airports done"

gateway:
	rm -f $(TGROOT)/airports/meta.json
	xpget.py -o $(TGROOT)/airports
	
terrain:
	@mkdir -p $(TERRAIN_DIR)
	echo $(TGCONSTRUCT_FLAGS)
	tg-construct $(TGCONSTRUCT_FLAGS)
	
$(TGROOT)/airports/dat/%.dat: $(TGROOT)/airports/apt.dat
	@mkdir -p $(TGROOT)/airports/dat
	@cat $(TGROOT)/airports/apt.dat | awk '/^1   /{flag=1} !flag{print }' > $@
	@cat $(TGROOT)/airports/apt.dat | awk '/^1   /{flag=0} /^1[ 0-9]*$*/{flag=1}flag{print }' >> $@
	
$(TGROOT)/airports/state/%.sta: $(TGROOT)/airports/dat/%.dat
	mkdir -p $(TGROOT)/airports/state
	genapts850 $(GENAPTS_FLAGS) --min-lon=$(MINLON) --min-lat=$(MINLAT) --max-lon=$(MAXLON) --max-lat=$(MAXLAT) --input=$<
	@touch $@

mirror-srtm3:
	cd $(TGROOT)/mirrors && \
        for R in Africa Australia Eurasia Islands North_America South_America; do \
          wget --accept=hgt.zip --wait=0 --random-wait --mirror --no-parent https://dds.cr.usgs.gov/srtm/version2_1/SRTM3/$$R;\
        done
	rm -f $(TGROOT)/data/SRTM-3 && ln -s $(TGROOT)/mirrors/dds.cr.usgs.gov/srtm/version2_1/SRTM3 $(TGROOT)/data/SRTM-3

mirror-srtm1:
	cd $(TGROOT)/mirrors && \
        for R in  6 7; do \
          wget --accept=hgt.zip --wait=0 --random-wait --mirror --no-parent https://dds.cr.usgs.gov/srtm/version2_1/SRTM1/Region_0$$R; \
        done
	rm -f $(TGROOT)/data/SRTM-1 && ln -s $(TGROOT)/mirrors/dds.cr.usgs.gov/srtm/version2_1/SRTM1 $(TGROOT)/data/SRTM-1

hgtchop-srtm3:
	cd $(TGROOT) && \
	for f in data/SRTM-3/*/*.zip; do hgtchop 3 "$$f" work/SRTM-3; done

hgtchop-srtm1:
	cd $(TGROOT) && \
	for f in data/SRTM-1/*/*.zip; do hgtchop 1 "$$f" work/SRTM-1; done

terrafit-srtm3:
	terrafit -j $(THREADS) -e $(TERRAFIT_MAXERROR) -x $(TERRAFIT_MAXNODES) $(TGROOT)/work/SRTM-3

terrafit-srtm1:
	terrafit -j $(THREADS) -e $(TERRAFIT_MAXERROR) -x $(TERRAFIT_MAXNODES) $(TGROOT)/work/SRTM-1

ogr-decode:
	./decode.sh -di $(TGROOT)/config/decode.dat

init:
	echo "Initializing Workspace"
	for f in data output work mirrors; do mkdir -p ${TGROOT}/$$f; done

help:
	cat README.md
