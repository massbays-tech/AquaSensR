# Package index

## Read, check, and format data

Functions for importing, checking, and formatting input data.

- [`readASRcont()`](https://massbays-tech.github.io/AquaSensR/reference/readASRcont.md)
  : Read continuous monitoring data from an external file
- [`readASRmeta()`](https://massbays-tech.github.io/AquaSensR/reference/readASRmeta.md)
  : Read continuous monitoring metadata from an external file
- [`checkASRcont()`](https://massbays-tech.github.io/AquaSensR/reference/checkASRcont.md)
  : Check continuous monitoring data
- [`checkASRmeta()`](https://massbays-tech.github.io/AquaSensR/reference/checkASRmeta.md)
  : Check continuous monitoring metadata
- [`formASRcont()`](https://massbays-tech.github.io/AquaSensR/reference/formASRcont.md)
  : Format continuous data
- [`formASRmeta()`](https://massbays-tech.github.io/AquaSensR/reference/formASRmeta.md)
  : Format continuous metadata

## Quality control

Functions for flagging suspect and failed data based on user-defined
metadata.

- [`anlzASRflag()`](https://massbays-tech.github.io/AquaSensR/reference/anlzASRflag.md)
  : Plot QC flag results for a continuous monitoring parameter
- [`utilASRflag()`](https://massbays-tech.github.io/AquaSensR/reference/utilASRflag.md)
  : Flag continuous monitoring data with QC criteria
- [`utilASRflagflatline()`](https://massbays-tech.github.io/AquaSensR/reference/utilASRflagflatline.md)
  : Apply flatline QC flag
- [`utilASRflaggross()`](https://massbays-tech.github.io/AquaSensR/reference/utilASRflaggross.md)
  : Apply gross range QC flag
- [`utilASRflagrleflat()`](https://massbays-tech.github.io/AquaSensR/reference/utilASRflagrleflat.md)
  : Compute consecutive run lengths for flatline detection
- [`utilASRflagroc()`](https://massbays-tech.github.io/AquaSensR/reference/utilASRflagroc.md)
  : Apply rate-of-change QC flag
- [`utilASRflagspike()`](https://massbays-tech.github.io/AquaSensR/reference/utilASRflagspike.md)
  : Apply spike QC flag
- [`utilASRflagupdate()`](https://massbays-tech.github.io/AquaSensR/reference/utilASRflagupdate.md)
  : Update QC flag severity

## Supplementary datasets

Supplementary datasets for the read, quality control, and analysis
functions.

- [`paramsASR`](https://massbays-tech.github.io/AquaSensR/reference/paramsASR.md)
  : Master list and units for acceptable parameters
