devtools::load_all(quiet = TRUE)

contdat <- readASRcont(
  system.file('extdata/ExampleCont.xlsx', package = 'AquaSensR'),
  tz = 'Etc/GMT+5',
  runchk = FALSE
)
metadat <- readASRmeta(
  system.file('extdata/ExampleMeta.xlsx', package = 'AquaSensR'),
  runchk = FALSE
)

flagdat <- utilASRflag(contdat, metadat, param = 'Water Temp_C')

cat('flagdat columns:', paste(names(flagdat), collapse = ', '), '\n')
cat('\ngross_flag:\n')
print(table(flagdat$gross_flag))
cat('\nspike_flag:\n')
print(table(flagdat$spike_flag))
cat('\nroc_flag:\n')
print(table(flagdat$roc_flag))
cat('\nflat_flag:\n')
print(table(flagdat$flat_flag))

p <- anlzASRflag(flagdat)
cat('\nplotly object class:', paste(class(p), collapse = ', '), '\n')
