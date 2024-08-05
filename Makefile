DOCTYPE = RTN
DOCNUMBER = 085
DOCNAME = $(DOCTYPE)-$(DOCNUMBER)

tex = $(filter-out $(wildcard *acronyms.tex) , $(wildcard *.tex))

GITVERSION := $(shell git log -1 --date=short --pretty=%h)
GITDATE := $(shell git log -1 --date=short --pretty=%ad)
GITSTATUS := $(shell git status --porcelain)
ifneq "$(GITSTATUS)" ""
	GITDIRTY = -dirty
endif

export TEXMFHOME ?= lsst-texmf/texmf

# Add aglossary.tex as a dependancy here if you want a glossary (and remove acronyms.tex)
$(DOCNAME).pdf: $(tex) meta.tex local.bib acronyms.tex openMilestones.tex DP1.pdf
	latexmk -bibtex -xelatex -f $(DOCNAME)
#	makeglossaries $(DOCNAME)
#	xelatex $(DOCNAME)
# For glossary uncomment the 2 lines above


# Acronym tool allows for selection of acronyms based on tags - you may want more than DM
acronyms.tex: $(tex) myacronyms.txt
	$(TEXMFHOME)/../bin/generateAcronyms.py -t "DM" $(tex)

# If you want a glossary you must manually run generateAcronyms.py  -gu to put the \gls in your files.
aglossary.tex :$(tex) myacronyms.txt
	generateAcronyms.py  -g $(tex)


.PHONY: clean
clean:
	latexmk -c
	rm -f $(DOCNAME).{bbl,glsdefs,pdf}
	rm -f meta.tex

.FORCE:

meta.tex: Makefile .FORCE
	rm -f $@
	touch $@
	printf '%% GENERATED FILE -- edit this in the Makefile\n' >>$@
	printf '\\newcommand{\\lsstDocType}{$(DOCTYPE)}\n' >>$@
	printf '\\newcommand{\\lsstDocNum}{$(DOCNUMBER)}\n' >>$@
	printf '\\newcommand{\\vcsRevision}{$(GITVERSION)$(GITDIRTY)}\n' >>$@
	printf '\\newcommand{\\vcsDate}{$(GITDATE)}\n' >>$@


DP1.pdf: DP1.tex
	pdflatex DP1.tex

# milestones from Jira and Gantt
openMilestones.tex: 
	( \
	. operations_milestones/venv/bin/activate; \
	python operations_milestones/opsMiles.py -ls -q "and labels=DP1"  -u ${JIRA_USER} -p ${JIRA_PASSWORD}; \
	)	
	
DP1.tex: 
	( \
	. operations_milestones/venv/bin/activate; \
	python operations_milestones/opsMiles.py -g -f "DP1.tex" -q "labels=DP1 and type != story"  -u ${JIRA_USER} -p ${JIRA_PASSWORD}; \
	)

install_deps:
	python -m pip install -r operations_milestones/requirements.txt

